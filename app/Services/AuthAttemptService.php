<?php
namespace App\Services;

use App\Core\Database;

/**
 * Rate-limit de autenticacao usando a tabela auth_attempts.
 *
 * Tudo aqui e "melhor esforco": se a tabela nao existir, o login
 * continua funcionando (apenas sem limite), para nao travar o acesso
 * em uma instalacao antiga.
 */
class AuthAttemptService
{
    public const ACTION_LOGIN    = 'login';
    public const ACTION_REGISTER = 'register';
    public const ACTION_OAUTH    = 'oauth';

    public static function ip(): string
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '';
        return substr($ip !== '' ? $ip : '0.0.0.0', 0, 45);
    }

    public static function record(string $action, bool $success, ?string $email = null): void
    {
        try {
            $stmt = Database::getInstance()->prepare("
                INSERT INTO auth_attempts (ip, email, action, success, created_at)
                VALUES (:ip, :email, :action, :success, NOW())
            ");
            $stmt->execute([
                'ip'      => self::ip(),
                'email'   => $email !== null ? mb_strtolower(mb_substr($email, 0, 255)) : null,
                'action'  => $action,
                'success' => $success ? 1 : 0,
            ]);
        } catch (\Throwable $e) {
            // silencioso: rate-limit nao pode derrubar o login
        }
    }

    /**
     * Quantos minutos faltam de bloqueio para este IP+e-mail (0 = liberado).
     */
    public static function loginLockMinutes(string $email): int
    {
        $max      = max(1, (int) ($_ENV['LOGIN_MAX_ATTEMPTS'] ?? 5));
        $lockMin  = max(1, (int) ($_ENV['LOGIN_LOCK_MINUTES'] ?? 15));

        try {
            // PDO nao aceita bind em INTERVAL: usamos concatenacao segura (valor inteiro)
            $stmt = Database::getInstance()->prepare("
                SELECT COUNT(*) AS total, MAX(created_at) AS ultima
                FROM auth_attempts
                WHERE action = 'login'
                  AND success = 0
                  AND ip = :ip
                  AND (email = :email OR email IS NULL)
                  AND created_at >= DATE_SUB(NOW(), INTERVAL {$lockMin} MINUTE)
            ");
            $stmt->execute(['ip' => self::ip(), 'email' => mb_strtolower($email)]);
            $row = $stmt->fetch();

            if (!$row || (int) $row->total < $max || empty($row->ultima)) {
                return 0;
            }

            $restante = $lockMin - (int) floor((time() - strtotime($row->ultima)) / 60);
            return max(1, min($lockMin, $restante));
        } catch (\Throwable $e) {
            return 0;
        }
    }

    /**
     * O IP ainda pode criar contas nesta hora?
     */
    public static function canRegister(): bool
    {
        $limite = max(1, (int) ($_ENV['REGISTRATION_MAX_PER_HOUR'] ?? 5));

        try {
            $stmt = Database::getInstance()->prepare("
                SELECT COUNT(*) AS total
                FROM auth_attempts
                WHERE action = 'register'
                  AND success = 1
                  AND ip = :ip
                  AND created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
            ");
            $stmt->execute(['ip' => self::ip()]);
            $row = $stmt->fetch();
            return !$row || (int) $row->total < $limite;
        } catch (\Throwable $e) {
            return true;
        }
    }
}
