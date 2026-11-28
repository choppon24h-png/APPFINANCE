<?php
namespace App\Services\Documents;

/**
 * Junta o codigo interpretado (CodeParser) com o texto do OCR
 * (TextExtractor) e monta a sugestao devolvida ao formulario.
 *
 * Nao acessa banco: recebe centros de custo e categorias do usuario em $ctx,
 * o que mantem a classe testavel e o controller no controle do isolamento.
 */
class DocumentAnalyzer
{
    private const PALAVRAS_CATEGORIA = [
        'energia' => ['energia', 'luz', 'cpfl', 'enel', 'cemig', 'copel', 'light', 'equatorial', 'neoenergia', 'eletrobras', 'eletropaulo'],
        'agua' => ['agua', 'sabesp', 'copasa', 'sanepar', 'cedae', 'saneamento', 'esgoto'],
        'telefonia' => ['telefone', 'internet', 'vivo', 'claro', 'tim ', 'oi ', 'banda larga', 'telecom'],
        'moradia' => ['aluguel', 'condominio', 'iptu', 'moradia', 'casa'],
        'alimentacao' => ['mercado', 'supermercado', 'padaria', 'restaurante', 'alimentacao', 'ifood'],
        'transporte' => ['combustivel', 'gasolina', 'etanol', 'posto', 'uber', 'transporte', 'pedagio'],
        'saude' => ['farmacia', 'drogaria', 'plano de saude', 'consulta', 'saude'],
        'educacao' => ['escola', 'faculdade', 'curso', 'educacao', 'mensalidade'],
    ];

    public static function analyze(?array $code, string $text, array $ctx = []): array
    {
        $texto = TextExtractor::extract($text);
        $norm = TextExtractor::normalize($text);
        $hoje = $ctx['today'] ?? date('Y-m-d');

        $kind = $code['kind'] ?? self::inferKind($norm, $code);
        $label = $code['label'] ?? self::labelFor($kind, $code, $norm);

        $amount = null;
        if (!empty($code['amount'])) {
            $amount = (float) $code['amount'];
        } elseif ($texto['amount'] !== null) {
            $amount = (float) $texto['amount'];
        }

        $dueDate = $code['due_date'] ?? $texto['due_date'];
        $transactionDate = $texto['transaction_date'] ?? $hoje;
        $payee = $texto['payee'];
        $cnpj = $code['cnpj'] ?? $texto['cnpj'];
        $docNumber = $texto['document_number'];

        $details = $code['details'] ?? [];
        $warnings = $code['warnings'] ?? [];
        if ($texto['text_length'] < 40) {
            $warnings[] = 'Pouco texto reconhecido: confira os campos antes de salvar.';
        }
        if ($amount === null) {
            $warnings[] = 'Valor não encontrado no documento: informe manualmente.';
        }
        if ($dueDate === null && $kind !== 'nfce') {
            $warnings[] = 'Vencimento não encontrado: informe manualmente.';
        }

        $categoria = self::guessCategory($norm, $payee, $ctx['categories'] ?? []);
        [$centro, $centroNome] = self::matchCostCenter($text, $norm, $ctx['cost_centers'] ?? []);

        $descricao = self::description($label, $payee, $docNumber, $code);
        $status = $kind === 'nfce' ? 'paid' : 'pending';
        $payment = in_array($kind, ['boleto', 'arrecadacao'], true) ? 'boleto' : ($kind === 'nfce' ? 'cash' : null);

        return [
            'ok' => true,
            'suggestion' => [
                'kind' => $kind,
                'label' => $label,
                'type' => 'expense',
                'description' => $descricao,
                'amount' => $amount,
                'due_date' => $dueDate,
                'transaction_date' => $transactionDate,
                'status' => $status,
                'payment_method' => $payment,
                'document_code' => $code['document_code'] ?? null,
                'document_code_formatted' => $code['document_code_formatted'] ?? null,
                'code_valid' => $code['code_valid'] ?? null,
                'cnpj' => $cnpj,
                'payee' => $payee,
                'category_hint' => $categoria['slug'],
                'category_id' => $categoria['id'],
                'category_name' => $categoria['name'],
                'cost_center_id' => $centro,
                'cost_center_name' => $centroNome,
                'details' => array_values(array_unique(array_filter($details))),
                'warnings' => array_values(array_unique(array_filter($warnings))),
                'duplicate' => (bool) ($ctx['duplicate'] ?? false),
            ],
            'extracted' => $texto,
        ];
    }

    private static function inferKind(string $norm, ?array $code): string
    {
        if ($code !== null) {
            return $code['kind'];
        }
        if (str_contains($norm, 'cupom fiscal') || str_contains($norm, 'nfce') || str_contains($norm, 'nfc-e')) {
            return 'nfce';
        }
        if (preg_match('/conta de (luz|agua|gas|telefone)|energia eletrica|saneamento/', $norm)) {
            return 'arrecadacao';
        }
        if (str_contains($norm, 'boleto') || str_contains($norm, 'vencimento')) {
            return 'boleto';
        }
        return 'other';
    }

    private static function labelFor(string $kind, ?array $code, string $norm): string
    {
        if ($kind === 'arrecadacao') {
            $segmento = $code['segment'] ?? null;
            $nomes = ['1' => 'Tributo municipal', '2' => 'Conta de água/esgoto', '3' => 'Conta de energia',
                '4' => 'Telefone/internet', '5' => 'Taxa pública', '6' => 'Carnê', '7' => 'Multa'];
            if ($segmento && isset($nomes[$segmento])) {
                return $nomes[$segmento];
            }
            if (preg_match('/conta de agua|sabesp|copasa|sanepar/', $norm)) return 'Conta de água/esgoto';
            if (preg_match('/energia|luz|cpfl|enel|cemig|copel/', $norm)) return 'Conta de energia';
            return 'Conta de consumo';
        }
        return match ($kind) {
            'boleto' => 'Boleto bancário',
            'nfce' => 'Cupom fiscal',
            default => 'Documento',
        };
    }

    private static function description(string $label, ?string $payee, ?string $docNumber, ?array $code): string
    {
        $partes = [$payee ?: $label];
        if ($docNumber) {
            $partes[] = 'doc. ' . $docNumber;
        } elseif (!empty($code['bank_code'])) {
            $partes[] = 'banco ' . $code['bank_code'];
        }
        $desc = trim(implode(' — ', $partes));
        if (function_exists('mb_substr')) {
            return mb_substr($desc, 0, 180, 'UTF-8');
        }
        return substr($desc, 0, 180);
    }

    /** @return array{0:?int,1:?string} */
    public static function matchCostCenter(string $text, string $norm, array $centros): array
    {
        $digitosTexto = preg_replace('/\D+/', ' ', $text) ?? '';
        $melhor = null;
        $melhorNome = null;
        $melhorPontos = 0;

        foreach ($centros as $centro) {
            $centro = (array) $centro;
            $pontos = 0;
            $ids = preg_split('/[\s,;|]+/', (string) ($centro['identifiers'] ?? ''), -1, PREG_SPLIT_NO_EMPTY) ?: [];
            foreach ($ids as $id) {
                $id = preg_replace('/\D+/', '', $id) ?? '';
                if (strlen($id) >= 4 && preg_match('/(?<!\d)' . preg_quote($id, '/') . '(?!\d)/', $digitosTexto)) {
                    $pontos += 10;
                }
            }
            $nome = trim((string) ($centro['name'] ?? ''));
            if (strlen($nome) >= 4) {
                $nomeNorm = TextExtractor::normalize($nome);
                if ($nomeNorm !== '' && str_contains($norm, $nomeNorm)) {
                    $pontos += 6;
                }
                $endereco = TextExtractor::normalize((string) ($centro['address'] ?? ''));
                if ($endereco !== '' && strlen($endereco) > 8 && str_contains($norm, $endereco)) {
                    $pontos += 4;
                }
            }
            if (($centro['kind'] ?? 'general') === 'property') {
                $pontos += 1; // leve preferencia por imovel
            }
            if ($pontos > $melhorPontos) {
                $melhorPontos = $pontos;
                $melhor = (int) $centro['id'];
                $melhorNome = $nome;
            }
        }
        if ($melhorPontos >= 5) {
            return [$melhor, $melhorNome];
        }
        // Nenhuma pista no documento: se o usuario tem um unico imovel,
        // ja deixa selecionado (evita esquecer o vinculo).
        $imoveis = array_values(array_filter($centros, static fn($c) => ((array) $c)['kind'] === 'property'));
        if (count($imoveis) === 1) {
            $unico = (array) $imoveis[0];
            return [(int) $unico['id'], (string) ($unico['name'] ?? '')];
        }
        return [null, null];
    }

    /** @return array{slug:?string,id:?int,name:?string} */
    public static function guessCategory(string $norm, ?string $payee, array $categorias): array
    {
        $slug = null;
        $alvo = $norm . ' ' . TextExtractor::normalize((string) $payee);
        foreach (self::PALAVRAS_CATEGORIA as $chave => $palavras) {
            foreach ($palavras as $palavra) {
                if (str_contains($alvo, $palavra)) {
                    $slug = $chave;
                    break 2;
                }
            }
        }
        if ($slug === null) {
            return ['slug' => null, 'id' => null, 'name' => null];
        }
        $mapa = [
            'energia' => ['energia', 'luz', 'eletricidade'],
            'agua' => ['agua', 'saneamento'],
            'telefonia' => ['telefonia', 'internet', 'telefone', 'comunicacao'],
            'moradia' => ['moradia', 'casa', 'aluguel', 'habitacao'],
            'alimentacao' => ['alimentacao', 'mercado', 'supermercado'],
            'transporte' => ['transporte', 'combustivel', 'veiculo'],
            'saude' => ['saude'],
            'educacao' => ['educacao'],
        ];
        foreach ($categorias as $cat) {
            $cat = (array) $cat;
            $nome = TextExtractor::normalize((string) ($cat['name'] ?? ''));
            foreach ($mapa[$slug] ?? [] as $termo) {
                if ($nome !== '' && str_contains($nome, $termo)) {
                    return ['slug' => $slug, 'id' => (int) $cat['id'], 'name' => (string) $cat['name']];
                }
            }
        }
        return ['slug' => $slug, 'id' => null, 'name' => null];
    }
}
