<?php
namespace App\Services;

use App\Models\InvestmentType;

/**
 * Estima a receita mensal de um investimento a partir da taxa contratada.
 *
 * Regras (todas em % ao ano, salvo quando rate_period = monthly):
 *  - CDI/Selic: taxa contratada é o percentual do índice (ex.: 110% do CDI);
 *  - IPCA+: taxa contratada é o juro real somado à inflação de referência;
 *  - Prefixado: a própria taxa contratada é a rentabilidade anual;
 *  - Sem índice: usa a taxa contratada como rentabilidade anual.
 *
 * O valor de referência (CDI/Selic/IPCA) fica em benchmark_rate e pode ser
 * ajustado pelo usuário no formulário — nenhuma API externa é necessária.
 */
final class InvestmentProjection
{
    /** Taxas anuais de referência usadas como sugestão no formulário. */
    public const REFERENCE_RATES = InvestmentType::REFERENCE_RATES;

    /**
     * @param object|array $investment Linha de investments (com accumulated_return/movement_result quando houver)
     * @return array{available:bool,principal:float,annual_rate:float,annual_amount:float,monthly_amount:float,benchmark:string,benchmark_rate:float,contract_rate:float,rate_period:string,method:string}
     */
    public static function estimate(object|array $investment, ?float $principalOverride = null): array
    {
        $get = static function (string $key, mixed $default = null) use ($investment): mixed {
            if (is_array($investment)) return $investment[$key] ?? $default;
            return $investment->$key ?? $default;
        };

        $principal = $principalOverride ?? (
            (float) $get('amount_invested', 0)
            + (float) $get('accumulated_return', 0)
            + (float) $get('movement_result', 0)
        );
        if ($principal <= 0) $principal = (float) $get('amount_invested', 0);

        $benchmark = self::benchmarkOf($get('type_benchmark'), $get('benchmark'), $get('rate_type'));
        $contractRate = (float) ($get('interest_rate') ?? 0);
        $reference = (float) ($get('benchmark_rate') ?? 0);
        if ($reference <= 0) $reference = self::REFERENCE_RATES[$benchmark] ?? 0.0;
        $period = (string) ($get('rate_period') ?? 'annual') === 'monthly' ? 'monthly' : 'annual';

        // Taxa contratada convertida para anual.
        $contractAnnual = $period === 'monthly'
            ? (pow(1 + ($contractRate / 100), 12) - 1)
            : ($contractRate / 100);
        $referenceAnnual = $reference / 100;

        $available = true;
        switch ($benchmark) {
            case 'cdi':
            case 'selic':
                $percent = $contractRate > 0 ? ($contractRate / 100) : 1.0;
                $annual = $percent * $referenceAnnual;
                break;
            case 'ipca':
                if ($reference <= 0) {
                    $annual = $contractAnnual;
                } else {
                    $annual = ((1 + $referenceAnnual) * (1 + $contractAnnual)) - 1;
                }
                break;
            case 'prefixado':
            case 'none':
            default:
                $annual = $contractAnnual;
                if ($annual <= 0 && $referenceAnnual > 0) {
                    $annual = $referenceAnnual;
                }
                if ($annual <= 0) $available = false;
                break;
        }
        if ($annual <= -0.99) {
            $annual = 0.0;
            $available = false;
        }

        $monthly = $principal * (pow(1 + $annual, 1 / 12) - 1);
        if (!$available) $monthly = 0.0;

        return [
            'available' => $available,
            'principal' => round($principal, 2),
            'annual_rate' => round($annual, 6),
            'annual_amount' => round($principal * $annual, 2),
            'monthly_amount' => round($monthly, 2),
            'benchmark' => $benchmark,
            'benchmark_rate' => $reference,
            'contract_rate' => $contractRate,
            'rate_period' => $period,
            'method' => self::describe($benchmark, $contractRate, $reference, $period),
        ];
    }

    /** Estimativa mensal arredondada (atalho para listagens). */
    public static function monthly(object|array $investment): float
    {
        return (float) self::estimate($investment)['monthly_amount'];
    }

    public static function benchmarkOf(?string $typeBenchmark, ?string $benchmark, ?string $rateType): string
    {
        $candidatos = array_filter([$typeBenchmark, $benchmark, $rateType]);
        foreach ($candidatos as $valor) {
            $valor = strtolower(trim((string) $valor));
            if ($valor === '') continue;
            if (str_contains($valor, 'cdi')) return 'cdi';
            if (str_contains($valor, 'selic')) return 'selic';
            if (str_contains($valor, 'ipca')) return 'ipca';
            if (str_contains($valor, 'pre') || str_contains($valor, 'fixad')) return 'prefixado';
            if (in_array($valor, ['none', 'sem indice', 'sem índice'], true)) return 'none';
        }
        return 'none';
    }

    public static function describe(string $benchmark, float $contractRate, float $reference, string $period): string
    {
        $taxa = rtrim(rtrim(number_format($contractRate, 4, ',', '.'), '0'), ',');
        $ref = rtrim(rtrim(number_format($reference, 2, ',', '.'), '0'), ',');
        $sufixo = $period === 'monthly' ? '% ao mês' : '% ao ano';
        return match ($benchmark) {
            'cdi' => ($contractRate > 0 ? $taxa . '% do CDI' : '100% do CDI') . ' (CDI ' . $ref . '% a.a.)',
            'selic' => ($contractRate > 0 ? $taxa . '% da Selic' : '100% da Selic') . ' (Selic ' . $ref . '% a.a.)',
            'ipca' => 'IPCA + ' . $taxa . '%' . ($reference > 0 ? ' (IPCA ' . $ref . '% a.a.)' : ''),
            'prefixado' => $taxa . $sufixo . ' prefixado',
            default => $contractRate > 0 ? $taxa . $sufixo : 'Sem taxa contratada',
        };
    }
}
