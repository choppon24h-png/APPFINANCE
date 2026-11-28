<?php
namespace App\Services;

use App\Core\Logger;

/**
 * Consulta de CEP com fallback entre provedores gratuitos.
 *
 * Ordem: ViaCEP -> BrasilAPI -> OpenCEP. Se um provedor falhar (timeout,
 * bloqueio, CEP inexistente), o próximo é tentado automaticamente. O
 * resultado fica em cache de arquivo por 7 dias para não repetir consultas.
 *
 * Nenhuma chave de API é necessária e nada depende de extensão além de curl
 * (com fallback para file_get_contents quando curl não estiver disponível).
 */
final class CepService
{
    private const TIMEOUT = 4;

    /** @var array<int,array{name:string,url:string}> */
    private array $providers = [
        ['name' => 'ViaCEP', 'url' => 'https://viacep.com.br/ws/%s/json/'],
        ['name' => 'BrasilAPI', 'url' => 'https://brasilapi.com.br/api/cep/v2/%s'],
        ['name' => 'OpenCEP', 'url' => 'https://opencep.com/v1/%s'],
    ];

    /** @var array<int,string> Provedores que falharam nesta requisição (para o painel). */
    private array $falhas = [];

    private int $cacheTtl;
    private int $timeout;

    /**
     * @param array<int,array{name:string,url:string}>|null $providers
     *        Permite trocar a ordem dos provedores (usado nos testes de fallback).
     */
    public function __construct(?array $providers = null)
    {
        if ($providers !== null && $providers !== []) {
            $this->providers = $providers;
        } else {
            $this->applyProviderOrder((string) ($_ENV['CEP_PROVIDERS'] ?? ''));
        }

        $dias = (int) ($_ENV['CEP_CACHE_TTL_DAYS'] ?? 7);
        $this->cacheTtl = max(0, $dias) * 86400;
        $this->timeout = max(1, (int) ($_ENV['CEP_TIMEOUT_SECONDS'] ?? self::TIMEOUT));
    }

    /**
     * Reordena os provedores conforme CEP_PROVIDERS (ex.: "brasilapi,viacep").
     * Nomes desconhecidos sao ignorados e os ausentes continuam no fim,
     * entao uma configuracao errada nunca deixa a busca sem provedor.
     */
    private function applyProviderOrder(string $ordem): void
    {
        $ordem = trim($ordem);
        if ($ordem === '') {
            return;
        }

        $mapa = [];
        foreach ($this->providers as $provider) {
            $mapa[strtolower($provider['name'])] = $provider;
        }

        $novos = [];
        foreach (explode(',', $ordem) as $nome) {
            $chave = strtolower(trim($nome));
            if ($chave !== '' && isset($mapa[$chave])) {
                $novos[] = $mapa[$chave];
                unset($mapa[$chave]);
            }
        }

        foreach ($this->providers as $provider) {
            if (isset($mapa[strtolower($provider['name'])])) {
                $novos[] = $provider;
            }
        }

        if ($novos !== []) {
            $this->providers = $novos;
        }
    }

    public static function normalize(?string $cep): ?string
    {
        $digitos = preg_replace('/\D/', '', (string) $cep) ?? '';
        return strlen($digitos) === 8 ? $digitos : null;
    }

    public static function format(?string $cep): string
    {
        $digitos = self::normalize($cep);
        return $digitos ? substr($digitos, 0, 5) . '-' . substr($digitos, 5) : '';
    }

    /**
     * @return array{cep:string,street:?string,complement:?string,neighborhood:?string,city:?string,state:?string,source:string}|null
     */
    public function lookup(?string $cep): ?array
    {
        $digitos = self::normalize($cep);
        if ($digitos === null) {
            return null;
        }

        $cache = $this->readCache($digitos);
        if ($cache !== null) {
            $cache['cached'] = true;
            return $cache;
        }

        $this->falhas = [];
        foreach ($this->providers as $provider) {
            $inicio = microtime(true);
            $payload = $this->request(sprintf($provider['url'], $digitos));
            if ($payload === null) {
                $this->falhas[] = $provider['name'];
                Logger::debug('cep.provedor_falhou', ['cep' => $digitos, 'provedor' => $provider['name']]);
                continue;
            }
            $normalizado = $this->normalizePayload($payload, $provider['name'], $digitos);
            if ($normalizado === null) {
                $this->falhas[] = $provider['name'];
                Logger::debug('cep.sem_resultado', ['cep' => $digitos, 'provedor' => $provider['name']]);
                continue;
            }
            $normalizado['cached'] = false;
            $this->writeCache($digitos, $normalizado);
            Logger::debug('cep.encontrado', [
                'cep' => $digitos, 'provedor' => $provider['name'],
                'ms' => (int) round((microtime(true) - $inicio) * 1000),
            ]);
            return $normalizado;
        }

        Logger::warning('cep.nao_encontrado', ['cep' => $digitos, 'falhas' => $this->falhas]);
        return null;
    }

    /** @return array<int,string> */
    public function failures(): array
    {
        return $this->falhas;
    }

    /** @return array<string,mixed>|null */
    private function request(string $url): ?array
    {
        $headers = ['Accept: application/json', 'User-Agent: SOMASE/1.0 (+https://finance.minasbyte.com)'];
        if (function_exists('curl_init')) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CONNECTTIMEOUT => 3,
                CURLOPT_TIMEOUT => $this->timeout,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_MAXREDIRS => 2,
                CURLOPT_HTTPHEADER => $headers,
                CURLOPT_SSL_VERIFYPEER => true,
                CURLOPT_SSL_VERIFYHOST => 2,
            ]);
            $body = curl_exec($ch);
            $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($body === false || $status >= 400) {
                return null;
            }
        } else {
            $contexto = stream_context_create(['http' => [
                'method' => 'GET', 'timeout' => $this->timeout, 'header' => implode("\r\n", $headers), 'ignore_errors' => true,
            ]]);
            $body = @file_get_contents($url, false, $contexto);
            if ($body === false) {
                return null;
            }
        }

        $data = json_decode((string) $body, true);
        return is_array($data) ? $data : null;
    }

    /** @return array<string,mixed>|null */
    private function normalizePayload(array $data, string $source, string $cep): ?array
    {
        // ViaCEP sinaliza CEP inexistente com {"erro": true}
        if (!empty($data['erro'])) {
            return null;
        }
        $street = $data['logradouro'] ?? $data['street'] ?? null;
        $city = $data['localidade'] ?? $data['city'] ?? null;
        $state = $data['uf'] ?? $data['state'] ?? null;
        $neighborhood = $data['bairro'] ?? $data['neighborhood'] ?? null;
        $complement = $data['complemento'] ?? $data['complement'] ?? null;

        if (($city === null || $city === '') && ($street === null || $street === '')) {
            return null;
        }

        $limpar = static function ($valor): ?string {
            $texto = trim((string) ($valor ?? ''));
            return $texto !== '' ? $texto : null;
        };

        return [
            'cep' => self::format($data['cep'] ?? $cep),
            'street' => $limpar($street),
            'complement' => $limpar($complement),
            'neighborhood' => $limpar($neighborhood),
            'city' => $limpar($city),
            'state' => strtoupper((string) ($limpar($state) ?? '')),
            'source' => $source,
        ];
    }

    private function cacheDir(): string
    {
        $configurado = trim((string) ($_ENV['CEP_CACHE_DIR'] ?? ''));
        $dir = $configurado !== ''
            ? (str_starts_with($configurado, '/') ? $configurado : dirname(__DIR__, 2) . '/' . ltrim($configurado, '/'))
            : dirname(__DIR__, 2) . '/storage/cache/cep';
        if (!is_dir($dir)) {
            @mkdir($dir, 0775, true);
        }
        return $dir;
    }

    /** @return array<string,mixed>|null */
    private function readCache(string $cep): ?array
    {
        if ($this->cacheTtl <= 0) {
            return null; // CEP_CACHE_TTL_DAYS=0 desliga o cache
        }
        $arquivo = $this->cacheDir() . '/' . $cep . '.json';
        if (!is_file($arquivo) || (time() - (int) filemtime($arquivo)) > $this->cacheTtl) {
            return null;
        }
        $data = json_decode((string) @file_get_contents($arquivo), true);
        return is_array($data) ? $data : null;
    }

    private function writeCache(string $cep, array $data): void
    {
        $arquivo = $this->cacheDir() . '/' . $cep . '.json';
        @file_put_contents($arquivo, json_encode($data, JSON_UNESCAPED_UNICODE), LOCK_EX);
    }
}
