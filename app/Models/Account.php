<?php
namespace App\Models;

use App\Core\Model;
use PDO;

class Account extends Model
{
    protected string $table = 'accounts';

    public function forUser(int $userId, bool $activeOnly = false): array
    {
        $sql = 'SELECT * FROM accounts WHERE user_id = :user_id';
        if ($activeOnly) $sql .= " AND status = 'active'";
        $sql .= ' ORDER BY status = \'active\' DESC, name ASC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll();
    }

    public function findForUser(int $id, int $userId): ?object
    {
        $stmt = $this->pdo->prepare('SELECT * FROM accounts WHERE id = :id AND user_id = :user_id LIMIT 1');
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $account = $stmt->fetch();
        return $account ?: null;
    }

    public function create(int $userId, array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO accounts
                (user_id, name, bank_name, bank_code, account_type, agency, account_number,
                 initial_balance, current_balance, initial_date, status, notes)
             VALUES (:user_id, :name, :bank_name, :bank_code, :account_type, :agency, :account_number,
                     :initial_balance, :current_balance, :initial_date, :status, :notes)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'name' => $data['name'],
            'bank_name' => $data['bank_name'],
            'bank_code' => $data['bank_code'] ?? null,
            'account_type' => $data['account_type'],
            'agency' => $data['agency'],
            'account_number' => $data['account_number'],
            'initial_balance' => $data['initial_balance'],
            'current_balance' => $data['initial_balance'],
            'initial_date' => $data['initial_date'],
            'status' => $data['status'],
            'notes' => $data['notes'],
        ]);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE accounts SET name = :name, bank_name = :bank_name, bank_code = :bank_code, account_type = :account_type,
                agency = :agency, account_number = :account_number, status = :status, notes = :notes
             WHERE id = :id AND user_id = :user_id'
        );
        return $stmt->execute([
            'id' => $id,
            'user_id' => $userId,
            'name' => $data['name'],
            'bank_name' => $data['bank_name'],
            'account_type' => $data['account_type'],
            'agency' => $data['agency'],
            'account_number' => $data['account_number'],
            'status' => $data['status'],
            'notes' => $data['notes'],
        ]);
    }

    public function setBalance(int $id, int $userId, float $balance): void
    {
        $stmt = $this->pdo->prepare('UPDATE accounts SET current_balance = :balance WHERE id = :id AND user_id = :user_id');
        $stmt->execute(['balance' => number_format($balance, 2, '.', ''), 'id' => $id, 'user_id' => $userId]);
    }

    public function totalBalance(int $userId): float
    {
        $stmt = $this->pdo->prepare("SELECT COALESCE(SUM(current_balance), 0) FROM accounts WHERE user_id = :user_id AND status = 'active'");
        $stmt->execute(['user_id' => $userId]);
        return (float) $stmt->fetchColumn();
    }

    public function balanceForUpdate(int $id, int $userId): ?float
    {
        $stmt = $this->pdo->prepare('SELECT current_balance FROM accounts WHERE id = :id AND user_id = :user_id FOR UPDATE');
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $value = $stmt->fetchColumn();
        return $value === false ? null : (float) $value;
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM accounts WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
    }
}
