<?php $csrf = $_SESSION['csrf_token'] ?? ''; ?>
<div class="auth-welcome">
    <h1>Entrar</h1>
    <p>Acesse sua conta para continuar</p>
</div>
<?php if (!empty($error)): ?><div class="auth-alert" role="alert"><span aria-hidden="true">!</span><span><?= htmlspecialchars($error) ?></span></div><?php endif; ?>
<?php if (($_GET['error'] ?? '') === 'sessao_expirada'): ?><div class="auth-alert warning" role="alert"><span aria-hidden="true">⏱</span><span>Sua sessão expirou. Faça login novamente.</span></div><?php endif; ?>
<form method="POST" action="/login" class="auth-form" data-login-form>
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">
    <label class="field">
        <span>E-mail</span>
        <span class="auth-field">
            <span class="field-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M3.5 7.5 12 13l8.5-5.5"/></svg></span>
            <input type="email" name="email" id="login-email" placeholder="voce@exemplo.com" autocomplete="email" inputmode="email" required autofocus>
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
        <label class="auth-check"><input type="checkbox" name="remember_email" value="1" data-remember-email> Lembrar e-mail</label>
        <a class="text-link" href="/login">Limpar</a>
    </div>
    <button type="submit" class="button button-primary" data-submit-label="Entrar">Entrar</button>
</form>
<p class="auth-footnote">Acesso protegido por sessão segura, CSRF e controle de permissões.</p>
