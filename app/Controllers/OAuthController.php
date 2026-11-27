<?php
namespace App\Controllers;

use App\Core\Audit\AuditLogger;
use App\Core\Auth;
use App\Core\Controller;
use App\Core\Database;
use App\Core\Flash;
use App\Core\Logger;
use App\Services\AuthAttemptService;
use App\Services\OAuthException;
use App\Services\OAuthService;

class OAuthController extends Controller
{
    /** /auth/{provider} — inicia o fluxo */
    public function start(string $provider): void
    {
        if (!OAuthService::isValidProvider($provider)) {
            $this->redirect('/login?erro=oauth_credenciais');
        }

        if (!OAuthService::isAvailable($provider)) {
            Logger::warning('Login social ainda nao configurado', [
                'provider' => $provider,
                'dica'     => 'Preencha CLIENT_ID/CLIENT_SECRET no .env (docs/OAUTH_SETUP.md)',
            ]);
            $this->redirect('/login?erro=oauth_nao_configurado&provider=' . urlencode($provider));
        }

        try {
            header('Location: ' . OAuthService::authorizeUrl($provider));
            exit;
        } catch (OAuthException $e) {
            Logger::warning('Falha ao iniciar OAuth', ['provider' => $provider, 'motivo' => $e->motivo()]);
            $this->redirect('/login?erro=' . urlencode($e->motivo()));
        }
    }

    /** /auth/{provider}/callback — retorno do provedor */
    public function callback(string $provider): void
    {
        if (!OAuthService::isValidProvider($provider)) {
            $this->redirect('/login?erro=oauth_credenciais');
        }

        // Banco sem a migration 0004: mensagem clara em vez de 500
        if (!\App\Core\Schema::accessReady()) {
            Logger::error('Callback OAuth bloqueado: schema de acesso incompleto', [
                'faltando' => \App\Core\Schema::missingAccess(),
            ]);
            $this->redirect('/login?erro=banco_desatualizado');
        }

        // Usuario cancelou na tela do provedor
        if (!empty($_GET['error'])) {
            AuthAttemptService::record(AuthAttemptService::ACTION_OAUTH, false);
            AuditLogger::log('oauth_cancel', 'user', null, ['provider' => $provider, 'error' => (string) $_GET['error']]);
            $this->redirect('/login?erro=oauth_cancelado');
        }

        $code  = (string) ($_GET['code'] ?? '');
        $state = (string) ($_GET['state'] ?? '');

        try {
            $perfil = OAuthService::handleCallback($provider, $code, $state);
        } catch (OAuthException $e) {
            AuthAttemptService::record(AuthAttemptService::ACTION_OAUTH, false);
            AuditLogger::log('oauth_fail', 'user', null, ['provider' => $provider, 'motivo' => $e->motivo()]);
            Logger::warning('Falha no callback OAuth', ['provider' => $provider, 'motivo' => $e->motivo()]);
            $this->redirect('/login?erro=' . urlencode($e->motivo()));
            return;
        }

        $pdo = Database::getInstance();

        try {
            // 1) identidade ja vinculada
            $stmt = $pdo->prepare("
                SELECT u.id, u.status
                FROM user_identities i
                JOIN users u ON u.id = i.user_id
                WHERE i.provider = :provider AND i.provider_user_id = :sub
                LIMIT 1
            ");
            $stmt->execute(['provider' => $perfil['provider'], 'sub' => $perfil['sub']]);
            $vinculo = $stmt->fetch();

            if ($vinculo) {
                $userId = (int) $vinculo->id;
                $status = (string) $vinculo->status;
                $novo   = false;
                $pdo->prepare("UPDATE user_identities SET last_login_at = NOW(), email = :email WHERE provider = :provider AND provider_user_id = :sub")
                    ->execute(['email' => $perfil['email'], 'provider' => $perfil['provider'], 'sub' => $perfil['sub']]);
            } else {
                // 2) usuario existente com o mesmo e-mail => vincula
                $stmt = $pdo->prepare("SELECT id, status FROM users WHERE email = :email LIMIT 1");
                $stmt->execute(['email' => $perfil['email']]);
                $existente = $stmt->fetch();

                if ($existente) {
                    $userId = (int) $existente->id;
                    $status = (string) $existente->status;
                    $novo   = false;
                } else {
                    // 3) cria usuario novo (senha inutilizavel, sem envio de e-mail)
                    $roleId = $this->roleId('user');
                    $stmt = $pdo->prepare("
                        INSERT INTO users (name, email, password, role_id, status, auth_provider, avatar_url,
                                           email_verified_at, registration_ip, created_at, updated_at)
                        VALUES (:name, :email, :password, :role_id, 'active', :provider, :avatar,
                                NOW(), :ip, NOW(), NOW())
                    ");
                    $stmt->execute([
                        'name'     => mb_substr($perfil['name'] !== '' ? $perfil['name'] : 'Usuário SOMASE', 0, 120),
                        'email'    => $perfil['email'],
                        'password' => password_hash(bin2hex(random_bytes(32)), PASSWORD_DEFAULT),
                        'role_id'  => $roleId,
                        'provider' => $perfil['provider'],
                        'avatar'   => $perfil['avatar'] ? mb_substr($perfil['avatar'], 0, 255) : null,
                        'ip'       => AuthAttemptService::ip(),
                    ]);
                    $userId = (int) $pdo->lastInsertId();
                    $status = 'active';
                    $novo   = true;
                }

                $this->linkIdentity($userId, $perfil);
            }

            if ($status !== 'active') {
                AuthAttemptService::record(AuthAttemptService::ACTION_OAUTH, false, $perfil['email']);
                $this->redirect('/login?erro=conta_desativada');
                return;
            }

            $user = Auth::findUser($userId);
            if (!$user) {
                $this->redirect('/login?erro=oauth_credenciais');
                return;
            }

            Auth::loginUser($user);
            AuthAttemptService::record(AuthAttemptService::ACTION_OAUTH, true, $perfil['email']);
            AuditLogger::log($novo ? 'oauth_register' : 'oauth_login', 'user', $userId, [
                'provider' => $perfil['provider'],
            ]);

            if (empty($user->birth_date) || empty($user->terms_accepted_at)) {
                Flash::info('Falta pouco: confirme sua data de nascimento e aceite os termos para liberar o sistema.');
                $this->redirect('/cadastro/completar');
                return;
            }

            $this->redirect(Auth::canAccessAdmin() ? '/admin' : '/dashboard');
        } catch (\Throwable $e) {
            Logger::error('Erro ao concluir login OAuth', ['message' => $e->getMessage()]);
            $this->redirect('/login?erro=oauth_credenciais');
        }
    }

    private function linkIdentity(int $userId, array $perfil): void
    {
        $stmt = Database::getInstance()->prepare("
            INSERT INTO user_identities (user_id, provider, provider_user_id, email, last_login_at, created_at)
            VALUES (:user_id, :provider, :sub, :email, NOW(), NOW())
            ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), email = VALUES(email), last_login_at = NOW()
        ");
        $stmt->execute([
            'user_id'  => $userId,
            'provider' => $perfil['provider'],
            'sub'      => $perfil['sub'],
            'email'    => $perfil['email'],
        ]);
    }

    private function roleId(string $slug): int
    {
        $stmt = Database::getInstance()->prepare("SELECT id FROM roles WHERE slug = :slug LIMIT 1");
        $stmt->execute(['slug' => $slug]);
        $id = $stmt->fetchColumn();
        return $id ? (int) $id : 3;
    }
}
