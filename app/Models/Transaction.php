<?php
namespace App\Models;

use App\Core\Model;
use PDO;

class Transaction extends Model
{
    protected string $table = 'transactions';

    private function filters(int $userId, array $filters): array
    {
        $where = ['t.user_id = :user_id'];
        $params = ['user_id' => $userId];
        if (!empty($filters['search'])) {
            $where[] = '(t.description LIKE :search_desc OR t.notes LIKE :search_notes)';
            $params['search_desc']  = '%' . trim($filters['search']) . '%';
            $params['search_notes'] = '%' . trim($filters['search']) . '%';
        }
        foreach (['type', 'status'] as $field) {
            if (!empty($filters[$field])) {
                $where[] = "t.{$field} = :{$field}";
                $params[$field] = $filters[$field];
            }
        }
        foreach (['account_id', 'category_id', 'cost_center_id'] as $field) {
            if (!empty($filters[$field])) {
                $where[] = "t.{$field} = :{$field}";
                $params[$field] = (int) $filters[$field];
            }
        }
        if (!empty($filters['center_kind'])) {
            $where[] = 'cc.kind = :center_kind';
            $params['center_kind'] = (string) $filters['center_kind'];
        }
        if (!empty($filters['date_from'])) {
            $where[] = 't.transaction_date >= :date_from';
            $params['date_from'] = $filters['date_from'];
        }
        if (!empty($filters['date_to'])) {
            $where[] = 't.transaction_date <= :date_to';
            $params['date_to'] = $filters['date_to'];
        }
        return [implode(' AND ', $where), $params];
    }

    public function paginateForUser(int $userId, array $filters, int $page = 1, int $perPage = 30): array
    {
        [$where, $params] = $this->filters($userId, $filters);
        $page = max(1, $page);
        $perPage = min(100, max(1, $perPage));
        $params['limit'] = $perPage;
        $params['offset'] = ($page - 1) * $perPage;
        $stmt = $this->pdo->prepare(
            "SELECT t.*, a.name AS account_name, c.name AS category_name, cc.name AS cost_center_name, cc.kind AS cost_center_kind
             FROM transactions t
             JOIN accounts a ON a.id = t.account_id AND a.user_id = t.user_id
             LEFT JOIN categories c ON c.id = t.category_id
             LEFT JOIN cost_centers cc ON cc.id = t.cost_center_id
             WHERE {$where}
             ORDER BY t.transaction_date DESC, t.id DESC
             LIMIT :limit OFFSET :offset"
        );
        foreach ($params as $key => $value) {
            $stmt->bindValue(':' . $key, $value, in_array($key, ['limit', 'offset', 'user_id', 'account_id', 'category_id', 'cost_center_id'], true) ? PDO::PARAM_INT : PDO::PARAM_STR);
        }
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function allForUser(int $userId, array $filters): array
    {
        [$where, $params] = $this->filters($userId, $filters);
        $stmt = $this->pdo->prepare(
            "SELECT t.*, a.name AS account_name, c.name AS category_name, cc.name AS cost_center_name, cc.kind AS cost_center_kind
             FROM transactions t
             JOIN accounts a ON a.id = t.account_id AND a.user_id = t.user_id
             LEFT JOIN categories c ON c.id = t.category_id
             LEFT JOIN cost_centers cc ON cc.id = t.cost_center_id
             WHERE {$where}
             ORDER BY t.transaction_date DESC, t.id DESC"
        );
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    public function countForUser(int $userId, array $filters): int
    {
        [$where, $params] = $this->filters($userId, $filters);
        $stmt = $this->pdo->prepare(
            "SELECT COUNT(*) FROM transactions t LEFT JOIN cost_centers cc ON cc.id = t.cost_center_id WHERE {$where}"
        );
        $stmt->execute($params);
        return (int) $stmt->fetchColumn();
    }

    public function findForUser(int $id, int $userId): ?object
    {
        $stmt = $this->pdo->prepare(
            'SELECT t.*, a.name AS account_name, c.name AS category_name, cc.name AS cost_center_name, cc.kind AS cost_center_kind
             FROM transactions t
             JOIN accounts a ON a.id = t.account_id AND a.user_id = t.user_id
             LEFT JOIN categories c ON c.id = t.category_id
             LEFT JOIN cost_centers cc ON cc.id = t.cost_center_id
             WHERE t.id = :id AND t.user_id = :user_id LIMIT 1'
        );
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $transaction = $stmt->fetch();
        return $transaction ?: null;
    }

    public function create(array $data): int
    {
        // Campos novos (migration 0006) sao opcionais para nao quebrar
        // chamadas antigas (recorrencia, transferencia, importacao).
        $data += ['document_code' => null, 'import_ref' => null, 'attachment_path' => null];
        $stmt = $this->pdo->prepare(
            'INSERT INTO transactions
             (user_id, account_id, category_id, cost_center_id, type, description, amount,
              transaction_date, due_date, payment_date, status, payment_method, notes,
              recurrence_id, recurrence_key, transfer_id,
              document_code, import_ref, attachment_path)
             VALUES (:user_id, :account_id, :category_id, :cost_center_id, :type, :description, :amount,
              :transaction_date, :due_date, :payment_date, :status, :payment_method, :notes,
              :recurrence_id, :recurrence_key, :transfer_id,
              :document_code, :import_ref, :attachment_path)'
        );
        $stmt->execute($data);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        // document_code e attachment_path so entram no UPDATE quando vieram
        // no POST (evita apagar o codigo lido ou o anexo em uma edicao rapida).
        $extra = '';
        if (array_key_exists('document_code', $data)) {
            $extra .= ', document_code = :document_code';
        }
        if (array_key_exists('attachment_path', $data)) {
            $extra .= ', attachment_path = :attachment_path';
        } else {
            unset($data['attachment_path']);
        }
        if (!array_key_exists('document_code', $data)) {
            unset($data['document_code']);
        }
        $stmt = $this->pdo->prepare(
            'UPDATE transactions SET account_id = :account_id, category_id = :category_id,
              cost_center_id = :cost_center_id, type = :type, description = :description,
              amount = :amount, transaction_date = :transaction_date, due_date = :due_date,
              payment_date = :payment_date, status = :status, payment_method = :payment_method,
              notes = :notes' . $extra . '
             WHERE id = :id AND user_id = :user_id'
        );
        $data['id'] = $id;
        $data['user_id'] = $userId;
        return $stmt->execute($data);
    }

    /** Referencia unica da linha importada (OFX/CSV). */
    public function setImportRef(int $id, int $userId, ?string $ref): bool
    {
        $stmt = $this->pdo->prepare('UPDATE transactions SET import_ref = :r WHERE id = :id AND user_id = :u');
        return $stmt->execute(['r' => $ref, 'id' => $id, 'u' => $userId]);
    }

    /** Grava (ou limpa, com null) o caminho do anexo do lancamento. */
    public function setAttachment(int $id, int $userId, ?string $path): bool
    {
        $stmt = $this->pdo->prepare('UPDATE transactions SET attachment_path = :p WHERE id = :id AND user_id = :u');
        return $stmt->execute(['p' => $path, 'id' => $id, 'u' => $userId]);
    }

    /** Ja existe lancamento do usuario com este codigo de documento? */
    public function existsDocumentCode(int $userId, string $code): bool
    {
        $stmt = $this->pdo->prepare('SELECT 1 FROM transactions WHERE user_id = :u AND document_code = :c LIMIT 1');
        $stmt->execute(['u' => $userId, 'c' => $code]);
        return (bool) $stmt->fetchColumn();
    }

    /** Referencias de importacao ja usadas (deduplicacao do lote). */
    public function existingImportRefs(int $userId, int $accountId, array $refs): array
    {
        $refs = array_values(array_filter($refs));
        if (!$refs) {
            return [];
        }
        $in = implode(',', array_fill(0, count($refs), '?'));
        $stmt = $this->pdo->prepare(
            "SELECT import_ref FROM transactions WHERE user_id = ? AND account_id = ? AND import_ref IN ({$in})"
        );
        $stmt->execute(array_merge([$userId, $accountId], $refs));
        return $stmt->fetchAll(\PDO::FETCH_COLUMN) ?: [];
    }

    /** Lancamento parecido (mesma conta, data e valor) para avisar duplicidade. */
    public function findSimilar(int $userId, int $accountId, string $date, float $amount): ?object
    {
        $stmt = $this->pdo->prepare(
            'SELECT id, description, transaction_date, amount FROM transactions
             WHERE user_id = :u AND account_id = :a AND transaction_date = :d AND amount = :v
             LIMIT 1'
        );
        $stmt->execute(['u' => $userId, 'a' => $accountId, 'd' => $date, 'v' => $amount]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM transactions WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
    }

    public function summary(int $userId, string $from, string $to): object
    {
        $stmt = $this->pdo->prepare(
            "SELECT
                COALESCE(SUM(CASE WHEN type = 'income' AND status = 'received' THEN amount ELSE 0 END), 0) AS income,
                COALESCE(SUM(CASE WHEN type = 'expense' AND status = 'paid' THEN amount ELSE 0 END), 0) AS expense,
                COALESCE(SUM(CASE WHEN type = 'income' AND status IN ('expected','late') THEN amount ELSE 0 END), 0) AS expected_income,
                COALESCE(SUM(CASE WHEN type = 'expense' AND status IN ('pending','overdue') THEN amount ELSE 0 END), 0) AS pending_expense,
                COUNT(CASE WHEN type = 'expense' AND status = 'overdue' THEN 1 END) AS overdue_count
             FROM transactions
             WHERE user_id = :user_id AND transaction_date BETWEEN :from_date AND :to_date
               AND status <> 'cancelled'"
        );
        $stmt->execute(['user_id' => $userId, 'from_date' => $from, 'to_date' => $to]);
        return $stmt->fetch();
    }

    public function monthlyEvolution(int $userId, string $from, string $to): array
    {
        $stmt = $this->pdo->prepare(
            "SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS period,
                COALESCE(SUM(CASE WHEN type = 'income' AND status = 'received' THEN amount ELSE 0 END), 0) AS income,
                COALESCE(SUM(CASE WHEN type = 'expense' AND status = 'paid' THEN amount ELSE 0 END), 0) AS expense
             FROM transactions
             WHERE user_id = :user_id AND transaction_date BETWEEN :from_date AND :to_date
               AND status <> 'cancelled'
             GROUP BY DATE_FORMAT(transaction_date, '%Y-%m') ORDER BY period ASC"
        );
        $stmt->execute(['user_id' => $userId, 'from_date' => $from, 'to_date' => $to]);
        return $stmt->fetchAll();
    }

    public function ranking(int $userId, string $type, string $from, string $to, int $limit = 5): array
    {
        $status = $type === 'income' ? 'received' : 'paid';
        $stmt = $this->pdo->prepare(
            "SELECT COALESCE(c.name, 'Sem categoria') AS label, SUM(t.amount) AS total, COUNT(*) AS items
             FROM transactions t LEFT JOIN categories c ON c.id = t.category_id
             WHERE t.user_id = :user_id AND t.type = :type AND t.status = :status
               AND t.transaction_date BETWEEN :from_date AND :to_date
             GROUP BY t.category_id, c.name ORDER BY total DESC LIMIT :limit"
        );
        $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindValue(':type', $type);
        $stmt->bindValue(':status', $status);
        $stmt->bindValue(':from_date', $from);
        $stmt->bindValue(':to_date', $to);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function upcoming(int $userId, string $from, string $to, int $limit = 6): array
    {
        $stmt = $this->pdo->prepare(
            "SELECT t.*, a.name AS account_name
             FROM transactions t JOIN accounts a ON a.id = t.account_id AND a.user_id = t.user_id
             WHERE t.user_id = :user_id AND t.due_date BETWEEN :from_date AND :to_date
               AND t.status IN ('pending','expected','overdue','late')
             ORDER BY t.due_date ASC, t.id ASC LIMIT :limit"
        );
        $stmt->bindValue(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindValue(':from_date', $from);
        $stmt->bindValue(':to_date', $to);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function overdueCount(int $userId): int
    {
        $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM transactions WHERE user_id = :user_id AND due_date < CURDATE() AND status IN ('pending','expected','overdue','late')");
        $stmt->execute(['user_id' => $userId]);
        return (int) $stmt->fetchColumn();
    }
}
