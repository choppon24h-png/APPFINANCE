<?php
namespace App\Controllers;

use App\Core\Audit\AuditLogger;
use App\Core\Auth;
use App\Core\Controller;
use App\Core\Logger;
use App\Models\Account;
use App\Models\Category;
use App\Models\CostCenter;
use App\Models\Transaction;
use App\Services\Documents\DocumentAnalyzer;
use App\Services\Documents\StatementParser;
use App\Services\Documents\TextExtractor;
use App\Services\FinanceService;
use App\Support\FinanceInput;
use Throwable;

/**
 * Lancamento em lote a partir de extrato OFX/CSV.
 *
 * Fluxo: /lancamentos/importar (tela) -> POST .../extrato (previa JSON)
 *        -> revisao na grade -> POST .../confirmar (grava ate 300 linhas).
 */
class ImportController extends Controller
{
    private const MAX_PREVIA = 500;
    private const MAX_CONFIRMAR = 300;

    private function userId(): int
    {
        return (int) Auth::user()->id;
    }

    public function form(): void
    {
        $userId = $this->userId();
        $this->view('transactions/import', [
            'title' => 'Lançar em lote',
            'accounts' => (new Account())->forUser($userId, true),
            'costCenters' => (new CostCenter())->forUser($userId, true),
            'categories' => (new Category())->forUser($userId, null, true),
        ]);
    }

    /** POST /lancamentos/importar/extrato */
    public function preview(): void
    {
        $payload = $this->payload();
        $userId = $this->userId();
        try {
            $accountId = FinanceInput::intId($payload['account_id'] ?? null, 'Conta', true);
            $conta = (new Account())->findForUser($accountId, $userId);
            if (!$conta) {
                $this->json(['ok' => false, 'error' => 'Conta não encontrada.'], 422);
                return;
            }
            $conteudo = '';
            $nome = (string) ($payload['filename'] ?? 'extrato');
            if (!empty($_FILES['file']['tmp_name']) && is_uploaded_file($_FILES['file']['tmp_name'])) {
                if ((int) $_FILES['file']['size'] > 8 * 1024 * 1024) {
                    $this->json(['ok' => false, 'error' => 'O extrato deve ter no máximo 8 MB.'], 422);
                    return;
                }
                $conteudo = (string) file_get_contents($_FILES['file']['tmp_name']);
                $nome = (string) ($_FILES['file']['name'] ?? $nome);
            } elseif (!empty($payload['content'])) {
                $conteudo = (string) $payload['content'];
            }
            if (trim($conteudo) === '') {
                $this->json(['ok' => false, 'error' => 'Envie o arquivo OFX/CSV ou cole o conteúdo.'], 422);
                return;
            }
            $linhas = StatementParser::parse($conteudo, $nome);
            if (!$linhas) {
                $this->json(['ok' => false, 'error' => 'Não encontrei lançamentos no arquivo. Verifique se é OFX ou CSV com data, descrição e valor.'], 422);
                return;
            }
            $total = count($linhas);
            $linhas = array_slice($linhas, 0, self::MAX_PREVIA);
            $rows = $this->enrich($userId, $accountId, $linhas);

            AuditLogger::log('import_preview', 'transaction', null, [
                'account_id' => $accountId, 'arquivo' => $nome, 'linhas' => $total,
            ]);
            $this->json([
                'ok' => true,
                'filename' => $nome,
                'total' => $total,
                'truncated' => $total > count($linhas),
                'rows' => $rows,
            ]);
        } catch (Throwable $e) {
            Logger::error('import.previa', ['erro' => $e->getMessage()]);
            $this->json(['ok' => false, 'error' => $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível ler o extrato.'], 422);
        }
    }

    /** POST /lancamentos/importar/confirmar */
    public function confirm(): void
    {
        $payload = $this->payload();
        $userId = $this->userId();
        $rows = $payload['rows'] ?? [];
        if (!is_array($rows) || !$rows) {
            $this->json(['ok' => false, 'error' => 'Nenhuma linha para importar.'], 422);
            return;
        }
        if (count($rows) > self::MAX_CONFIRMAR) {
            $this->json(['ok' => false, 'error' => 'Importe no máximo ' . self::MAX_CONFIRMAR . ' linhas por vez.'], 422);
            return;
        }
        try {
            $accountId = FinanceInput::intId($payload['account_id'] ?? null, 'Conta', true);
            if (!(new Account())->findForUser($accountId, $userId)) {
                $this->json(['ok' => false, 'error' => 'Conta não encontrada.'], 422);
                return;
            }
        } catch (Throwable $e) {
            $this->json(['ok' => false, 'error' => $e->getMessage()], 422);
            return;
        }

        $servico = new FinanceService();
        $modelo = new Transaction();
        $importados = 0;
        $ignorados = 0;
        $erros = [];

        foreach ($rows as $i => $row) {
            $row = (array) $row;
            if (!empty($row['skip'])) {
                $ignorados++;
                continue;
            }
            try {
                $data = StatementParser::parseDate((string) ($row['date'] ?? ''));
                if ($data === null) {
                    throw new \InvalidArgumentException('Data inválida.');
                }
                $valor = TextExtractor::parseMoney((string) ($row['amount'] ?? ''));
                if ($valor === null || $valor <= 0) {
                    throw new \InvalidArgumentException('Valor inválido.');
                }
                $tipo = ($row['type'] ?? 'expense') === 'income' ? 'income' : 'expense';
                $ref = substr(trim((string) ($row['import_ref'] ?? '')), 0, 100);
                if ($ref !== '' && $modelo->existingImportRefs($userId, $accountId, [$ref])) {
                    $ignorados++;
                    continue;
                }
                $status = $tipo === 'income' ? 'received' : 'paid';
                $id = $servico->createTransaction($userId, [
                    'type' => $tipo,
                    'description' => (string) ($row['description'] ?? 'Lançamento importado'),
                    'amount' => number_format($valor, 2, '.', ''),
                    'account_id' => $accountId,
                    'category_id' => $row['category_id'] ?? null,
                    'cost_center_id' => $row['cost_center_id'] ?? null,
                    'transaction_date' => $data,
                    'due_date' => $data,
                    'payment_date' => $data,
                    'status' => $status,
                    'payment_method' => 'transfer',
                    'notes' => 'Importado de extrato em ' . date('d/m/Y H:i'),
                    'frequency' => 'none',
                ]);
                if ($ref !== '') {
                    $modelo->setImportRef($id, $userId, $ref);
                }
                $importados++;
            } catch (Throwable $e) {
                $erros[] = 'Linha ' . ($i + 1) . ': ' . ($e instanceof \InvalidArgumentException ? $e->getMessage() : 'não foi possível salvar.');
            }
        }

        AuditLogger::log('import', 'transaction', null, [
            'account_id' => $accountId, 'importados' => $importados, 'ignorados' => $ignorados, 'erros' => count($erros),
        ]);
        $this->json([
            'ok' => true,
            'imported' => $importados,
            'skipped' => $ignorados,
            'errors' => $erros,
            'message' => $importados . ' lançamento(s) importado(s)'
                . ($ignorados ? ', ' . $ignorados . ' ignorado(s)' : '')
                . ($erros ? ', ' . count($erros) . ' com erro' : '') . '.',
        ]);
    }

    /**
     * Marca duplicados e sugere categoria/centro de custo para cada linha.
     */
    private function enrich(int $userId, int $accountId, array $linhas): array
    {
        $modelo = new Transaction();
        $refs = array_map(static fn($l) => (string) $l['import_ref'], $linhas);
        $existentes = array_flip($modelo->existingImportRefs($userId, $accountId, $refs));

        // Categorias aprendidas: descricao -> categoria/centro mais usados.
        $historico = [];
        $stmt = \App\Core\Database::getInstance()->prepare(
            "SELECT description, category_id, cost_center_id, COUNT(*) AS total
             FROM transactions
             WHERE user_id = :u AND type = 'expense' AND category_id IS NOT NULL
             GROUP BY description, category_id, cost_center_id
             ORDER BY total DESC LIMIT 400"
        );
        $stmt->execute(['u' => $userId]);
        foreach ($stmt->fetchAll() as $h) {
            $chave = TextExtractor::normalize((string) $h->description);
            if (!isset($historico[$chave])) {
                $historico[$chave] = $h;
            }
        }

        $categorias = (new Category())->forUser($userId);
        $centros = (new CostCenter())->forUser($userId);
        $saida = [];
        foreach ($linhas as $linha) {
            $descNorm = TextExtractor::normalize((string) $linha['description']);
            $categoriaId = null;
            $centroId = null;
            foreach ($historico as $chave => $h) {
                if ($chave !== '' && ($chave === $descNorm || str_contains($descNorm, $chave) || str_contains($chave, $descNorm))) {
                    $categoriaId = (int) $h->category_id;
                    $centroId = $h->cost_center_id ? (int) $h->cost_center_id : null;
                    break;
                }
            }
            if ($categoriaId === null) {
                $sug = DocumentAnalyzer::guessCategory($descNorm, null, $categorias);
                $categoriaId = $sug['id'];
            }
            if ($centroId === null) {
                [$centroId] = DocumentAnalyzer::matchCostCenter((string) $linha['description'], $descNorm, $centros);
            }
            $similar = $modelo->findSimilar($userId, $accountId, (string) $linha['date'], (float) $linha['amount']);
            $status = isset($existentes[$linha['import_ref']]) ? 'imported' : ($similar ? 'similar' : null);
            $saida[] = $linha + [
                'category_id' => $categoriaId,
                'cost_center_id' => $centroId,
                'duplicate' => $status,
                'duplicate_hint' => $similar ? $similar->description : null,
                'skip' => $status === 'imported',
            ];
        }
        return $saida;
    }

    private function payload(): array
    {
        $raw = file_get_contents('php://input') ?: '';
        if ($raw !== '' && str_contains((string) ($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json')) {
            $json = json_decode($raw, true);
            return is_array($json) ? $json : [];
        }
        return $_POST;
    }
}
