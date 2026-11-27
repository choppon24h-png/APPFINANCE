<?php
$csrf      = $csrf ?? ($_SESSION['csrf_token'] ?? '');
$providers = $providers ?? [];
$email     = $email ?? '';
$erro      = $error ?? null;
$info      = $_GET['info'] ?? '';
?>
<div class="auth-welcome">
    <h1>Entrar</h1>
    <p>Acesse sua conta para continuar</p>
</div>

<?php if (!empty($erro)): ?>
    <div class="auth-alert" role="alert"><span aria-hidden="true">!</span><span><?= htmlspecialchars($erro) ?></span></div>
<?php endif; ?>

<?php if ($info === 'senha'): ?>
    <div class="auth-alert info" role="status"><span aria-hidden="true">i</span><span>Fale com o administrador para redefinir sua senha.</span></div>
<?php endif; ?>

<form method="POST" action="/login" class="auth-form" data-login-form>
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">

    <label class="field">
        <span>E-mail</span>
        <span class="auth-field">
            <span class="field-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M3.5 7.5 12 13l8.5-5.5"/></svg></span>
            <input type="email" name="email" id="login-email" placeholder="voce@exemplo.com" autocomplete="email" inputmode="email" required autofocus value="<?= htmlspecialchars($email) ?>">
        </span>
    </label>

    <label class="field">
        <span>Senha</span>
        <span class="auth-field">
            <span class="field-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><rect x="4" y="10.5" width="16" height="10" rx="2.5"/><path d="M8 10.5V7.8a4 4 0 0 1 8 0v2.7"/></svg></span>
            <input type="password" name="password" id="login-password" placeholder="Sua senha" autocomplete="current-password" required>
            <button type="button" class="field-toggle" data-toggle-password aria-controls="login-password" aria-pressed="false">mostrar</button>
        </span>
    </label>

    <div class="auth-row">
        <label class="auth-check"><input type="checkbox" name="remember_email" value="1" data-remember-email> Lembrar meu e-mail</label>
        <a class="text-link" href="/login?info=senha">Esqueci minha senha</a>
    </div>

    <button type="submit" class="button button-primary" data-submit-label="Entrar">Entrar</button>
</form>

<?php if (!empty($providers)): ?>
    <div class="auth-divider"><span>ou</span></div>
    <div class="oauth-buttons">
        <?php if (isset($providers['google'])): ?>
            <a class="button oauth-button" href="/auth/google" data-oauth="google">
                <svg viewBox="0 0 24 24" aria-hidden="true" width="18" height="18">
                    <path fill="#4285F4" d="M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.5a5.6 5.6 0 0 1-2.4 3.7v3h3.9c2.3-2.1 3.5-5.2 3.5-8.9z"/>
                    <path fill="#34A853" d="M12 24c3.2 0 5.9-1.1 7.9-2.9l-3.9-3a7.2 7.2 0 0 1-10.7-3.8H1.3v3.1A12 12 0 0 0 12 24z"/>
                    <path fill="#FBBC05" d="M5.3 14.3a7.2 7.2 0 0 1 0-4.6V6.6H1.3a12 12 0 0 0 0 10.8l4-3.1z"/>
                    <path fill="#EA4335" d="M12 4.8c1.8 0 3.4.6 4.6 1.8l3.4-3.4A12 12 0 0 0 1.3 6.6l4 3.1A7.2 7.2 0 0 1 12 4.8z"/>
                </svg>
                Continuar com Google
            </a>
        <?php endif; ?>
        <?php if (isset($providers['microsoft'])): ?>
            <a class="button oauth-button" href="/auth/microsoft" data-oauth="microsoft">
                <svg viewBox="0 0 24 24" aria-hidden="true" width="18" height="18">
                    <rect x="2" y="2" width="9" height="9" fill="#F25022"/>
                    <rect x="13" y="2" width="9" height="9" fill="#7FBA00"/>
                    <rect x="2" y="13" width="9" height="9" fill="#00A4EF"/>
                    <rect x="13" y="13" width="9" height="9" fill="#FFB900"/>
                </svg>
                Continuar com Microsoft
            </a>
        <?php endif; ?>
    </div>
<?php endif; ?>

<?php if (!empty($registrationOpen)): ?>
    <p class="auth-switch">Não tem conta? <a href="/cadastro">Criar conta</a></p>
<?php endif; ?>

<p class="auth-footnote">Acesso protegido por sessão segura, CSRF e controle de permissões.</p>
