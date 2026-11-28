<?php
namespace App\Models;

use App\Core\Model;

class CostCenter extends Model
{
    protected string $table = 'cost_centers';

    public function forUser(int $userId, bool $activeOnly = false): array
    {
        $sql = 'SELECT * FROM cost_centers WHERE (user_id IS NULL OR user_id = :user_id)';
        if ($activeOnly) $sql .= " AND status = 'active'";
        $sql .= " ORDER BY (kind = 'property') DESC, name ASC";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll();
    }

    public function findForUser(int $id, int $userId): ?object
    {
        $stmt = $this->pdo->prepare('SELECT * FROM cost_centers WHERE id = :id AND (user_id IS NULL OR user_id = :user_id) LIMIT 1');
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $center = $stmt->fetch();
        return $center ?: null;
    }

    public function create(int $userId, array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO cost_centers (user_id, name, kind, address, identifiers, code, description, status)
             VALUES (:user_id, :name, :kind, :address, :identifiers, :code, :description, :status)'
        );
        $stmt->execute([
            'user_id' => $userId, 'name' => $data['name'],
            'kind' => $data['kind'] ?? 'general',
            'address' => $data['address'] ?? null,
            'identifiers' => $data['identifiers'] ?? null,
            'code' => $data['code'], 'description' => $data['description'], 'status' => $data['status'],
        ]);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE cost_centers SET name = :name, kind = :kind, address = :address, identifiers = :identifiers,
              code = :code, description = :description, status = :status
             WHERE id = :id AND user_id = :user_id'
        );
        return $stmt->execute([
            'id' => $id, 'user_id' => $userId, 'name' => $data['name'],
            'kind' => $data['kind'] ?? 'general',
            'address' => $data['address'] ?? null,
            'identifiers' => $data['identifiers'] ?? null,
            'code' => $data['code'], 'description' => $data['description'], 'status' => $data['status'],
        ]);
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM cost_centers WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
    }

    /** Total de despesas do periodo por centro de custo (cartoes de imovel). */
    public function monthlyTotals(int $userId, string $from, string $to): array
    {
        $stmt = $this->pdo->prepare(
            "SELECT cost_center_id, COALESCE(SUM(amount), 0) AS total
             FROM transactions
             WHERE user_id = :u AND type = 'expense' AND status <> 'cancelled'
               AND cost_center_id IS NOT NULL AND transaction_date BETWEEN :i AND :f
             GROUP BY cost_center_id"
        );
        $stmt->execute(['u' => $userId, 'i' => $from, 'f' => $to]);
        $out = [];
        foreach ($stmt->fetchAll() as $row) {
            $out[(int) $row->cost_center_id] = (float) $row->total;
        }
        return $out;
    }

    public function seedDefaults(int $userId): void
    {
        $defaults = [
            ['Pessoal', 'PES'], ['Casa', 'CAS'], ['Empresa', 'EMP'],
            ['Carro', 'CAR'], ['Operacional', 'OPE'],
        ];
        $check = $this->pdo->prepare('SELECT COUNT(*) FROM cost_centers WHERE user_id IS NULL OR user_id = :user_id');
        $check->execute(['user_id' => $userId]);
        if ((int) $check->fetchColumn() > 0) return;
        $stmt = $this->pdo->prepare(
            'INSERT INTO cost_centers (user_id, name, code, status) VALUES (:user_id, :name, :code, \'active\')'
        );
        foreach ($defaults as [$name, $code]) $stmt->execute(compact('userId', 'name', 'code'));
    }
}
