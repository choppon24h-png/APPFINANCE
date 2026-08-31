<?php
namespace App\Models;

use App\Core\Model;

class Category extends Model
{
    protected string $table = 'categories';

    public function forUser(int $userId, ?string $type = null, bool $activeOnly = false): array
    {
        $sql = 'SELECT * FROM categories WHERE (user_id IS NULL OR user_id = :user_id)';
        $params = ['user_id' => $userId];
        if ($type !== null) {
            $sql .= ' AND type = :type';
            $params['type'] = $type;
        }
        if ($activeOnly) $sql .= " AND status = 'active'";
        $sql .= ' ORDER BY name ASC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    public function findForUser(int $id, int $userId): ?object
    {
        $stmt = $this->pdo->prepare('SELECT * FROM categories WHERE id = :id AND (user_id IS NULL OR user_id = :user_id) LIMIT 1');
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $category = $stmt->fetch();
        return $category ?: null;
    }

    public function create(int $userId, array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO categories (user_id, name, type, icon, color, parent_id, status)
             VALUES (:user_id, :name, :type, :icon, :color, :parent_id, :status)'
        );
        $stmt->execute([
            'user_id' => $userId, 'name' => $data['name'], 'type' => $data['type'],
            'icon' => $data['icon'], 'color' => $data['color'], 'parent_id' => $data['parent_id'],
            'status' => $data['status'],
        ]);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE categories SET name = :name, type = :type, icon = :icon, color = :color,
                parent_id = :parent_id, status = :status
             WHERE id = :id AND user_id = :user_id'
        );
        return $stmt->execute([
            'id' => $id, 'user_id' => $userId, 'name' => $data['name'], 'type' => $data['type'],
            'icon' => $data['icon'], 'color' => $data['color'], 'parent_id' => $data['parent_id'],
            'status' => $data['status'],
        ]);
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM categories WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
    }

    public function seedDefaults(int $userId): void
    {
        $defaults = [
            ['Alimentação', 'expense', 'utensils', '#ef4444'], ['Moradia', 'expense', 'home', '#f97316'],
            ['Transporte', 'expense', 'car', '#eab308'], ['Saúde', 'expense', 'heart', '#ec4899'],
            ['Educação', 'expense', 'book', '#8b5cf6'], ['Assinaturas', 'expense', 'repeat', '#06b6d4'],
            ['Lazer', 'expense', 'smile', '#14b8a6'], ['Impostos', 'expense', 'receipt', '#64748b'],
            ['Outros', 'expense', 'tag', '#64748b'], ['Salário', 'income', 'briefcase', '#16a34a'],
            ['Vendas', 'income', 'shopping-bag', '#22c55e'], ['Serviços', 'income', 'briefcase', '#84cc16'],
            ['Comissões', 'income', 'percent', '#10b981'], ['Rendimentos', 'income', 'trending-up', '#0ea5e9'],
            ['Reembolso', 'income', 'rotate-ccw', '#6366f1'], ['Outros', 'income', 'tag', '#64748b'],
        ];
        $check = $this->pdo->prepare('SELECT COUNT(*) FROM categories WHERE user_id IS NULL OR user_id = :user_id');
        $check->execute(['user_id' => $userId]);
        if ((int) $check->fetchColumn() > 0) return;
        $stmt = $this->pdo->prepare(
            'INSERT INTO categories (user_id, name, type, icon, color, status) VALUES (:user_id, :name, :type, :icon, :color, \'active\')'
        );
        foreach ($defaults as [$name, $type, $icon, $color]) {
            $stmt->execute(compact('userId', 'name', 'type', 'icon', 'color'));
        }
    }
}
