<?php
namespace App\Core;

use PDO;

/**
 * Verifica se o banco ja recebeu a migration 0004 (acesso).
 *
 * Serve para transformar um erro 500 de SQL em uma mensagem clara de
 * "banco precisa ser atualizado", sem derrubar a aplicacao quando o
 * deploy do codigo acontece antes da migration.
 */
class Schema
{
    private static ?array $cache = null;

    /** Colunas que a 0004 adiciona em users. */
    private const USER_COLUMNS = [
        'birth_date',
        'auth_provider',
        'avatar_url',
        'email_verified_at',
        'terms_accepted_at',
        'registration_ip',
    ];

    private const TABLES = ['user_identities', 'auth_attempts'];

    /**
     * Lista o que falta para a etapa de acesso funcionar.
     * Retorna [] quando esta tudo aplicado.
     */
    public static function missingAccess(): array
    {
        if (self::$cache !== null) {
            return self::$cache;
        }

        $faltando = [];

        try {
            $pdo = Database::getInstance();
            // Usa o banco realmente conectado (evita falso negativo quando
            // DB_DATABASE nao esta no .env ou o host usa prefixo do cPanel)
            $banco = (string) $pdo->query('SELECT DATABASE()')->fetchColumn();
            if ($banco === '') {
                $banco = (string) ($_ENV['DB_DATABASE'] ?? '');
            }

            $stmt = $pdo->prepare("
                SELECT TABLE_NAME
                FROM information_schema.TABLES
                WHERE TABLE_SCHEMA = :banco
            ");
            $stmt->execute(['banco' => $banco]);
            $tabelas = array_map('strtolower', $stmt->fetchAll(PDO::FETCH_COLUMN));

            foreach (self::TABLES as $tabela) {
                if (!in_array($tabela, $tabelas, true)) {
                    $faltando[] = 'tabela ' . $tabela;
                }
            }

            $stmt = $pdo->prepare("
                SELECT COLUMN_NAME
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = :banco AND TABLE_NAME = 'users'
            ");
            $stmt->execute(['banco' => $banco]);
            $colunas = array_map('strtolower', $stmt->fetchAll(PDO::FETCH_COLUMN));

            foreach (self::USER_COLUMNS as $coluna) {
                if (!in_array($coluna, $colunas, true)) {
                    $faltando[] = 'users.' . $coluna;
                }
            }

            // Permissao do painel (0004 insere em permissions)
            if (in_array('permissions', $tabelas, true)) {
                $tem = $pdo->query("SELECT COUNT(*) FROM permissions WHERE slug = 'access_admin_panel'")->fetchColumn();
                if ((int) $tem === 0) {
                    $faltando[] = 'permissao access_admin_panel';
                }
            }
        } catch (\Throwable $e) {
            Logger::warning('Nao foi possivel verificar o schema', ['erro' => $e->getMessage()]);
            // Sem informacao confiavel: nao bloqueia o acesso
            self::$cache = [];
            return self::$cache;
        }

        self::$cache = $faltando;

        if ($faltando) {
            Logger::warning('Schema de acesso incompleto', ['faltando' => $faltando]);
        }

        return self::$cache;
    }

    public static function accessReady(): bool
    {
        return self::missingAccess() === [];
    }

    /** Texto curto para exibir ao usuario. */
    public static function missingLabel(): string
    {
        $faltando = self::missingAccess();

        return $faltando ? implode(', ', array_slice($faltando, 0, 6)) : '';
    }
}
