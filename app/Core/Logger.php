<?php

namespace App\Core;

/**
 * Log da aplicacao em arquivos diarios dentro de storage/logs/.
 *
 * Estrutura gerada automaticamente:
 *   storage/logs/app-AAAA-MM-DD.log     tudo (DEBUG, INFO, WARNING, ERROR)
 *   storage/logs/erros-AAAA-MM-DD.log   somente ERROR/CRITICAL, com contexto completo
 *   storage/logs/php_errors.log         erros nativos do PHP (error_log do php.ini)
 *
 * Cada linha comeca com data/hora, nivel e um codigo curto de requisicao
 * (request id) que tambem aparece na pagina de erro 500. Assim o usuario
 * informa o codigo e o suporte acha a linha exata no log.
 *
 * Se a pasta nao existir ou nao tiver permissao de escrita, o Logger
 * tenta criar (0755) e, em ultimo caso, grava no diretorio temporario do
 * sistema, sem nunca derrubar a requisicao.
 */
class Logger
{
    /** Nivel minimo gravado no arquivo geral (debug|info|warning|error). */
    private const NIVEL_MINIMO = 'debug';

    private const PESOS = [
        'DEBUG'    => 10,
        'INFO'     => 20,
        'WARNING'  => 30,
        'ERROR'    => 40,
        'CRITICAL' => 50,
    ];

    private static ?string $requestId = null;
    private static ?string $dirFallback = null;
    private static bool $jaAvisouPermissao = false;

    /* ------------------------------------------------------------------
     * Identificacao da requisicao
     * ---------------------------------------------------------------- */

    /**
     * Codigo curto (8 caracteres) que identifica esta requisicao no log.
     * O mesmo codigo aparece na tela de erro 500.
     */
    public static function requestId(): string
    {
        if (self::$requestId === null) {
            try {
                self::$requestId = strtoupper(bin2hex(random_bytes(4)));
            } catch (\Throwable $e) {
                self::$requestId = strtoupper(substr(md5((string) mt_rand()), 0, 8));
            }
        }
        return self::$requestId;
    }

    public static function definirRequestId(string $id): void
    {
        self::$requestId = $id;
    }

    /* ------------------------------------------------------------------
     * Diretorios e arquivos
     * ---------------------------------------------------------------- */

    public static function dir(): string
    {
        if (defined('STORAGE_PATH')) {
            return rtrim(STORAGE_PATH, '/\\') . '/logs';
        }
        return dirname(__DIR__, 2) . '/storage/logs';
    }

    /** Garante que a pasta existe e aceita escrita; devolve o caminho usavel. */
    public static function garantirDir(): string
    {
        $dir = self::dir();
        if (!is_dir($dir)) {
            @mkdir($dir, 0755, true);
        }
        if (is_dir($dir) && is_writable($dir)) {
            return $dir;
        }

        // Fallback: diretorio temporario (util quando storage/ veio sem permissao)
        if (self::$dirFallback === null) {
            $tmp = rtrim(sys_get_temp_dir(), '/\\') . '/somase-logs';
            if (!is_dir($tmp)) {
                @mkdir($tmp, 0755, true);
            }
            self::$dirFallback = is_dir($tmp) && is_writable($tmp) ? $tmp : '';
            if (!self::$jaAvisouPermissao) {
                self::$jaAvisouPermissao = true;
                self::escrever('WARNING', 'storage/logs sem permissao de escrita; usando diretorio alternativo', [
                    'pasta_esperada' => $dir,
                    'pasta_usada'    => self::$dirFallback,
                ], false);
            }
        }
        return self::$dirFallback !== '' ? self::$dirFallback : '';
    }

    public static function arquivoAtual(): string
    {
        return self::garantirDir() . '/app-' . date('Y-m-d') . '.log';
    }

    public static function arquivoErros(): string
    {
        return self::garantirDir() . '/erros-' . date('Y-m-d') . '.log';
    }

    /**
     * Lista os arquivos de log existentes, do mais novo para o mais antigo.
     *
     * @return array<int, array{arquivo:string, caminho:string, tamanho:int, modificado:int}>
     */
    public static function arquivos(): array
    {
        $dir = self::garantirDir();
        if ($dir === '' || !is_dir($dir)) {
            return [];
        }
        $lista = [];
        foreach (glob($dir . '/*.log') ?: [] as $caminho) {
            $lista[] = [
                'arquivo'    => basename($caminho),
                'caminho'    => $caminho,
                'tamanho'    => (int) @filesize($caminho),
                'modificado' => (int) @filemtime($caminho),
            ];
        }
        usort($lista, static fn ($a, $b) => $b['modificado'] <=> $a['modificado']);
        return $lista;
    }

    /**
     * Ultimas linhas de um arquivo de log (padrao: arquivo do dia).
     *
     * @return array<int, string>
     */
    public static function tail(?string $arquivo = null, int $linhas = 200): array
    {
        $dir = self::garantirDir();
        if ($dir === '') {
            return [];
        }
        $caminho = $arquivo !== null && $arquivo !== ''
            ? $dir . '/' . basename($arquivo)
            : self::arquivoAtual();
        if (!is_file($caminho) || !is_readable($caminho)) {
            return [];
        }
        $conteudo = @file($caminho, FILE_IGNORE_NEW_LINES);
        if ($conteudo === false) {
            return [];
        }
        return array_slice($conteudo, -max(1, $linhas));
    }

    /**
     * Junta as ultimas linhas de ERROR/CRITICAL dos arquivos recentes.
     *
     * @return array<int, string>
     */
    public static function ultimosErros(int $linhas = 25): array
    {
        $saida = [];
        foreach (array_slice(self::arquivos(), 0, 5) as $info) {
            $conteudo = @file($info['caminho'], FILE_IGNORE_NEW_LINES);
            if ($conteudo === false) {
                continue;
            }
            foreach ($conteudo as $linha) {
                if (str_contains($linha, '[ERROR]') || str_contains($linha, '[CRITICAL]')) {
                    $saida[] = $linha;
                }
            }
            if (count($saida) >= $linhas * 3) {
                break;
            }
        }
        return array_slice($saida, -max(1, $linhas));
    }

    /* ------------------------------------------------------------------
     * API de gravacao
     * ---------------------------------------------------------------- */

    public static function debug(string $mensagem, array $contexto = []): void
    {
        self::write('DEBUG', $mensagem, $contexto);
    }

    public static function info(string $mensagem, array $contexto = []): void
    {
        self::write('INFO', $mensagem, $contexto);
    }

    public static function warning(string $mensagem, array $contexto = []): void
    {
        self::write('WARNING', $mensagem, $contexto);
    }

    public static function error(string $mensagem, array $contexto = []): void
    {
        self::write('ERROR', $mensagem, $contexto);
    }

    public static function critical(string $mensagem, array $contexto = []): void
    {
        self::write('CRITICAL', $mensagem, $contexto);
    }

    /**
     * Registra uma excecao com contexto completo e devolve o request id.
     */
    public static function exception(\Throwable $e, string $mensagem = 'Excecao nao tratada', array $extra = []): string
    {
        $contexto = array_merge([
            'request_id' => self::requestId(),
            'exception'  => get_class($e),
            'message'    => $e->getMessage(),
            'code'       => $e->getCode(),
            'file'       => $e->getFile() . ':' . $e->getLine(),
            'trace'      => self::resumirTrace($e),
        ], $extra);

        $anterior = $e->getPrevious();
        for ($nivel = 1; $anterior !== null && $nivel <= 3; $nivel++) {
            $contexto['previous_' . $nivel] = [
                'exception' => get_class($anterior),
                'message'   => $anterior->getMessage(),
                'file'      => $anterior->getFile() . ':' . $anterior->getLine(),
            ];
            if ($anterior instanceof \PDOException) {
                $contexto['previous_' . $nivel]['sqlstate']     = $anterior->getCode();
                $contexto['previous_' . $nivel]['driver_error'] = $anterior->errorInfo[1] ?? null;
            }
            $anterior = $anterior->getPrevious();
        }

        if ($e instanceof \PDOException) {
            $contexto['sqlstate']        = $e->getCode();
            $contexto['driver_error']    = $e->errorInfo[1] ?? null;
            $contexto['driver_message']  = $e->errorInfo[2] ?? null;
        }

        self::write('ERROR', $mensagem, $contexto);
        return (string) $contexto['request_id'];
    }

    /* ------------------------------------------------------------------
     * Interno
     * ---------------------------------------------------------------- */

    /** Contexto automatico de toda linha: metodo, rota, ip e usuario. */
    private static function contextoBase(): array
    {
        $ctx = [
            'request_id' => self::requestId(),
            'method'     => $_SERVER['REQUEST_METHOD'] ?? 'CLI',
            'uri'        => $_SERVER['REQUEST_URI'] ?? ($_SERVER['argv'][0] ?? 'cli'),
            'ip'         => $_SERVER['REMOTE_ADDR'] ?? null,
        ];
        try {
            if (class_exists(Auth::class) && Auth::check()) {
                $ctx['user_id'] = Auth::user()?->id;
            }
        } catch (\Throwable $e) {
            // Nunca deixa o log falhar por causa da sessao/banco
        }
        if (isset($_SERVER['HTTP_USER_AGENT'])) {
            $ctx['ua'] = mb_substr((string) $_SERVER['HTTP_USER_AGENT'], 0, 160);
        }
        return array_filter($ctx, static fn ($v) => $v !== null && $v !== '');
    }

    private static function write(string $nivel, string $mensagem, array $contexto = []): void
    {
        self::escrever($nivel, $mensagem, $contexto, true);
    }

    private static function escrever(string $nivel, string $mensagem, array $contexto = [], bool $comContextoBase = true): void
    {
        $nivel = strtoupper($nivel);
        if (self::PESOS[$nivel] < self::PESOS[strtoupper(self::NIVEL_MINIMO)]) {
            return;
        }

        $dir   = self::garantirDir();
        $linha = sprintf(
            '[%s] [%s] [%s] %s%s',
            date('Y-m-d H:i:s'),
            $nivel,
            self::requestId(),
            $mensagem,
            $contexto ? ' | ' . self::json($comContextoBase ? array_merge(self::contextoBase(), $contexto) : $contexto) : ''
        ) . PHP_EOL;

        if ($dir === '') {
            @error_log(trim($linha));
            return;
        }

        $principal = $dir . '/app-' . date('Y-m-d') . '.log';
        if (@file_put_contents($principal, $linha, FILE_APPEND | LOCK_EX) === false) {
            @error_log(trim($linha));
        }

        if (self::PESOS[$nivel] >= self::PESOS['ERROR']) {
            @file_put_contents($dir . '/erros-' . date('Y-m-d') . '.log', $linha, FILE_APPEND | LOCK_EX);
        }
    }

    private static function json(array $dados): string
    {
        $json = json_encode($dados, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PARTIAL_OUTPUT_ON_ERROR);
        if ($json === false) {
            return '{"aviso":"contexto nao serializavel"}';
        }
        // Evita linhas gigantes (trace longo) mantendo o comeco util
        return mb_strlen($json) > 6000 ? mb_substr($json, 0, 6000) . '...[truncado]' : $json;
    }

    /** 12 primeiros frames da pilha, em texto curto. */
    private static function resumirTrace(\Throwable $e): array
    {
        $frames = [];
        foreach (array_slice($e->getTrace(), 0, 12) as $i => $frame) {
            $frames[] = sprintf(
                '#%d %s%s%s() em %s:%s',
                $i,
                $frame['class'] ?? '',
                $frame['type'] ?? '',
                $frame['function'] ?? '',
                $frame['file'] ?? '?',
                $frame['line'] ?? '?'
            );
        }
        return $frames;
    }
}
