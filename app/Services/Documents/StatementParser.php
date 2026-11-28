<?php
namespace App\Services\Documents;

/**
 * Le extratos bancarios em OFX (SGML/XML) e CSV, devolvendo linhas
 * normalizadas para a tela de importacao em lote.
 *
 * Cada linha: date, description, amount, type, import_ref, memo, external_id.
 * Nada aqui grava no banco: o controller decide o que e duplicado.
 */
class StatementParser
{
    /** @return array<int,array<string,mixed>> */
    public static function parse(string $conteudo, string $nomeArquivo = ''): array
    {
        $conteudo = self::toUtf8($conteudo);
        $ext = strtolower(pathinfo($nomeArquivo, PATHINFO_EXTENSION));
        if ($ext === 'ofx' || str_contains(substr($conteudo, 0, 400), '<OFX>')) {
            return self::parseOfx($conteudo);
        }
        if ($ext === 'csv' || $ext === 'txt' || str_contains($conteudo, ';') || str_contains($conteudo, ',')) {
            return self::parseCsv($conteudo);
        }
        return [];
    }

    public static function toUtf8(string $conteudo): string
    {
        // Remove BOM UTF-8.
        $conteudo = preg_replace('/^\xEF\xBB\xBF/', '', $conteudo) ?? $conteudo;
        if (mb_check_encoding($conteudo, 'UTF-8')) {
            return $conteudo;
        }
        $convertido = @iconv('Windows-1252', 'UTF-8//IGNORE', $conteudo);
        return $convertido !== false ? $convertido : $conteudo;
    }

    /* ------------------------------------------------------------------ */
    /* OFX                                                                 */
    /* ------------------------------------------------------------------ */

    public static function parseOfx(string $conteudo): array
    {
        $linhas = [];
        if (!preg_match_all('/<STMTTRN>(.*?)(?:<\/STMTTRN>|(?=<STMTTRN>)|(?=<\/BANKTRANLIST>))/is', $conteudo, $blocos)) {
            return [];
        }
        foreach ($blocos[1] as $bloco) {
            $tipo = strtoupper(self::tag($bloco, 'TRNTYPE'));
            $data = self::ofxDate(self::tag($bloco, 'DTPOSTED'));
            $valor = TextExtractor::parseMoney(str_replace(',', '.', self::tag($bloco, 'TRNAMT')));
            if ($data === null || $valor === null || abs($valor) < 0.001) {
                continue;
            }
            $fitid = self::tag($bloco, 'FITID');
            $nome = self::tag($bloco, 'NAME');
            $memo = self::tag($bloco, 'MEMO');
            $descricao = trim($nome !== '' ? $nome : $memo);
            if ($nome !== '' && $memo !== '' && TextExtractor::normalize($memo) !== TextExtractor::normalize($nome)) {
                $descricao .= ' — ' . $memo;
            }
            $ehCredito = $valor > 0 || in_array($tipo, ['CREDIT', 'DEP', 'DIRECTDEP', 'INT', 'DIV'], true);
            $linhas[] = [
                'date' => $data,
                'description' => self::limit($descricao !== '' ? $descricao : 'Lançamento importado', 180),
                'amount' => round(abs($valor), 2),
                'type' => $ehCredito ? 'income' : 'expense',
                'import_ref' => $fitid !== '' ? 'ofx:' . substr($fitid, 0, 60) : 'ofx:' . sha1($data . '|' . $valor . '|' . $descricao),
                'memo' => $memo,
                'external_id' => $fitid,
            ];
        }
        return $linhas;
    }

    private static function tag(string $bloco, string $tag): string
    {
        if (preg_match('/<' . $tag . '>([^<\r\n]*)/i', $bloco, $m)) {
            return trim(html_entity_decode($m[1], ENT_QUOTES | ENT_XML1, 'UTF-8'));
        }
        return '';
    }

    private static function ofxDate(string $valor): ?string
    {
        $valor = preg_replace('/\D+/', '', $valor) ?? '';
        if (strlen($valor) < 8) {
            return null;
        }
        $ano = (int) substr($valor, 0, 4);
        $mes = (int) substr($valor, 4, 2);
        $dia = (int) substr($valor, 6, 2);
        return checkdate($mes, $dia, $ano) ? sprintf('%04d-%02d-%02d', $ano, $mes, $dia) : null;
    }

    /* ------------------------------------------------------------------ */
    /* CSV                                                                 */
    /* ------------------------------------------------------------------ */

    public static function parseCsv(string $conteudo): array
    {
        $linhasBrutas = preg_split('/\r\n|\n|\r/', trim($conteudo)) ?: [];
        $linhasBrutas = array_values(array_filter($linhasBrutas, static fn($l) => trim($l) !== ''));
        if (count($linhasBrutas) < 2) {
            return [];
        }
        $separador = self::detectSeparator($linhasBrutas[0]);
        $cabecalho = str_getcsv($linhasBrutas[0], $separador);
        $mapa = self::mapHeader($cabecalho);

        // Sem cabecalho reconhecivel: assume data;descricao;valor.
        $inicio = $mapa['date'] !== null ? 1 : 0;
        if ($mapa['date'] === null) {
            $mapa = ['date' => 0, 'description' => 1, 'amount' => 2, 'debit' => null, 'credit' => null];
        }

        $saida = [];
        $vistos = [];
        for ($i = $inicio; $i < count($linhasBrutas); $i++) {
            $cols = str_getcsv($linhasBrutas[$i], $separador);
            if (count($cols) < 2) {
                continue;
            }
            $data = self::parseDate($cols[$mapa['date']] ?? '');
            if ($data === null) {
                continue;
            }
            $descricao = trim((string) ($cols[$mapa['description']] ?? ''));
            if ($descricao === '') {
                $descricao = 'Lançamento importado';
            }
            $norm = TextExtractor::normalize($descricao);
            if (preg_match('/^saldo( anterior| do dia| final| disponivel)?$/', $norm)) {
                continue; // linhas de saldo nao sao lancamentos
            }
            $valor = null;
            $tipo = null;
            if ($mapa['debit'] !== null || $mapa['credit'] !== null) {
                $debito = $mapa['debit'] !== null ? TextExtractor::parseMoney((string) ($cols[$mapa['debit']] ?? '')) : null;
                $credito = $mapa['credit'] !== null ? TextExtractor::parseMoney((string) ($cols[$mapa['credit']] ?? '')) : null;
                if ($debito !== null && abs($debito) > 0.001) {
                    $valor = abs($debito);
                    $tipo = 'expense';
                } elseif ($credito !== null && abs($credito) > 0.001) {
                    $valor = abs($credito);
                    $tipo = 'income';
                }
            } else {
                $valor = TextExtractor::parseMoney((string) ($cols[$mapa['amount']] ?? ''));
            }
            if ($valor === null || abs($valor) < 0.001) {
                continue;
            }
            $tipo = $tipo ?? ($valor < 0 ? 'expense' : 'income');
            $hash = sha1($data . '|' . number_format(abs($valor), 2, '.', '') . '|' . TextExtractor::normalize($descricao));
            $vistos[$hash] = ($vistos[$hash] ?? 0) + 1;
            $saida[] = [
                'date' => $data,
                'description' => self::limit($descricao, 180),
                'amount' => round(abs($valor), 2),
                'type' => $tipo,
                'import_ref' => 'csv:' . $hash . ($vistos[$hash] > 1 ? '-' . $vistos[$hash] : ''),
                'memo' => '',
                'external_id' => null,
            ];
        }
        return $saida;
    }

    private static function detectSeparator(string $linha): string
    {
        $candidatos = [';' => substr_count($linha, ';'), "\t" => substr_count($linha, "\t"), ',' => substr_count($linha, ',')];
        arsort($candidatos);
        return (string) array_key_first($candidatos);
    }

    /** @return array{date:?int,description:?int,amount:?int,debit:?int,credit:?int} */
    private static function mapHeader(array $cabecalho): array
    {
        $mapa = ['date' => null, 'description' => null, 'amount' => null, 'debit' => null, 'credit' => null];
        foreach ($cabecalho as $i => $titulo) {
            $n = TextExtractor::normalize(trim((string) $titulo));
            if ($n === '') {
                continue;
            }
            if ($mapa['date'] === null && preg_match('/^(data|date|dt)\b/', $n)) {
                $mapa['date'] = $i;
            } elseif ($mapa['debit'] === null && preg_match('/debito|saida/', $n)) {
                $mapa['debit'] = $i;
            } elseif ($mapa['credit'] === null && preg_match('/credito|entrada/', $n)) {
                $mapa['credit'] = $i;
            } elseif ($mapa['amount'] === null && preg_match('/valor|amount|montante/', $n)) {
                $mapa['amount'] = $i;
            } elseif ($mapa['description'] === null && preg_match('/descri|histor|memo|lancamento|detalhe/', $n)) {
                $mapa['description'] = $i;
            }
        }
        if ($mapa['description'] === null) {
            foreach ($cabecalho as $i => $titulo) {
                if ($i !== $mapa['date'] && $i !== $mapa['amount'] && $i !== $mapa['debit'] && $i !== $mapa['credit']) {
                    $mapa['description'] = $i;
                    break;
                }
            }
        }
        return $mapa;
    }

    public static function parseDate(string $valor): ?string
    {
        $valor = trim($valor);
        if ($valor === '') {
            return null;
        }
        if (preg_match('/^(\d{4})-(\d{2})-(\d{2})/', $valor, $m)) {
            return checkdate((int) $m[2], (int) $m[3], (int) $m[1]) ? "{$m[1]}-{$m[2]}-{$m[3]}" : null;
        }
        if (preg_match('/^(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{2,4})$/', $valor, $m)) {
            $dia = (int) $m[1];
            $mes = (int) $m[2];
            $ano = (int) $m[3];
            if ($ano < 100) {
                $ano += 2000;
            }
            return checkdate($mes, $dia, $ano) ? sprintf('%04d-%02d-%02d', $ano, $mes, $dia) : null;
        }
        return null;
    }

    private static function limit(string $texto, int $max): string
    {
        return function_exists('mb_substr') ? mb_substr($texto, 0, $max, 'UTF-8') : substr($texto, 0, $max);
    }
}
