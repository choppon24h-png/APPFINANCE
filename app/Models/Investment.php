<?php
namespace App\Models;

use App\Core\Model;
use PDO;

class Investment extends Model
{
    protected string $table = 'investments';

    public function forUser(int $userId): array
    {
        $stmt = $this->pdo->prepare(
            "SELECT i.*, a.name AS account_name,
                COALESCE((SELECT SUM(CASE WHEN m.type IN ('income','adjustment') THEN m.amount WHEN m.type = 'redemption' THEN -m.amount ELSE 0 END)
                    FROM investment_movements m WHERE m.investment_id = i.id), 0) AS movement_result,
                COALESCE((SELECT SUM(r.return_amount) FROM investment_returns r WHERE r.investment_id = i.id), 0) AS accumulated_return,
                COALESCE((SELECT SUM(r.return_percentage) FROM investment_returns r WHERE r.investment_id = i.id), 0) AS accumulated_rate
             FROM investments i JOIN accounts a ON a.id = i.account_id AND a.user_id = i.user_id
             WHERE i.user_id = :user_id ORDER BY i.status = 'active' DESC, accumulated_return DESC, i.name ASC"
        );
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll();
    }

    public function findForUser(int $id, int $userId): ?object
    {
        $stmt = $this->pdo->prepare(
            'SELECT i.*, a.name AS account_name FROM investments i
             JOIN accounts a ON a.id = i.account_id AND a.user_id = i.user_id
             WHERE i.id = :id AND i.user_id = :user_id LIMIT 1'
        );
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $investment = $stmt->fetch();
        return $investment ?: null;
    }

    public function create(array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO investments (user_id, account_id, institution, investment_type, name,
             amount_invested, application_date, interest_rate, rate_type, benchmark, liquidity,
             maturity_date, status, notes)
             VALUES (:user_id, :account_id, :institution, :investment_type, :name, :amount_invested,
             :application_date, :interest_rate, :rate_type, :benchmark, :liquidity, :maturity_date, :status, :notes)'
        );
        $stmt->execute($data);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE investments SET account_id = :account_id, institution = :institution,
             investment_type = :investment_type, name = :name, interest_rate = :interest_rate,
             rate_type = :rate_type, benchmark = :benchmark, liquidity = :liquidity,
             maturity_date = :maturity_date, status = :status, notes = :notes
             WHERE id = :id AND user_id = :user_id'
        );
        $data['id'] = $id; $data['user_id'] = $userId;
        return $stmt->execute($data);
    }

    public function addMovement(array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO investment_movements (investment_id, type, amount, movement_date, rate, notes)
             VALUES (:investment_id, :type, :amount, :movement_date, :rate, :notes)'
        );
        $stmt->execute($data);
        return (int) $this->pdo->lastInsertId();
    }

    public function addReturn(array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO investment_returns
             (investment_id, reference_month, reference_year, initial_value, return_amount, return_percentage, final_value)
             VALUES (:investment_id, :reference_month, :reference_year, :initial_value, :return_amount, :return_percentage, :final_value)
             ON DUPLICATE KEY UPDATE initial_value = VALUES(initial_value), return_amount = VALUES(return_amount),
                return_percentage = VALUES(return_percentage), final_value = VALUES(final_value), updated_at = CURRENT_TIMESTAMP'
        );
        $stmt->execute($data);
        return (int) $this->pdo->lastInsertId();
    }

    public function returnsForUser(int $investmentId, int $userId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT r.* FROM investment_returns r JOIN investments i ON i.id = r.investment_id
             WHERE r.investment_id = :investment_id AND i.user_id = :user_id
             ORDER BY reference_year DESC, reference_month DESC'
        );
        $stmt->execute(['investment_id' => $investmentId, 'user_id' => $userId]);
        return $stmt->fetchAll();
    }

    public function totals(int $userId): object
    {
        $stmt = $this->pdo->prepare(
            "SELECT
                COALESCE((SELECT SUM(i.amount_invested) FROM investments i WHERE i.user_id = :user_id_invested AND i.status <> 'inactive'), 0) AS invested,
                COALESCE((SELECT SUM(r.return_amount) FROM investment_returns r JOIN investments i ON i.id = r.investment_id
                    WHERE i.user_id = :user_id_month AND i.status <> 'inactive'
                      AND r.reference_year = YEAR(CURDATE()) AND r.reference_month = MONTH(CURDATE())), 0) AS monthly_return,
                COALESCE((SELECT SUM(r.return_amount) FROM investment_returns r JOIN investments i ON i.id = r.investment_id
                    WHERE i.user_id = :user_id_total AND i.status <> 'inactive'), 0) AS total_return,
                COALESCE((SELECT SUM(i.amount_invested) FROM investments i WHERE i.user_id = :user_id_current AND i.status <> 'inactive'), 0)
                + COALESCE((SELECT SUM(r.return_amount) FROM investment_returns r JOIN investments i ON i.id = r.investment_id
                    WHERE i.user_id = :user_id_current_return AND i.status <> 'inactive'), 0) AS current_value"
        );
        $stmt->execute([
            'user_id_invested' => $userId, 'user_id_month' => $userId, 'user_id_total' => $userId,
            'user_id_current' => $userId, 'user_id_current_return' => $userId,
        ]);
        return $stmt->fetch();
    }

    public function ranked(int $userId, string $orderBy = 'absolute'): array
    {
        $order = $orderBy === 'percentage' ? 'return_percentage DESC' : 'return_amount DESC';
        $stmt = $this->pdo->prepare(
            "SELECT i.id, i.name, i.institution, i.amount_invested,
                COALESCE(SUM(r.return_amount), 0) AS return_amount,
                CASE WHEN i.amount_invested > 0 THEN (COALESCE(SUM(r.return_amount), 0) / i.amount_invested) * 100 ELSE 0 END AS return_percentage,
                COALESCE(SUM(r.return_amount), 0) + i.amount_invested AS current_value
             FROM investments i LEFT JOIN investment_returns r ON r.investment_id = i.id
             WHERE i.user_id = :user_id AND i.status = 'active'
             GROUP BY i.id, i.name, i.institution, i.amount_invested
             ORDER BY {$order}, i.name ASC LIMIT 5"
        );
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll();
    }
}
