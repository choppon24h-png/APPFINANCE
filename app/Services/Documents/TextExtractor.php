<?php
namespace App\Services\Documents;

/**
 * Extrai informacoes uteis do texto obtido por OCR (ou digitado) de um
 * boleto, conta de consumo, cupom fiscal ou comprovante.
 *
 * Tudo aqui e deterministico e sem banco de dados, para poder ser testado
 * por tests/DocumentsTest.php.
 */
class TextExtractor
{
    /** Rotulos que indicam o valor a pagar (em ordem de prioridade). */
    private const ROTULOS_VALOR = [
        'valor a pagar', 'valor total a pagar', 'total a pagar', 'valor do documento',
        'valor cobrado', 'valor da conta', 'valor total', 'total da nota', 'total r$',
        'valor liquido', 'valor', 'total',
    ];

    private const ROTULOS_VENCIMENTO = [
        'vencimento', 'data de vencimento', 'venc', 'pague ate', 'pagar ate', 'vence em',
    ];

    public static function normalize(string $text): string
    {
        $text = str_replace(["\r\n", "\r"], "\n", $text);
        $lower = function_exists('mb_strtolower') ? mb_strtolower($text, 'UTF-8') : strtolower($text);
        $semAcento = @iconv('UTF-8', 'ASCII//TRANSLIT', $lower);
        return $semAcento !== false ? $semAcento : $lower;
    }

    public static function extract(string $text): array
    {
        $norm = self::normalize($text);
        $linhas = array_values(array_filter(array_map('trim', explode("\n", $text)), static fn($l) => $l !== ''));

        return [
            'cnpj' => self::cnpj($text),
            'amount' => self::amount($text, $norm),
            'due_date' => self::dueDate($text, $norm),
            'transaction_date' => self::issueDate($text, $norm),
            'payee' => self::payee($linhas),
            'document_number' => self::documentNumber($norm),
            'identifiers' => self::identifiers($text),
            'text_length' => strlen(trim($text)),
        ];
    }

    public static function cnpj(string $text): ?string
    {
        if (preg_match('/(\d{2})[.\s]?(\d{3})[.\s]?(\d{3})[\/\s]?(\d{4})[-\s]?(\d{2})/', $text, $m)) {
            $cnpj = $m[1] . $m[2] . $m[3] . $m[4] . $m[5];
            // Aceita o numero formatado mesmo quando o DV nao fecha (documentos
            // antigos e digitalizacoes); o DV so e exigido para 14 digitos soltos.
            $formatado = (bool) preg_match('/\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}/', $m[0]);
            if ($formatado || self::cnpjValido($cnpj)) {
                return $cnpj;
            }
        }
        return null;
    }

    public static function cnpjValido(string $cnpj): bool
    {
        $cnpj = preg_replace('/\D+/', '', $cnpj) ?? '';
        if (strlen($cnpj) !== 14 || preg_match('/^(\d)\1{13}$/', $cnpj)) {
            return false;
        }
        $calc = static function (string $base): int {
            $pesos = strlen($base) === 12 ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2] : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
            $soma = 0;
            for ($i = 0; $i < strlen($base); $i++) {
                $soma += (int) $base[$i] * $pesos[$i];
            }
            $resto = $soma % 11;
            return $resto < 2 ? 0 : 11 - $resto;
        };
        return $calc(substr($cnpj, 0, 12)) === (int) $cnpj[12]
            && $calc(substr($cnpj, 0, 13)) === (int) $cnpj[13];
    }

    /** Converte "1.234,56", "1234.56" e "R$ 157,90" em float. */
    public static function parseMoney(string $valor): ?float
    {
        $valor = trim($valor);
        $valor = preg_replace('/[^\d.,-]/', '', $valor) ?? '';
        if ($valor === '') {
            return null;
        }
        $temVirgula = str_contains($valor, ',');
        $temPonto = str_contains($valor, '.');
        if ($temVirgula && $temPonto) {
            // Formato BR: ponto e separador de milhar.
            $valor = str_replace('.', '', $valor);
            $valor = str_replace(',', '.', $valor);
        } elseif ($temVirgula) {
            $valor = str_replace(',', '.', $valor);
        }
        return is_numeric($valor) ? round((float) $valor, 2) : null;
    }

    public static function amount(string $text, ?string $norm = null): ?float
    {
        $norm = $norm ?? self::normalize($text);
        $valores = [];

        // 1) Valor imediatamente depois de um rotulo conhecido.
        foreach (self::ROTULOS_VALOR as $rotulo) {
            $pos = strpos($norm, $rotulo);
            if ($pos === false) {
                continue;
            }
            $trecho = substr($text, $pos, 90);
            if (preg_match('/R\$\s*([\d.]*\d,\d{2}|\d+\.\d{2}|\d+,\d{2})/i', $trecho, $m)) {
                $v = self::parseMoney($m[1]);
                if ($v !== null && $v > 0) {
                    $valores[] = $v;
                }
            }
        }
        if ($valores) {
            return max($valores);
        }

        // 2) Qualquer valor em reais no documento (o total costuma ser o maior).
        if (preg_match_all('/R\$\s*([\d.]*\d,\d{2}|\d+\.\d{2})/i', $text, $m)) {
            $todos = array_filter(array_map([self::class, 'parseMoney'], $m[1]), static fn($v) => $v !== null && $v > 0);
            if ($todos) {
                return max($todos);
            }
        }
        // 3) Numero solto com centavos perto de "valor".
        if (preg_match('/(?:valor|total)[^\d]{0,20}(\d{1,3}(?:\.\d{3})*,\d{2})/i', $text, $m)) {
            return self::parseMoney($m[1]);
        }
        return null;
    }

    public static function dueDate(string $text, ?string $norm = null): ?string
    {
        $norm = $norm ?? self::normalize($text);
        foreach (self::ROTULOS_VENCIMENTO as $rotulo) {
            $pos = strpos($norm, $rotulo);
            if ($pos === false) {
                continue;
            }
            $trecho = substr($text, $pos, 70);
            $data = self::firstDate($trecho);
            if ($data) {
                return $data;
            }
        }
        return null;
    }

    public static function issueDate(string $text, ?string $norm = null): ?string
    {
        $norm = $norm ?? self::normalize($text);
        foreach (['data de emissao', 'emissao', 'emitido em', 'data'] as $rotulo) {
            $pos = strpos($norm, $rotulo);
            if ($pos === false) {
                continue;
            }
            $data = self::firstDate(substr($text, $pos, 70));
            if ($data) {
                return $data;
            }
        }
        return null;
    }

    public static function firstDate(string $trecho): ?string
    {
        if (preg_match('/\b(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{2,4})\b/', $trecho, $m)) {
            $dia = (int) $m[1];
            $mes = (int) $m[2];
            $ano = (int) $m[3];
            if ($ano < 100) {
                $ano += 2000;
            }
            if (checkdate($mes, $dia, $ano)) {
                return sprintf('%04d-%02d-%02d', $ano, $mes, $dia);
            }
        }
        return null;
    }

    /** Nome do beneficiario/emitente: primeiras linhas com texto "de verdade". */
    public static function payee(array $linhas): ?string
    {
        $ignorar = ['boleto', 'banco', 'pagador', 'beneficiario', 'cedente', 'sacado', 'cnpj', 'cpf',
            'valor', 'vencimento', 'documento', 'nosso numero', 'agencia', 'conta', 'carteira',
            'recibo', 'fatura', 'conta de', 'comprovante', 'via', 'segunda via', 'total'];
        foreach ($linhas as $linha) {
            $limpa = trim(preg_replace('/\s+/', ' ', $linha) ?? '');
            $norm = self::normalize($limpa);
            if (strlen($limpa) < 4 || strlen($limpa) > 70) {
                continue;
            }
            if (preg_match('/^[\d\W]+$/', $limpa)) {
                continue;
            }
            foreach ($ignorar as $palavra) {
                if (str_starts_with($norm, $palavra)) {
                    continue 2;
                }
            }
            // Linha com CNPJ junto costuma ser o cabecalho do emitente.
            return $limpa;
        }
        return null;
    }

    public static function documentNumber(string $norm): ?string
    {
        foreach (['nosso numero', 'numero do documento', 'n do documento', 'numero da conta', 'conta contrato'] as $rotulo) {
            $pos = strpos($norm, $rotulo);
            if ($pos !== false && preg_match('/([0-9][0-9.\/-]{3,})/', substr($norm, $pos + strlen($rotulo), 40), $m)) {
                return trim($m[1], " .-/");
            }
        }
        return null;
    }

    /**
     * Numeros que podem identificar um imovel (instalacao, medidor, conta):
     * grupos de 6 a 12 digitos, ignorando CNPJ/CPF e o proprio codigo de barras.
     */
    public static function identifiers(string $text): array
    {
        $semCodigo = preg_replace('/\d{44,48}/', ' ', $text) ?? $text;
        if (!preg_match_all('/(?<!\d)(\d{6,12})(?!\d)/', $semCodigo, $m)) {
            return [];
        }
        $out = [];
        foreach ($m[1] as $n) {
            if (strlen($n) === 11 && self::cpfValido($n)) {
                continue; // CPF nao identifica imovel
            }
            $out[(string) $n] = true;
        }
        return array_map('strval', array_keys($out));
    }

    private static function cpfValido(string $cpf): bool
    {
        if (preg_match('/^(\d)\1{10}$/', $cpf)) {
            return false;
        }
        for ($t = 9; $t < 11; $t++) {
            $soma = 0;
            for ($i = 0; $i < $t; $i++) {
                $soma += (int) $cpf[$i] * (($t + 1) - $i);
            }
            $digito = ((10 * $soma) % 11) % 10;
            if ((int) $cpf[$t] !== $digito) {
                return false;
            }
        }
        return true;
    }
}
