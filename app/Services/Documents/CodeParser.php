<?php
namespace App\Services\Documents;

/**
 * Interpreta codigos numericos de documentos de cobranca brasileiros.
 *
 *  - Boleto bancario: linha digitavel de 47 digitos ou codigo de barras de 44
 *  - Arrecadacao/convênio (agua, luz, telefone, tributos): 48 ou 44 digitos
 *    comecando por 8
 *  - NFC-e / NF-e: chave de acesso de 44 digitos (modelo 65 ou 55)
 *
 * Nenhuma dependencia externa: serve para o endpoint PHP e para os testes.
 */
class CodeParser
{
    public const SEGMENTOS = [
        '1' => 'Prefeituras',
        '2' => 'Saneamento',
        '3' => 'Energia elétrica e gás',
        '4' => 'Telecomunicações',
        '5' => 'Órgãos governamentais',
        '6' => 'Carnês e assemelhados',
        '7' => 'Multas de trânsito',
        '9' => 'Uso exclusivo do banco',
    ];

    /**
     * @param string[] $codes codigos encontrados no documento (QR, ITF, digitados)
     * @param string   $text  texto do OCR (opcional, usado para desempate)
     * @return array|null
     */
    public static function detect(array $codes, string $text = ''): ?array
    {
        $candidatos = [];
        foreach ($codes as $code) {
            $digits = self::digits($code);
            if (strlen($digits) >= 44) {
                $candidatos[] = $digits;
            }
        }
        // Codigos no meio do texto, inclusive com espacos/pontos entre grupos
        // (ex.: "836600000019 579001382020 ..." ou chave da NFC-e em blocos de 4).
        if ($text !== '' && preg_match_all('/\d(?:[\d.\-\s]{42,70})\d/', $text, $m)) {
            foreach ($m[0] as $sequencia) {
                $digits = self::digits($sequencia);
                if (strlen($digits) >= 44 && strlen($digits) <= 48) {
                    $candidatos[] = $digits;
                }
            }
        }
        // Ultimo recurso: sequencia continua de 44 a 48 digitos.
        if (preg_match_all('/\d{44,48}/', self::digits($text), $m)) {
            foreach ($m[0] as $digits) {
                $candidatos[] = $digits;
            }
        }
        $candidatos = array_values(array_unique($candidatos));

        // Prioriza arrecadacao (48/44 comecando por 8) e boleto de 47.
        foreach ([48, 47, 44] as $len) {
            foreach ($candidatos as $digits) {
                if (strlen($digits) !== $len) {
                    continue;
                }
                $parsed = self::parse($digits, $text);
                if ($parsed !== null) {
                    return $parsed;
                }
            }
        }
        return null;
    }

    public static function parse(string $digits, string $text = ''): ?array
    {
        $digits = self::digits($digits);
        $len = strlen($digits);
        if ($len === 47) {
            return self::boleto47($digits);
        }
        if ($len === 48 && $digits[0] === '8') {
            return self::arrecadacao48($digits);
        }
        if ($len === 44 && $digits[0] === '8') {
            return self::arrecadacao44($digits);
        }
        if ($len === 44) {
            return self::keyOrBarcode44($digits);
        }
        return null;
    }

    /* ------------------------------------------------------------------ */
    /* Boleto bancario                                                     */
    /* ------------------------------------------------------------------ */

    private static function boleto47(string $d): array
    {
        $campo1 = substr($d, 0, 10);   // 9 dados + DV
        $campo2 = substr($d, 10, 11);  // 10 dados + DV
        $campo3 = substr($d, 21, 11);  // 10 dados + DV
        $dvGeral = substr($d, 32, 1);
        $campo5 = substr($d, 33, 14);  // fator (4) + valor (10)

        $erros = [];
        if (self::mod10(substr($campo1, 0, 9)) !== (int) $campo1[9]) {
            $erros[] = 'Dígito verificador do campo 1 não confere.';
        }
        if (self::mod10(substr($campo2, 0, 10)) !== (int) $campo2[10]) {
            $erros[] = 'Dígito verificador do campo 2 não confere.';
        }
        if (self::mod10(substr($campo3, 0, 10)) !== (int) $campo3[10]) {
            $erros[] = 'Dígito verificador do campo 3 não confere.';
        }

        // Codigo de barras (44): banco+moeda + DV + fator+valor + campo livre
        $livre = substr($campo1, 4, 5) . substr($campo2, 0, 10) . substr($campo3, 0, 10);
        $barcode = substr($campo1, 0, 4) . $dvGeral . $campo5 . $livre;
        $dvCalculado = self::mod11Boleto(substr($barcode, 0, 4) . substr($barcode, 5));
        if ($dvCalculado !== (int) $dvGeral) {
            $erros[] = 'Dígito verificador geral não confere.';
        }

        $fator = (int) substr($campo5, 0, 4);
        $valor = ((int) substr($campo5, 4, 10)) / 100;
        $vencimento = self::fatorParaData($fator);

        return [
            'kind' => 'boleto',
            'label' => 'Boleto bancário',
            'bank_code' => substr($d, 0, 3),
            'document_code' => $d,
            'document_code_formatted' => self::formatBoleto($d),
            'barcode' => $barcode,
            'amount' => $valor > 0 ? round($valor, 2) : null,
            'due_date' => $vencimento,
            'code_valid' => $erros === [],
            'details' => array_values(array_filter([
                'Banco ' . substr($d, 0, 3),
                'Fator de vencimento ' . $fator,
                $valor > 0 ? 'Valor embutido R$ ' . number_format($valor, 2, ',', '.') : 'Sem valor embutido (informe no formulário)',
            ])),
            'warnings' => $erros,
        ];
    }

    private static function keyOrBarcode44(string $d): ?array
    {
        // Chave de NF-e/NFC-e: posicoes 21-22 (indice 20) = modelo (55/65).
        // Exige DV da chave valido e codigo de UF plausivel para nao confundir
        // com um codigo de barras de boleto que tenha "55"/"65" no campo livre.
        $modelo = substr($d, 20, 2);
        $uf = (int) substr($d, 0, 2);
        $valida = self::mod11Chave($d) === (int) $d[43];
        if (in_array($modelo, ['55', '65'], true) && $valida && $uf >= 11 && $uf <= 53) {
            return [
                'kind' => 'nfce',
                'label' => $modelo === '65' ? 'Cupom fiscal (NFC-e)' : 'Nota fiscal (NF-e)',
                'document_code' => $d,
                'document_code_formatted' => self::formatKey($d),
                'barcode' => $d,
                'amount' => null,
                'due_date' => null,
                'code_valid' => $valida,
                'details' => array_values(array_filter([
                    'Chave de acesso com 44 dígitos',
                    'CNPJ do emitente: ' . self::formatCnpj(substr($d, 6, 14)),
                    'Emissão: ' . self::dateFromAamm(substr($d, 2, 4)),
                    $valida ? 'Dígito verificador confere' : 'Dígito verificador não confere',
                ])),
                'warnings' => $valida ? [] : ['Dígito verificador da chave não confere.'],
                'cnpj' => substr($d, 6, 14),
            ];
        }
        // Codigo de barras de boleto (44): banco + moeda + DV + fator + valor
        $banco = substr($d, 0, 3);
        if (!ctype_digit($banco) || (int) $banco === 0) {
            return null;
        }
        $dv = (int) $d[4];
        $valido = self::mod11Boleto(substr($d, 0, 4) . substr($d, 5)) === $dv;
        $fator = (int) substr($d, 5, 4);
        $valor = ((int) substr($d, 9, 10)) / 100;
        $linha = self::barcodeToLinha($d);
        return [
            'kind' => 'boleto',
            'label' => 'Boleto bancário',
            'bank_code' => $banco,
            'document_code' => $d,
            'document_code_formatted' => $linha ? self::formatBoleto($linha) : $d,
            'barcode' => $d,
            'amount' => $valor > 0 ? round($valor, 2) : null,
            'due_date' => self::fatorParaData($fator),
            'code_valid' => $valido,
            'details' => array_values(array_filter([
                'Banco ' . $banco,
                'Código de barras de 44 dígitos',
                $valor > 0 ? 'Valor embutido R$ ' . number_format($valor, 2, ',', '.') : null,
            ])),
            'warnings' => $valido ? [] : ['Dígito verificador geral não confere.'],
        ];
    }

    /** Converte o codigo de barras (44) na linha digitavel (47). */
    public static function barcodeToLinha(string $barcode): ?string
    {
        $barcode = self::digits($barcode);
        if (strlen($barcode) !== 44) {
            return null;
        }
        $campo1 = substr($barcode, 0, 4) . substr($barcode, 19, 5);
        $campo2 = substr($barcode, 24, 10);
        $campo3 = substr($barcode, 34, 10);
        $campo5 = substr($barcode, 5, 14);
        return $campo1 . self::mod10($campo1)
            . $campo2 . self::mod10($campo2)
            . $campo3 . self::mod10($campo3)
            . $barcode[4]
            . $campo5;
    }

    /* ------------------------------------------------------------------ */
    /* Arrecadacao / convenio                                              */
    /* ------------------------------------------------------------------ */

    private static function arrecadacao48(string $d): array
    {
        $erros = [];
        for ($i = 0; $i < 4; $i++) {
            $bloco = substr($d, $i * 12, 12);
            $dados = substr($bloco, 0, 11);
            $dv = (int) $bloco[11];
            // Bloco 1 sempre modulo 10 (o 3o digito e o indicador de valor).
            // Blocos 2 a 4: modulo 11 quando o 3o digito for 6 ou 7.
            $mod = ($i > 0 && in_array($bloco[2], ['6', '7'], true)) ? 11 : 10;
            $calc = $mod === 11 ? self::mod11Arrecadacao($dados) : self::mod10($dados);
            if ($calc !== $dv) {
                $erros[] = 'Dígito verificador do bloco ' . ($i + 1) . ' não confere.';
            }
        }
        return self::arrecadacaoBase($d, $erros, substr($d, 4, 11), true);
    }

    private static function arrecadacao44(string $d): array
    {
        return self::arrecadacaoBase($d, [], substr($d, 4, 11), false);
    }

    private static function arrecadacaoBase(string $d, array $erros, string $valorDigits, bool $comDv): array
    {
        $segmento = $d[1] ?? '';
        $valor = ((int) $valorDigits) / 100;
        $tipoValor = $d[2] ?? '';
        $rotulos = ['1' => 'Tributo municipal', '2' => 'Conta de água/esgoto', '3' => 'Conta de energia',
            '4' => 'Telefone/internet', '5' => 'Taxa pública', '6' => 'Carnê', '7' => 'Multa'];
        return [
            'kind' => 'arrecadacao',
            'label' => $rotulos[$segmento] ?? 'Conta de consumo',
            'bank_code' => null,
            'segment' => $segmento,
            'segment_name' => self::SEGMENTOS[$segmento] ?? 'Segmento ' . $segmento,
            'document_code' => $d,
            'document_code_formatted' => self::formatArrecadacao($d),
            'barcode' => $comDv ? self::arrecadacaoSemDv($d) : $d,
            'amount' => $valor > 0 ? round($valor, 2) : null,
            'due_date' => null,
            'code_valid' => $erros === [],
            'details' => array_values(array_filter([
                'Segmento ' . $segmento . ' — ' . (self::SEGMENTOS[$segmento] ?? 'não identificado'),
                $valor > 0 ? 'Valor embutido R$ ' . number_format($valor, 2, ',', '.') : 'Sem valor embutido',
                $comDv ? 'Linha de 48 dígitos (com DVs)' : 'Código de 44 dígitos (sem DVs)',
                $tipoValor !== '' ? 'Indicador de valor: ' . $tipoValor : null,
            ])),
            'warnings' => $erros,
        ];
    }

    private static function arrecadacaoSemDv(string $d): string
    {
        $out = '';
        for ($i = 0; $i < 4; $i++) {
            $out .= substr($d, $i * 12, 11);
        }
        return $out;
    }

    /* ------------------------------------------------------------------ */
    /* Formatacao e utilitarios                                            */
    /* ------------------------------------------------------------------ */

    public static function digits(string $value): string
    {
        return preg_replace('/\D+/', '', $value) ?? '';
    }

    public static function formatBoleto(string $d): string
    {
        $d = self::digits($d);
        if (strlen($d) !== 47) {
            return $d;
        }
        return substr($d, 0, 5) . '.' . substr($d, 5, 5) . ' '
            . substr($d, 10, 5) . '.' . substr($d, 15, 6) . ' '
            . substr($d, 21, 5) . '.' . substr($d, 26, 6) . ' '
            . substr($d, 32, 1) . ' '
            . substr($d, 33);
    }

    public static function formatArrecadacao(string $d): string
    {
        $d = self::digits($d);
        return trim(chunk_split($d, 12, ' '));
    }

    public static function formatKey(string $d): string
    {
        return trim(chunk_split(self::digits($d), 4, ' '));
    }

    public static function formatCnpj(string $cnpj): string
    {
        $cnpj = self::digits($cnpj);
        if (strlen($cnpj) !== 14) {
            return $cnpj;
        }
        return substr($cnpj, 0, 2) . '.' . substr($cnpj, 2, 3) . '.' . substr($cnpj, 5, 3)
            . '/' . substr($cnpj, 8, 4) . '-' . substr($cnpj, 12, 2);
    }

    /**
     * Fator de vencimento -> data (Y-m-d).
     *
     * O fator reiniciou em 1000 no dia 22/02/2025 (FEBRABAN), portanto um
     * mesmo fator tem duas datas possiveis. Escolhemos a mais proxima da
     * data de referencia (hoje, por padrao): boletos antigos continuam
     * corretos e boletos novos tambem.
     */
    public static function fatorParaData(int $fator, ?string $referencia = null): ?string
    {
        if ($fator <= 0) {
            return null;
        }
        $ref = new \DateTimeImmutable($referencia ?: date('Y-m-d'));
        $antiga = (new \DateTimeImmutable('1997-10-07'))->modify('+' . $fator . ' days');
        if ($fator < 1000) {
            return $antiga->format('Y-m-d');
        }
        $nova = (new \DateTimeImmutable('2025-02-22'))->modify('+' . ($fator - 1000) . ' days');
        $distAntiga = abs((int) $ref->diff($antiga)->format('%r%a'));
        $distNova = abs((int) $ref->diff($nova)->format('%r%a'));
        return ($distNova <= $distAntiga ? $nova : $antiga)->format('Y-m-d');
    }

    private static function dateFromAamm(string $aamm): string
    {
        if (strlen($aamm) !== 4) {
            return '';
        }
        $ano = 2000 + (int) substr($aamm, 0, 2);
        $mes = (int) substr($aamm, 2, 2);
        if ($mes < 1 || $mes > 12) {
            return '';
        }
        return sprintf('%02d/%04d', $mes, $ano);
    }

    /* ------------------------------------------------------------------ */
    /* Digitos verificadores                                               */
    /* ------------------------------------------------------------------ */

    public static function mod10(string $numero): int
    {
        $soma = 0;
        $peso = 2;
        for ($i = strlen($numero) - 1; $i >= 0; $i--) {
            $produto = ((int) $numero[$i]) * $peso;
            $soma += $produto > 9 ? $produto - 9 : $produto;
            $peso = $peso === 2 ? 1 : 2;
        }
        return (10 - ($soma % 10)) % 10;
    }

    /** Modulo 11 do boleto bancario (DV geral). */
    public static function mod11Boleto(string $numero): int
    {
        $soma = 0;
        $peso = 2;
        for ($i = strlen($numero) - 1; $i >= 0; $i--) {
            $soma += ((int) $numero[$i]) * $peso;
            $peso = $peso === 9 ? 2 : $peso + 1;
        }
        $resto = $soma % 11;
        $dv = 11 - $resto;
        return ($dv === 0 || $dv === 10 || $dv === 11) ? 1 : $dv;
    }

    /** Modulo 11 dos blocos de arrecadacao. */
    public static function mod11Arrecadacao(string $numero): int
    {
        $soma = 0;
        $peso = 2;
        for ($i = strlen($numero) - 1; $i >= 0; $i--) {
            $soma += ((int) $numero[$i]) * $peso;
            $peso = $peso === 9 ? 2 : $peso + 1;
        }
        $dv = 11 - ($soma % 11);
        return ($dv === 10 || $dv === 11) ? 0 : $dv;
    }

    /** DV da chave de acesso NF-e/NFC-e (modulo 11, pesos 2..9 da direita). */
    public static function mod11Chave(string $chave): int
    {
        $soma = 0;
        $peso = 2;
        for ($i = 42; $i >= 0; $i--) {
            $soma += ((int) $chave[$i]) * $peso;
            $peso = $peso === 9 ? 2 : $peso + 1;
        }
        $resto = $soma % 11;
        $dv = 11 - $resto;
        return ($dv >= 10) ? 0 : $dv;
    }
}
