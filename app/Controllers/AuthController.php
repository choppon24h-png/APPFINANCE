<?php
namespace App\Controllers;

use App\Core\Audit\AuditLogger;
use App\Core\Auth;
use App\Core\Controller;
use App\Core\Flash;
use App\Services\AuthAttemptService;
use App\Services\OAuthService;

class AuthController extends Controller {

    public function showLogin(): void {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }

        if (Auth::check()) {
            $this->redirect(Auth::canAccessAdmin() ? '/admin' : '/dashboard');
        }

        $this->view('auth/login', [
            'title'            => 'Entrar',
            'error'            => $this->mensagemErro(),
            'providers'        => OAuthService::availableProviders(),
            'registrationOpen' => $this->registrationOpen(),
            'csrf'             => $this->csrfToken(),
        ], 'auth');
    }

    public function login(): void {
        $email    = mb_strtolower(trim((string) ($_POST['email'] ?? '')));
        $password = (string) ($_POST['password'] ?? '');

        $render = function (string $erro, array $extra = []) use ($email) {
            $this->view('auth/login', array_merge([
                'title'            => 'Entrar',
                'error'            => $erro,
                'email'            => $email,
                'providers'        => OAuthService::availableProviders(),
                'registrationOpen' => $this->registrationOpen(),
                'csrf'             => $this->csrfToken(),
            ], $extra), 'auth');
        };

        if ($email === '' || $password === '') {
            $render('Informe e-mail e senha para entrar.');
            return;
        }

        // Rate-limit por IP + e-mail
        $bloqueio = AuthAttemptService::loginLockMinutes($email);
        if ($bloqueio > 0) {
            AuthAttemptService::record(AuthAttemptService::ACTION_LOGIN, false, $email);
            $render('Muitas tentativas. Tente novamente em ' . $bloqueio . ' minutos.');
            return;
        }

        $resultado = Auth::login($email, $password);

        if ($resultado !== 'ok') {
            AuthAttemptService::record(AuthAttemptService::ACTION_LOGIN, false, $email);

            if ($resultado === 'inactive') {
                $render('Sua conta está desativada. Fale com o administrador.');
                return;
            }

            // Mensagem generica: nao revela se o e-mail existe
            $render('E-mail ou senha incorretos.');
            return;
        }

        AuthAttemptService::record(AuthAttemptService::ACTION_LOGIN, true, $email);
        AuditLogger::log('login', 'user', (int) Auth::user()->id, ['provider' => 'local']);

        // Perfil incompleto (usuarios criados por OAuth) vai direto completar
        // (com banco desatualizado, deixa o painel explicar o que falta)
        if ($this->perfilIncompleto() && \App\Core\Schema::accessReady() && !Auth::canAccessAdmin()) {
            $this->redirect('/cadastro/completar');
        }

        if (count(Auth::userTenants()) > 1) {
            $this->redirect('/selecionar-empresa');
        }

        $this->redirect(Auth::canAccessAdmin() ? '/admin' : '/dashboard');
    }

    public function logout(): void {
        if (Auth::check()) {
            AuditLogger::log('logout', 'user', (int) Auth::user()->id);
        }
        Auth::logout();
        $this->redirect('/login');
    }

    public function selectTenant(): void {
        if (!Auth::check()) {
            $this->redirect('/login');
        }

        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }

        $tenants = Auth::userTenants();

        if (empty($tenants)) {
            $this->redirect('/dashboard');
        }

        $this->view('auth/select_tenant', [
            'title'   => 'Selecionar organizacao',
            'tenants' => $tenants,
        ], 'auth');
    }

    public function setTenant(): void {
        if (!Auth::check()) {
            $this->redirect('/login');
        }

        $tenantId = (int) ($_POST['tenant_id'] ?? 0);
        $allowed  = array_column(Auth::userTenants(), 'tenant_id');

        if (!$tenantId || !in_array($tenantId, $allowed)) {
            $this->redirect('/selecionar-empresa');
        }

        Auth::setTenant($tenantId);
        $this->redirect('/dashboard');
    }

    /* ------------------------------------------------------------------ */

    private function registrationOpen(): bool {
        return ($_ENV['REGISTRATION_ENABLED'] ?? 'true') !== 'false';
    }

    private function perfilIncompleto(): bool {
        $user = Auth::user();
        return $user && (empty($user->birth_date) || empty($user->terms_accepted_at));
    }

    private function mensagemErro(): ?string {
        $erro = $_GET['erro'] ?? '';

        $mapa = [
            'oauth_cancelado'   => 'O login social foi cancelado. Tente novamente ou use e-mail e senha.',
            'oauth_credenciais' => 'Não foi possível concluir o login social. Tente novamente.',
            'oauth_email'       => 'O provedor não retornou um e-mail verificado. Use e-mail e senha.',
            'oauth_state'       => 'Sessão de login social expirada. Tente novamente.',
            'sessao_expirada'   => 'Sua sessão expirou. Faça login novamente.',
            'conta_desativada'  => 'Sua conta está desativada. Fale com o administrador.',
            'acesso_restrito'   => 'Faça login para continuar.',
            'banco_desatualizado' => 'O banco de dados precisa ser atualizado antes de usar o login social. Fale com o administrador.',
        ];

        if ($erro === 'oauth_nao_configurado') {
            $provedor = (string) ($_GET['provider'] ?? 'social');
            $nome     = $provedor === 'google' ? 'Google' : ($provedor === 'microsoft' ? 'Microsoft' : 'social');
            return 'O login com ' . $nome . ' ainda não está ativado neste servidor. Use e-mail e senha ou fale com o administrador.';
        }

        return $mapa[$erro] ?? null;
    }
}
