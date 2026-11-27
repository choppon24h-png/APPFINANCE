<?php
namespace App\Core;

class Auth {
    /**
     * Tenta autenticar por e-mail e senha.
     *
     * Retorna:
     *  - 'ok'       autenticado
     *  - 'invalid'  e-mail inexistente ou senha errada (mensagem generica)
     *  - 'inactive' conta desativada (so e revelado com a senha correta)
     */
    public static function login(string $email, string $password): string {
        $pdo  = Database::getInstance();
        $stmt = $pdo->prepare("
            SELECT u.*, r.slug AS role_slug, r.name AS role_name
            FROM users u
            JOIN roles r ON r.id = u.role_id
            WHERE u.email = :email
            LIMIT 1
        ");
        $stmt->execute(['email' => $email]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user->password)) {
            return 'invalid';
        }

        if ($user->status !== 'active') {
            return 'inactive';
        }

        self::establishSession($user);
        return 'ok';
    }

    /**
     * Autentica um usuario ja carregado (cadastro, OAuth, troca de contexto).
     * O objeto precisa conter role_slug/role_name (JOIN com roles).
     */
    public static function loginUser(object $user): void {
        self::establishSession($user);
    }

    /**
     * Carrega o usuario com o slug da role (para sessao/OAuth).
     */
    public static function findUser(int $id): ?object {
        $stmt = Database::getInstance()->prepare("
            SELECT u.*, r.slug AS role_slug, r.name AS role_name
            FROM users u
            JOIN roles r ON r.id = u.role_id
            WHERE u.id = :id
            LIMIT 1
        ");
        $stmt->execute(['id' => $id]);
        return $stmt->fetch() ?: null;
    }

    /**
     * Grava o usuario na sessao com ID novo (previne session fixation)
     * e pre-carrega permissoes e vinculos multi-tenant.
     */
    private static function establishSession(object $user): void {
        $pdo = Database::getInstance();

        // Sessao nova a cada login
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_regenerate_id(true);
        }

        $pdo->prepare("UPDATE users SET last_login_at = NOW() WHERE id = :id")
            ->execute(['id' => $user->id]);

        unset($user->password);

        $_SESSION['user']        = $user;
        $_SESSION['user_id']     = $user->id;
        $_SESSION['permissions'] = Permission::forRole((int) $user->role_id);
        $_SESSION['login_at']    = time();

        if (($user->role_slug ?? '') === 'superadmin') {
            $_SESSION['tenant_id']     = null;
            $_SESSION['user_tenants']  = [];
            return;
        }

        $stmt = $pdo->prepare("
            SELECT ut.tenant_id, ut.role_id, r.slug AS role_slug, t.name, t.status
            FROM user_tenants ut
            JOIN tenants t ON t.id = ut.tenant_id
            JOIN roles r ON r.id = ut.role_id
            WHERE ut.user_id = :uid AND ut.active = 1 AND t.status = 'active'
        ");
        $stmt->execute(['uid' => $user->id]);
        $tenants = $stmt->fetchAll();

        $_SESSION['user_tenants'] = $tenants;

        if (count($tenants) === 1) {
            $_SESSION['tenant_id'] = $tenants[0]->tenant_id;
        }
    }

    public static function logout(): void {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $p = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
        }
        session_destroy();
    }

    public static function check(): bool {
        return isset($_SESSION['user_id']);
    }

    public static function user(): ?object {
        return $_SESSION['user'] ?? null;
    }

    public static function tenantId(): ?int {
        return isset($_SESSION['tenant_id']) ? (int) $_SESSION['tenant_id'] : null;
    }

    public static function isSuperAdmin(): bool {
        $user = self::user();
        return $user && ($user->role_slug ?? '') === 'superadmin';
    }

    public static function can(string $permission): bool {
        $user = self::user();
        if (!$user) return false;
        if (($user->role_slug ?? '') === 'superadmin') return true;
        return in_array($permission, $_SESSION['permissions'] ?? [], true);
    }

    /** Pode entrar no painel administrativo? */
    public static function canAccessAdmin(): bool {
        return self::can('access_admin_panel');
    }

    public static function userTenants(): array {
        return $_SESSION['user_tenants'] ?? [];
    }

    public static function setTenant(int $tenantId): void {
        $_SESSION['tenant_id'] = $tenantId;
    }

    /** Recarrega os dados do usuario na sessao (apos edicao no painel). */
    public static function refreshSession(): void {
        if (!self::check()) return;
        $user = self::findUser((int) $_SESSION['user_id']);
        if (!$user) return;
        unset($user->password);
        $_SESSION['user']        = $user;
        $_SESSION['permissions'] = Permission::forRole((int) $user->role_id);
    }
}
