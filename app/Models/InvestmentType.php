<?php
namespace App\Models;

use App\Core\Logger;
use App\Core\Model;
use Throwable;

class InvestmentType extends Model
{
    protected string $table = 'investment_types';

    /** Evita repetir o aviso de tabela ausente a cada consulta. */
    private static bool $avisou = false;

    public const BENCHMARKS = [
        'cdi' => 'CDI',
        'selic' => 'Selic',
        'ipca' => 'IPCA',
        'prefixado' => 'Prefixado',
        'none' => 'Sem índice',
    ];

    /** Taxas de referência anuais usadas na estimativa (editáveis no formulário). */
    public const REFERENCE_RATES = [
        'cdi' => 10.65,
        'selic' => 10.65,
        'ipca' => 4.50,
        'prefixado' => 0.0,
        'none' => 0.0,
    ];

    public function forUser(int $userId, bool $activeOnly = false): array
    {
        $sql = 'SELECT * FROM investment_types WHERE (user_id IS NULL OR user_id = :user_id)';
        if ($activeOnly) $sql .= " AND status = 'active'";
        $sql .= ' ORDER BY name ASC';
        try {
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute(['user_id' => $userId]);
            return $stmt->fetchAll();
        } catch (Throwable $e) {
            self::avisarAusencia($e);
            return [];
        }
    }

    public function findForUser(int $id, int $userId): ?object
    {
        try {
            $stmt = $this->pdo->prepare(
                'SELECT * FROM investment_types WHERE id = :id AND (user_id IS NULL OR user_id = :user_id) LIMIT 1'
            );
            $stmt->execute(['id' => $id, 'user_id' => $userId]);
            $type = $stmt->fetch();
            return $type ?: null;
        } catch (Throwable $e) {
            self::avisarAusencia($e);
            return null;
        }
    }

    /** Registra uma unica vez que o catalogo ainda nao existe no banco. */
    private static function avisarAusencia(Throwable $e): void
    {
        if (self::$avisou) {
            return;
        }
        self::$avisou = true;
        Logger::warning('investment_types.indisponivel', [
            'motivo' => 'tabela ausente ou inacessivel; usando a lista padrao',
            'erro'   => $e->getMessage(),
            'sqlstate' => (string) $e->getCode(),
        ]);
    }

    public function create(int $userId, array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO investment_types (user_id, name, slug, benchmark, default_rate, default_rate_period, status)
             VALUES (:user_id, :name, :slug, :benchmark, :default_rate, :default_rate_period, :status)'
        );
        $stmt->execute([
            'user_id' => $userId, 'name' => $data['name'], 'slug' => $data['slug'],
            'benchmark' => $data['benchmark'] ?? 'none', 'default_rate' => $data['default_rate'] ?? null,
            'default_rate_period' => $data['default_rate_period'] ?? 'annual', 'status' => $data['status'] ?? 'active',
        ]);
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE investment_types SET name = :name, slug = :slug, benchmark = :benchmark,
                default_rate = :default_rate, default_rate_period = :default_rate_period, status = :status
             WHERE id = :id AND user_id = :user_id'
        );
        return $stmt->execute([
            'id' => $id, 'user_id' => $userId, 'name' => $data['name'], 'slug' => $data['slug'],
            'benchmark' => $data['benchmark'] ?? 'none', 'default_rate' => $data['default_rate'] ?? null,
            'default_rate_period' => $data['default_rate_period'] ?? 'annual', 'status' => $data['status'] ?? 'active',
        ]);
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM investment_types WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
    }

    public function slugsForUser(int $userId): array
    {
        $stmt = $this->pdo->prepare('SELECT slug FROM investment_types WHERE user_id = :user_id');
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll(\PDO::FETCH_COLUMN) ?: [];
    }

    /** Opções para <select>: id => nome (com o índice entre parênteses). */
    public function options(int $userId): array
    {
        $opcoes = [];
        foreach ($this->forUser($userId, true) as $type) {
            $indice = self::BENCHMARKS[$type->benchmark] ?? '';
            $opcoes[(int) $type->id] = $type->name . ($indice !== '' && $indice !== 'Sem índice' ? ' · ' . $indice : '');
        }
        return $opcoes;
    }

    public static function benchmarkLabel(?string $benchmark): string
    {
        return self::BENCHMARKS[$benchmark ?? 'none'] ?? 'Sem índice';
    }
}
