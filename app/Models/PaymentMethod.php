<?php
namespace App\Models;

use App\Core\Model;

class PaymentMethod extends Model
{
    protected string $table = 'payment_methods';

    /** Rotulos das formas antigas (antes do catalogo) para nao perder historico. */
    public const LEGACY = [
        'pix' => 'PIX',
        'debit' => 'Débito',
        'credit' => 'Crédito',
        'boleto' => 'Boleto',
        'cash' => 'Dinheiro',
        'transfer' => 'Transferência',
        'other' => 'Outro',
    ];

    /** Rotulos dos slugs criados pela migration 0007 (usados em relatorios). */
    public const LABELS = [
        'pix' => 'PIX',
        'debito_conta' => 'DÉBITO EM CONTA',
        'debito_automatico' => 'DÉBITO AUTOMÁTICO',
        'cartao_debito' => 'CARTÃO DE DÉBITO',
        'cartao_credito' => 'CARTÃO DE CRÉDITO',
        'boleto' => 'BOLETO',
        'dinheiro' => 'DINHEIRO',
        'transferencia' => 'TRANSFERÊNCIA',
        'outro' => 'OUTRO',
    ];

    public const KINDS = [
        'bank' => 'Conta bancária',
        'card' => 'Cartão',
        'cash' => 'Dinheiro',
        'transfer' => 'Transferência',
        'other' => 'Outro',
    ];

    public function forUser(int $userId, bool $activeOnly = false): array
    {
        $sql = 'SELECT * FROM payment_methods WHERE (user_id IS NULL OR user_id = :user_id)';
        if ($activeOnly) $sql .= " AND status = 'active'";
        $sql .= ' ORDER BY sort_order ASC, name ASC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll();
    }

    public function findForUser(int $id, int $userId): ?object
    {
        $stmt = $this->pdo->prepare('SELECT * FROM payment_methods WHERE id = :id AND user_id = :user_id LIMIT 1');
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $method = $stmt->fetch();
        return $method ?: null;
    }

    public function create(int $userId, array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO payment_methods (user_id, name, slug, kind, icon, sort_order, status)
             VALUES (:user_id, :name, :slug, :kind, :icon, :sort_order, :status)'
        );
        $stmt->execute([
            'user_id' => $userId, 'name' => $data['name'], 'slug' => $data['slug'],
            'kind' => $data['kind'] ?? 'other', 'icon' => $data['icon'] ?? null,
            'sort_order' => (int) ($data['sort_order'] ?? 0), 'status' => $data['status'] ?? 'active',
        ]);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE payment_methods SET name = :name, slug = :slug, kind = :kind, icon = :icon,
                sort_order = :sort_order, status = :status
             WHERE id = :id AND user_id = :user_id'
        );
        return $stmt->execute([
            'id' => $id, 'user_id' => $userId, 'name' => $data['name'], 'slug' => $data['slug'],
            'kind' => $data['kind'] ?? 'other', 'icon' => $data['icon'] ?? null,
            'sort_order' => (int) ($data['sort_order'] ?? 0), 'status' => $data['status'] ?? 'active',
        ]);
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM payment_methods WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
    }

    /** Slugs ja usados pelo usuario (para gerar um slug unico). */
    public function slugsForUser(int $userId): array
    {
        $stmt = $this->pdo->prepare('SELECT slug FROM payment_methods WHERE user_id = :user_id');
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll(\PDO::FETCH_COLUMN) ?: [];
    }

    /** A forma existe no catalogo (padrao do sistema ou do usuario) e esta ativa? */
    public function existsForUser(int $userId, string $slug): bool
    {
        $stmt = $this->pdo->prepare(
            "SELECT 1 FROM payment_methods
             WHERE slug = :slug AND (user_id IS NULL OR user_id = :user_id) AND status = 'active' LIMIT 1"
        );
        $stmt->execute(['slug' => $slug, 'user_id' => $userId]);
        return (bool) $stmt->fetchColumn();
    }

    /**
     * Lista pronta para <select>: slug => rotulo. Mantem os slugs antigos
     * quando ainda existem lancamentos com eles.
     */
    public function options(int $userId, ?string $incluirSlug = null): array
    {
        $opcoes = [];
        foreach ($this->forUser($userId, true) as $method) {
            $opcoes[$method->slug] = $method->name;
        }
        foreach (self::LEGACY as $slug => $label) {
            if (!isset($opcoes[$slug])) $opcoes[$slug] = $label;
        }
        if ($incluirSlug !== null && $incluirSlug !== '' && !isset($opcoes[$incluirSlug])) {
            $opcoes[$incluirSlug] = ucfirst(str_replace('_', ' ', $incluirSlug));
        }
        return $opcoes;
    }

    public static function labelFor(?string $slug): string
    {
        if ($slug === null || $slug === '') return '—';
        return self::LABELS[$slug] ?? self::LEGACY[$slug] ?? ucfirst(str_replace('_', ' ', $slug));
    }
}
