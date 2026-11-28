<?php
/**
 * Testes das novidades de 28/11/2026: CEP com fallback, projecao de
 * investimentos, slug dos catalogos e endereco montado.
 * NAO precisam de banco de dados:
 *
 *   php tests/FeaturesTest.php
 */
spl_autoload_register(static function (string $class): void {
    if (str_starts_with($class, 'App\\')) {
        $path = __DIR__ . '/../app/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        if (is_file($path)) {
            require_once $path;
        }
    }
});

use App\Models\CostCenter;
use App\Models\InvestmentType;
use App\Models\PaymentMethod;
use App\Services\CepService;
use App\Services\InvestmentProjection;
use App\Support\Slug;

$falhas = 0;
$total = 0;

function check(bool $ok, string $mensagem, $esperado = null, $obtido = null): void
{
    global $falhas, $total;
    $total++;
    if ($ok) {
        echo "  OK  {$mensagem}\n";
        return;
    }
    $falhas++;
    echo "  FALHOU  {$mensagem}";
    if ($esperado !== null || $obtido !== null) {
        echo ' (esperado: ' . var_export($esperado, true) . ' / obtido: ' . var_export($obtido, true) . ')';
    }
    echo "\n";
}

function grupo(string $titulo): void
{
    echo "\n{$titulo}\n";
}

function quase(float $a, float $b, float $tolerancia = 0.02): bool
{
    return abs($a - $b) <= $tolerancia;
}

/* ------------------------------------------------------------------
 | CEP
 | ---------------------------------------------------------------- */
grupo('CEP: normalizacao e formatacao');
check(CepService::normalize('30130-010') === '30130010', 'remove a mascara do CEP');
check(CepService::normalize(' 30.130-010 ') === '30130010', 'aceita pontos e espacos');
check(CepService::normalize('3013001') === null, 'rejeita CEP com 7 digitos');
check(CepService::normalize('301300100') === null, 'rejeita CEP com 9 digitos');
check(CepService::normalize('') === null, 'rejeita vazio');
check(CepService::format('30130010') === '30130-010', 'formata 30130010 como 30130-010');
check(CepService::format('invalido') === '', 'formatacao de invalido fica vazia');

grupo('CEP: fallback entre provedores (sem rede)');
$cepTeste = '98765432';
$cache = __DIR__ . '/../storage/cache/cep/' . $cepTeste . '.json';
if (is_file($cache)) @unlink($cache);
$json = tempnam(sys_get_temp_dir(), 'cep') . '.json';
file_put_contents($json, json_encode([
    'cep' => '98765-432', 'logradouro' => 'Rua do Fallback', 'complemento' => '',
    'bairro' => 'Centro', 'localidade' => 'Belo Horizonte', 'uf' => 'MG',
], JSON_UNESCAPED_UNICODE));
$servico = new CepService([
    ['name' => 'Quebrado', 'url' => 'file:///tmp/nao-existe-' . $cepTeste . '-%s.json'],
    ['name' => 'Local', 'url' => 'file://' . $json],
]);
$resultado = $servico->lookup($cepTeste);
check($resultado !== null, 'consulta devolve resultado quando o 1o provedor falha');
check(($resultado['source'] ?? '') === 'Local', 'usa o 2o provedor da lista', 'Local', $resultado['source'] ?? null);
check(($resultado['city'] ?? '') === 'Belo Horizonte', 'cidade preenchida pelo fallback', 'Belo Horizonte', $resultado['city'] ?? null);
check(($resultado['state'] ?? '') === 'MG', 'UF preenchida pelo fallback', 'MG', $resultado['state'] ?? null);
check(($resultado['street'] ?? '') === 'Rua do Fallback', 'rua preenchida pelo fallback', 'Rua do Fallback', $resultado['street'] ?? null);
check($servico->failures() === ['Quebrado'], 'registra o provedor que falhou', ['Quebrado'], $servico->failures());
@unlink($json);
if (is_file($cache)) @unlink($cache);

grupo('CEP: todos os provedores indisponiveis');
$cepFalha = '98765431';
$cacheFalha = __DIR__ . '/../storage/cache/cep/' . $cepFalha . '.json';
if (is_file($cacheFalha)) @unlink($cacheFalha);
$servicoFalha = new CepService([
    ['name' => 'A', 'url' => 'file:///tmp/nao-existe-a-%s.json'],
    ['name' => 'B', 'url' => 'file:///tmp/nao-existe-b-%s.json'],
]);
check($servicoFalha->lookup($cepFalha) === null, 'devolve null quando todos falham');
check($servicoFalha->failures() === ['A', 'B'], 'lista todos os provedores tentados', ['A', 'B'], $servicoFalha->failures());
if (is_file($cacheFalha)) @unlink($cacheFalha);

/* ------------------------------------------------------------------
 | Projecao de investimentos
 | ---------------------------------------------------------------- */
grupo('Investimentos: estimativa mensal');
$cdb = (object) ['amount_invested' => 10000, 'interest_rate' => 110, 'benchmark_rate' => 10.65, 'rate_period' => 'annual', 'type_benchmark' => 'cdi'];
$est = InvestmentProjection::estimate($cdb);
check(quase($est['annual_rate'], 0.11715, 0.000001), 'CDB 110% do CDI rende 11,715% a.a.', 0.11715, $est['annual_rate']);
check(quase($est['monthly_amount'], 92.74, 0.02), 'CDB 110% do CDI estima R$ 92,74/mes', 92.74, $est['monthly_amount']);
check(str_contains($est['method'], '110% do CDI'), 'descricao mostra o percentual do CDI', '110% do CDI', $est['method']);

$prefixado = (object) ['amount_invested' => 10000, 'interest_rate' => 12, 'rate_period' => 'annual', 'type_benchmark' => 'prefixado'];
$est = InvestmentProjection::estimate($prefixado);
check(quase($est['annual_rate'], 0.12, 0.000001), 'Prefixado 12% a.a. usa a taxa cheia', 0.12, $est['annual_rate']);
check(quase($est['monthly_amount'], 94.89, 0.02), 'Prefixado 12% estima R$ 94,89/mes', 94.89, $est['monthly_amount']);

$mensal = (object) ['amount_invested' => 10000, 'interest_rate' => 1, 'rate_period' => 'monthly', 'type_benchmark' => 'prefixado'];
$est = InvestmentProjection::estimate($mensal);
check(quase($est['annual_rate'], 0.126825, 0.000001), 'Taxa de 1% ao mes equivale a 12,6825% a.a.', 0.126825, $est['annual_rate']);
check(quase($est['monthly_amount'], 100.00, 0.02), '1% ao mes em 10.000 estima R$ 100,00/mes', 100.00, $est['monthly_amount']);

$ipca = (object) ['amount_invested' => 10000, 'interest_rate' => 5, 'benchmark_rate' => 4.5, 'rate_period' => 'annual', 'type_benchmark' => 'ipca'];
$est = InvestmentProjection::estimate($ipca);
check(quase($est['annual_rate'], 0.09725, 0.000001), 'IPCA+5% com IPCA de 4,5% rende 9,725% a.a.', 0.09725, $est['annual_rate']);
check(quase($est['monthly_amount'], 77.64, 0.02), 'IPCA+5% estima R$ 77,64/mes', 77.64, $est['monthly_amount']);

$comRendimento = (object) ['amount_invested' => 10000, 'accumulated_return' => 1000, 'interest_rate' => 12, 'rate_period' => 'annual', 'type_benchmark' => 'prefixado'];
$est = InvestmentProjection::estimate($comRendimento);
check(quase($est['principal'], 11000, 0.01), 'patrimonio inclui rendimentos acumulados', 11000, $est['principal']);

$semTaxa = (object) ['amount_invested' => 10000, 'interest_rate' => null, 'benchmark_rate' => null, 'rate_period' => 'annual', 'type_benchmark' => 'none'];
$est = InvestmentProjection::estimate($semTaxa);
check($est['available'] === false, 'sem taxa nao inventa estimativa');
check(quase($est['monthly_amount'], 0.0, 0.001), 'sem taxa a estimativa fica zerada', 0.0, $est['monthly_amount']);

grupo('Investimentos: deteccao do indice');
check(InvestmentProjection::benchmarkOf(null, 'CDI', null) === 'cdi', 'benchmark CDI');
check(InvestmentProjection::benchmarkOf(null, null, 'IPCA+') === 'ipca', 'rate_type IPCA+');
check(InvestmentProjection::benchmarkOf('selic', null, null) === 'selic', 'tipo Selic');
check(InvestmentProjection::benchmarkOf(null, null, 'Prefixado 12%') === 'prefixado', 'rate_type prefixado');
check(InvestmentProjection::benchmarkOf(null, null, 'CDB') === 'none', 'sem indice reconhecido');
check(InvestmentType::benchmarkLabel('cdi') === 'CDI', 'rotulo do indice CDI');
check(InvestmentType::REFERENCE_RATES['cdi'] === 10.65, 'taxa de referencia do CDI', 10.65, InvestmentType::REFERENCE_RATES['cdi']);

/* ------------------------------------------------------------------
 | Catalogos e endereco
 | ---------------------------------------------------------------- */
grupo('Catalogos: slug e rotulos');
check(Slug::make('Débito em conta') === 'debito_em_conta', 'slug sem acento', 'debito_em_conta', Slug::make('Débito em conta'));
check(Slug::make('CDB 110%') === 'cdb_110', 'slug com numero', 'cdb_110', Slug::make('CDB 110%'));
check(Slug::make('!!!') === 'item', 'slug vazio usa fallback', 'item', Slug::make('!!!'));
check(Slug::unique('cdb', ['cdb', 'cdb_2']) === 'cdb_3', 'slug unico acrescenta sufixo', 'cdb_3', Slug::unique('cdb', ['cdb', 'cdb_2']));
check(PaymentMethod::labelFor('pix') === 'PIX', 'rotulo legado do PIX', 'PIX', PaymentMethod::labelFor('pix'));
check(PaymentMethod::labelFor('debito_conta') === 'DÉBITO EM CONTA', 'rotulo de slug novo', 'DÉBITO EM CONTA', PaymentMethod::labelFor('debito_conta'));
check(isset(PaymentMethod::LEGACY['debit']), 'mantem compatibilidade com o slug antigo debit');

grupo('Endereco montado a partir do CEP');
$endereco = CostCenter::composeAddress([
    'street' => 'Praça Sete de Setembro', 'address_number' => '1000', 'complement' => 'Sala 5',
    'neighborhood' => 'Centro', 'city' => 'Belo Horizonte', 'state' => 'mg',
]);
check($endereco === 'Praça Sete de Setembro, 1000 - Sala 5 — Centro, Belo Horizonte/MG', 'monta endereco completo', 'Praça Sete de Setembro, 1000 - Sala 5 — Centro, Belo Horizonte/MG', $endereco);
check(CostCenter::composeAddress(['street' => '', 'city' => '']) === null, 'endereco vazio vira null');
check(CostCenter::composeAddress(['street' => 'Rua A', 'city' => 'Recife', 'state' => 'pe']) === 'Rua A — Recife/PE', 'monta endereco sem numero/bairro', 'Rua A — Recife/PE', CostCenter::composeAddress(['street' => 'Rua A', 'city' => 'Recife', 'state' => 'pe']));

/* ------------------------------------------------------------------
 | Resultado
 | ---------------------------------------------------------------- */
echo "\n" . str_repeat('-', 60) . "\n";
echo "{$total} verificacoes, {$falhas} falha(s)\n";
exit($falhas === 0 ? 0 : 1);
