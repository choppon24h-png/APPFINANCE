<?php
/**
 * Testes da leitura de documentos (boletos, arrecadacao, NFC-e) e dos
 * parsers de extrato (OFX/CSV). NAO precisam de banco de dados:
 *
 *   php tests/DocumentsTest.php
 */
spl_autoload_register(static function (string $class): void {
    if (str_starts_with($class, 'App\\')) {
        $path = __DIR__ . '/../app/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        if (is_file($path)) {
            require_once $path;
        }
    }
});

use App\Services\Documents\CodeParser;
use App\Services\Documents\DocumentAnalyzer;
use App\Services\Documents\StatementParser;
use App\Services\Documents\TextExtractor;

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

/* ------------------------------------------------------------------ */
grupo('1. Boleto bancario — linha digitavel de 47 digitos');

$bradesco = '23790558059000008711524005846001795860000129562';
$r = CodeParser::parse($bradesco);
check($r['kind'] === 'boleto', 'Bradesco reconhecido como boleto', 'boleto', $r['kind']);
check($r['code_valid'] === true, 'Bradesco com DV valido', true, $r['code_valid']);
check(abs($r['amount'] - 1295.62) < 0.001, 'Bradesco valor R$ 1.295,62', 1295.62, $r['amount']);
check($r['due_date'] === '2024-01-05', 'Bradesco fator 9586 -> 05/01/2024', '2024-01-05', $r['due_date']);
check($r['bank_code'] === '237', 'Bradesco banco 237', '237', $r['bank_code']);
check(str_contains($r['document_code_formatted'], '.'), 'Linha digitavel formatada para exibicao', true, $r['document_code_formatted']);

$itau = '34191090087256489872332408290008110010000082831';
$r = CodeParser::parse($itau);
check($r['code_valid'] === true, 'Itau com DV valido', true, $r['code_valid']);
check(abs($r['amount'] - 828.31) < 0.001, 'Itau valor R$ 828,31', 828.31, $r['amount']);
check($r['due_date'] === '2025-02-23', 'Itau fator 1001 -> 23/02/2025 (novo fator)', '2025-02-23', $r['due_date']);

$itau2026 = '34191090088725648987023240829004216560000045090';
$r = CodeParser::parse($itau2026);
check($r['code_valid'] === true, 'Itau 2026 com DV valido', true, $r['code_valid']);
check($r['due_date'] === '2026-12-10', 'Itau fator 1656 -> 10/12/2026', '2026-12-10', $r['due_date']);
check(abs($r['amount'] - 450.90) < 0.001, 'Itau 2026 valor R$ 450,90', 450.90, $r['amount']);

/* ------------------------------------------------------------------ */
grupo('2. Codigo de barras de 44 digitos <-> linha digitavel');

$barcode = CodeParser::parse($bradesco)['barcode'];
check(strlen($barcode) === 44, 'Codigo de barras extraido tem 44 digitos', 44, strlen($barcode));
check(CodeParser::barcodeToLinha($barcode) === $bradesco, 'Ida e volta 44 -> 47 reproduz a linha original', $bradesco, CodeParser::barcodeToLinha($barcode));
$r44 = CodeParser::parse($barcode);
check($r44['kind'] === 'boleto' && $r44['code_valid'], 'Codigo de 44 digitos reconhecido e valido', true, $r44['code_valid']);
check(abs($r44['amount'] - 1295.62) < 0.001, 'Valor lido no codigo de 44 digitos', 1295.62, $r44['amount']);

// Um digito trocado precisa ser denunciado.
$invalido = substr($bradesco, 0, 32) . (($bradesco[32] === '9') ? '8' : '9') . substr($bradesco, 33);
$ri = CodeParser::parse($invalido);
check($ri['code_valid'] === false, 'DV geral invalido e detectado', false, $ri['code_valid']);

/* ------------------------------------------------------------------ */
grupo('3. Arrecadacao / contas de consumo (48 digitos)');

$energia = '836600000019579001382020612180000004000000000000';
$r = CodeParser::parse($energia);
check($r['kind'] === 'arrecadacao', 'Conta de energia reconhecida como arrecadacao', 'arrecadacao', $r['kind']);
check($r['code_valid'] === true, 'Blocos da arrecadacao com DV valido', true, $r['code_valid']);
check($r['segment'] === '3', 'Segmento 3 (energia)', '3', $r['segment']);
check(str_contains($r['label'], 'energia'), 'Rotulo indica conta de energia', 'Conta de energia', $r['label']);
check(abs($r['amount'] - 195.79) < 0.001, 'Valor embutido nas posicoes 5-15 (R$ 195,79)', 195.79, $r['amount']);
$r44a = CodeParser::parse(substr($energia, 0, 12) . substr($energia, 12, 0)); // 12 digitos: nao e documento
check($r44a === null, 'Linha curta nao e confundida com documento', null, $r44a);

/* ------------------------------------------------------------------ */
grupo('4. Fator de vencimento (regra 22/02/2025)');

check(CodeParser::fatorParaData(2100, '2026-11-27') === '2028-02-27', 'Fator 2100 -> 27/02/2028', '2028-02-27', CodeParser::fatorParaData(2100, '2026-11-27'));
check(CodeParser::fatorParaData(1736, '2026-11-27') === '2027-02-28', 'Fator 1736 -> 28/02/2027', '2027-02-28', CodeParser::fatorParaData(1736, '2026-11-27'));
check(CodeParser::fatorParaData(1000, '2026-11-27') === '2025-02-22', 'Fator 1000 -> 22/02/2025 (reinicio)', '2025-02-22', CodeParser::fatorParaData(1000, '2026-11-27'));
check(CodeParser::fatorParaData(0) === null, 'Fator 0 sem data', null, CodeParser::fatorParaData(0));

/* ------------------------------------------------------------------ */
grupo('5. NFC-e / NF-e (chave de 44 digitos)');

$chave = '31261112345678000190650010000045211123456788';
$r = CodeParser::parse($chave);
check($r['kind'] === 'nfce', 'Chave reconhecida como NFC-e', 'nfce', $r['kind']);
check($r['code_valid'] === true, 'DV da chave confere', true, $r['code_valid']);
check($r['cnpj'] === '12345678000190', 'CNPJ extraido da chave', '12345678000190', $r['cnpj']);
check(str_contains($r['details'][1] ?? '', '12.345.678/0001-90'), 'CNPJ formatado nos detalhes', true, $r['details'][1] ?? '');

/* ------------------------------------------------------------------ */
grupo('6. Texto de boleto: valor, vencimento, beneficiario e imovel');

$textoBoleto = "CONDOMINIO RESIDENCIAL ALVORADA\n"
    . "CNPJ 12.345.678/0001-90\n"
    . "Boleto bancario - 2a via\n"
    . "Vencimento: 10/12/2026\n"
    . "Valor do documento: R$ 157,90\n"
    . "Nosso numero 12345678901\n"
    . "Referente a conta de luz - instalacao 99887766\n";

$extraido = TextExtractor::extract($textoBoleto);
check($extraido['amount'] !== null && abs($extraido['amount'] - 157.90) < 0.001, 'Valor R$ 157,90 lido do texto', 157.90, $extraido['amount']);
check($extraido['due_date'] === '2026-12-10', 'Vencimento 10/12/2026 lido do texto', '2026-12-10', $extraido['due_date']);
check($extraido['cnpj'] === '12345678000190', 'CNPJ valido reconhecido', '12345678000190', $extraido['cnpj']);
check(in_array('99887766', $extraido['identifiers'], true), 'Numero de instalacao listado como identificador', true, $extraido['identifiers']);

$analise = DocumentAnalyzer::analyze(null, $textoBoleto, [
    'today' => '2026-11-27',
    'cost_centers' => [
        ['id' => 7, 'name' => 'Apartamento Centro', 'kind' => 'property', 'identifiers' => '99887766, 11223344', 'address' => 'Rua das Flores 100'],
        ['id' => 9, 'name' => 'Casa da praia', 'kind' => 'property', 'identifiers' => '55667788', 'address' => ''],
    ],
    'categories' => [
        ['id' => 3, 'name' => 'Energia elétrica'],
        ['id' => 4, 'name' => 'Moradia'],
    ],
]);
$s = $analise['suggestion'];
check($s['cost_center_id'] === 7, 'Imovel reconhecido pelo numero de instalacao', 7, $s['cost_center_id']);
check($s['category_id'] === 3, 'Categoria "Energia elétrica" sugerida', 3, $s['category_id']);
check(abs($s['amount'] - 157.90) < 0.001, 'Sugestao usa o valor do texto quando nao ha codigo', 157.90, $s['amount']);
check($s['status'] === 'pending', 'Boleto entra como pendente', 'pending', $s['status']);

/* ------------------------------------------------------------------ */
grupo('7. Cupom fiscal (NFC-e) e duplicidade');

$textoCupom = "CUPOM FISCAL ELETRONICO\nSUPERMERCADO BOM PRECO LTDA\n"
    . "CNPJ: 12.345.678/0001-90\nITEM 1  ARROZ 5KG   32,90\nITEM 2  FEIJAO      12,50\n"
    . "VALOR TOTAL R$ 89,90\n"
    . "Chave de acesso: 3126 1112 3456 7800 0190 6500 1000 0045 2111 2345 6788\n";
$r = CodeParser::detect([], $textoCupom);
check($r !== null && $r['kind'] === 'nfce', 'Chave da NFC-e encontrada no meio do texto', 'nfce', $r['kind'] ?? null);
$analise = DocumentAnalyzer::analyze($r, $textoCupom, [
    'today' => '2026-11-27', 'duplicate' => true,
    'cost_centers' => [['id' => 2, 'name' => 'Casa', 'kind' => 'property', 'identifiers' => '', 'address' => '']],
    'categories' => [['id' => 5, 'name' => 'Alimentação']],
]);
$s = $analise['suggestion'];
check($s['kind'] === 'nfce', 'Sugestao marcada como NFC-e', 'nfce', $s['kind']);
check(abs($s['amount'] - 89.90) < 0.001, 'Total do cupom R$ 89,90', 89.90, $s['amount']);
check($s['status'] === 'paid', 'Cupom ja pago entra como pago', 'paid', $s['status']);
check($s['duplicate'] === true, 'Duplicidade sinalizada quando o codigo ja existe', true, $s['duplicate']);
check($s['category_id'] === 5, 'Categoria de alimentacao sugerida', 5, $s['category_id']);
check($s['cost_center_id'] === 2, 'Centro de custo padrao quando so ha um imovel', 2, $s['cost_center_id']);

/* ------------------------------------------------------------------ */
grupo('8. Digitos verificadores (mod 10 e mod 11)');

check(CodeParser::mod10('237905580') === 5, 'Modulo 10 do campo 1 do Bradesco', 5, CodeParser::mod10('237905580'));
check(CodeParser::mod11Boleto(substr($barcode, 0, 4) . substr($barcode, 5)) === 7, 'Modulo 11 do DV geral do Bradesco', 7, CodeParser::mod11Boleto(substr($bradesco, 0, 32) . substr($bradesco, 33)));
check(TextExtractor::parseMoney('R$ 1.295,62') === 1295.62, 'Conversao de moeda brasileira', 1295.62, TextExtractor::parseMoney('R$ 1.295,62'));
check(TextExtractor::parseMoney('828.31') === 828.31, 'Conversao de moeda com ponto decimal', 828.31, TextExtractor::parseMoney('828.31'));

/* ------------------------------------------------------------------ */
grupo('9. Extrato OFX (SGML) e CSV');

$ofx = <<<OFX
OFXHEADER:100
DATA:OFXSGML
VERSION:102
SECURITY:NONE
ENCODING:USASCII
CHARSET:1252
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE

<OFX>
<SIGNONMSGSRSV1><SONRS><STATUS><CODE>0<SEVERITY>INFO</STATUS><DTSERVER>20261127120000<LANGUAGE>POR</SONRS></SIGNONMSGSRSV1>
<BANKMSGSRSV1><STMTTRNRS><TRNUID>1<STATUS><CODE>0<SEVERITY>INFO</STATUS>
<STMTRS><CURDEF>BRL<BANKACCTFROM><BANKID>237<ACCTID>12345-6<ACCTTYPE>CHECKING</BANKACCTFROM>
<BANKTRANLIST><DTSTART>20261101<DTEND>20261130
<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20261105120000<TRNAMT>-157.90<FITID>202611050001<NAME>ENEL DISTRIBUICAO<MEMO>CONTA DE LUZ</STMTTRN>
<STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20261110120000<TRNAMT>2500.00<FITID>202611100002<NAME>CLIENTE ABC<MEMO>PIX RECEBIDO</STMTTRN>
</BANKTRANLIST><LEDGERBAL><BALAMT>5000.00<DTASOF>20261130</LEDGERBAL></STMTRS></STMTTRNRS></BANKMSGSRSV1></OFX>
OFX;
$linhas = StatementParser::parse($ofx, 'extrato.ofx');
check(count($linhas) === 2, 'OFX gera 2 lancamentos (saldo ignorado)', 2, count($linhas));
check($linhas[0]['type'] === 'expense' && abs($linhas[0]['amount'] - 157.90) < 0.001, 'Debito do OFX vira despesa de R$ 157,90', 'expense/157.90', $linhas[0]['type'] . '/' . $linhas[0]['amount']);
check($linhas[1]['type'] === 'income' && abs($linhas[1]['amount'] - 2500.00) < 0.001, 'Credito do OFX vira receita', 'income/2500', $linhas[1]['type'] . '/' . $linhas[1]['amount']);
check($linhas[0]['import_ref'] === 'ofx:202611050001', 'FITID usado como referencia unica', 'ofx:202611050001', $linhas[0]['import_ref']);
check(str_contains($linhas[0]['description'], 'ENEL'), 'Descricao traz o favorecido do OFX', true, $linhas[0]['description']);

$csv = "Data;Descrição;Valor;Saldo\n05/11/2026;Conta de luz;-157,90;4.842,10\n10/11/2026;PIX recebido;2.500,00;7.342,10\n";
$linhas = StatementParser::parse($csv, 'extrato.csv');
check(count($linhas) === 2, 'CSV com ; gera 2 lancamentos', 2, count($linhas));
check($linhas[0]['date'] === '2026-11-05' && $linhas[0]['type'] === 'expense', 'Data e tipo do CSV (debito)', '2026-11-05/expense', $linhas[0]['date'] . '/' . $linhas[0]['type']);
check(abs($linhas[1]['amount'] - 2500.00) < 0.001, 'Valor do CSV com separador brasileiro', 2500.00, $linhas[1]['amount']);
check(str_starts_with($linhas[0]['import_ref'], 'csv:'), 'Referencia do CSV e um hash', 'csv:', substr($linhas[0]['import_ref'], 0, 4));

$csvDebitoCredito = "Data,Histórico,Débito,Crédito\n05/11/2026,Conta de luz,\"157,90\",\n10/11/2026,PIX recebido,,\"2500,00\"\n";
$linhas = StatementParser::parse($csvDebitoCredito, 'extrato2.csv');
check(count($linhas) === 2, 'CSV com colunas Debito/Credito', 2, count($linhas));
check($linhas[0]['type'] === 'expense' && abs($linhas[0]['amount'] - 157.90) < 0.001, 'Debito na coluna propria', 'expense/157.9', $linhas[0]['type'] . '/' . $linhas[0]['amount']);
check($linhas[1]['type'] === 'income' && abs($linhas[1]['amount'] - 2500.00) < 0.001, 'Credito na coluna propria', 'income/2500', $linhas[1]['type'] . '/' . $linhas[1]['amount']);

/* ------------------------------------------------------------------ */
echo "\n" . str_repeat('-', 60) . "\n";
echo "{$total} verificacoes, {$falhas} falha(s)\n";
exit($falhas === 0 ? 0 : 1);
