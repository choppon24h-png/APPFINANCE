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
        $sql .= ' ORDER BY name ASC';
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
            'INSERT INTO cost_centers (user_id, name, code, description, status)
             VALUES (:user_id, :name, :code, :description, :status)'
        );
        $stmt->execute([
            'user_id' => $userId, 'name' => $data['name'], 'code' => $data['code'],
            'description' => $data['description'], 'status' => $data['status'],
        ]);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE cost_centers SET name = :name, code = :code, description = :description, status = :status
             WHERE id = :id AND user_id = :user_id'
        );
        return $stmt->execute([
            'id' => $id, 'user_id' => $userId, 'name' => $data['name'], 'code' => $data['code'],
            'description' => $data['description'], 'status' => $data['status'],
        ]);
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM cost_centers WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
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
