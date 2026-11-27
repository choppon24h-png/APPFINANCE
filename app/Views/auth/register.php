<?php
$csrf      = $csrf ?? ($_SESSION['csrf_token'] ?? '');
$providers = $providers ?? [];
$old       = $old ?? [];
$errors    = $errors ?? [];
$minAge    = $minAge ?? 18;
$val       = static fn(string $campo) => htmlspecialchars((string) ($old[$campo] ?? ''));
$temErro   = static fn(string $campo) => isset($errors[$campo]) ? ' has-error' : '';
$descreve  = static fn(string $campo) => isset($errors[$campo]) ? 'field-error' : 'field-hint';
?>
<div class="auth-welcome">
    <h1>Criar conta</h1>
    <p>Leva menos de um minuto para começar</p>
</div>

<?php if (!empty($errors['form'])): ?>
    <div class="auth-alert" role="alert"><span aria-hidden="true">!</span><span><?= htmlspecialchars($errors['form']) ?></span></div>
<?php endif; ?>

<?php if (!empty($providers)): ?>
    <div class="oauth-buttons oauth-buttons-top">
        <?php if (isset($providers['google'])): ?>
            <a class="button oauth-button" href="/auth/google">
                <svg viewBox="0 0 24 24" aria-hidden="true" width="18" height="18">
                    <path fill="#4285F4" d="M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.5a5.6 5.6 0 0 1-2.4 3.7v3h3.9c2.3-2.1 3.5-5.2 3.5-8.9z"/>
                    <path fill="#34A853" d="M12 24c3.2 0 5.9-1.1 7.9-2.9l-3.9-3a7.2 7.2 0 0 1-10.7-3.8H1.3v3.1A12 12 0 0 0 12 24z"/>
                    <path fill="#FBBC05" d="M5.3 14.3a7.2 7.2 0 0 1 0-4.6V6.6H1.3a12 12 0 0 0 0 10.8l4-3.1z"/>
                    <path fill="#EA4335" d="M12 4.8c1.8 0 3.4.6 4.6 1.8l3.4-3.4A12 12 0 0 0 1.3 6.6l4 3.1A7.2 7.2 0 0 1 12 4.8z"/>
                </svg>
                Cadastrar com Google
            </a>
        <?php endif; ?>
        <?php if (isset($providers['microsoft'])): ?>
            <a class="button oauth-button" href="/auth/microsoft">
                <svg viewBox="0 0 24 24" aria-hidden="true" width="18" height="18">
                    <rect x="2" y="2" width="9" height="9" fill="#F25022"/>
                    <rect x="13" y="2" width="9" height="9" fill="#7FBA00"/>
                    <rect x="2" y="13" width="9" height="9" fill="#00A4EF"/>
                    <rect x="13" y="13" width="9" height="9" fill="#FFB900"/>
                </svg>
                Cadastrar com Microsoft
            </a>
        <?php endif; ?>
    </div>
    <div class="auth-divider"><span>ou preencha seus dados</span></div>
<?php endif; ?>

<form method="POST" action="/cadastro" class="auth-form auth-form-wide" data-register-form novalidate>
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">
    <div class="hp-field" aria-hidden="true">
        <label>Não preencha este campo<input type="text" name="website" tabindex="-1" autocomplete="off"></label>
    </div>

    <label class="field<?= $temErro('name') ?>">
        <span>Nome completo</span>
        <input type="text" name="name" id="reg-name" placeholder="Maria Silva" autocomplete="name" required minlength="3" maxlength="120" value="<?= $val('name') ?>" data-validate="name">
        <small class="<?= $descreve('name') ?>"><?= $errors['name'] ?? 'Como você quer ser chamado(a) no sistema.' ?></small>
    </label>

    <label class="field<?= $temErro('email') ?>">
        <span>E-mail</span>
        <input type="email" name="email" id="reg-email" placeholder="voce@exemplo.com" autocomplete="email" inputmode="email" required maxlength="255" value="<?= $val('email') ?>" data-validate="email">
        <small class="<?= $descreve('email') ?>"><?= $errors['email'] ?? 'Usaremos apenas para identificar sua conta.' ?></small>
    </label>

    <label class="field<?= $temErro('birth_date') ?>">
        <span>Data de nascimento <em>(dd/mm/aaaa)</em></span>
        <input type="date" name="birth_date" id="reg-birth" required min="1900-01-01" value="<?= $val('birth_date') ?>" data-validate="birth">
        <small class="<?= $descreve('birth_date') ?>"><?= $errors['birth_date'] ?? 'É necessário ter pelo menos ' . (int) $minAge . ' anos.' ?></small>
    </label>

    <label class="field<?= $temErro('password') ?>">
        <span>Senha</span>
        <span class="auth-field">
            <span class="field-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><rect x="4" y="10.5" width="16" height="10" rx="2.5"/><path d="M8 10.5V7.8a4 4 0 0 1 8 0v2.7"/></svg></span>
            <input type="password" name="password" id="reg-password" placeholder="Mínimo de 8 caracteres" autocomplete="new-password" required minlength="8" data-validate="password">
            <button type="button" class="field-toggle" data-toggle-password aria-controls="reg-password" aria-pressed="false">mostrar</button>
        </span>
        <span class="strength" data-strength hidden>
            <span class="strength-bars"><i></i><i></i><i></i><i></i></span>
            <span class="strength-label">Força da senha</span>
        </span>
        <small class="<?= $descreve('password') ?>"><?= $errors['password'] ?? 'Use maiúscula, minúscula, número e símbolo.' ?></small>
    </label>

    <label class="field<?= $temErro('password_confirm') ?>">
        <span>Confirmar senha</span>
        <span class="auth-field">
            <span class="field-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><rect x="4" y="10.5" width="16" height="10" rx="2.5"/><path d="M8 10.5V7.8a4 4 0 0 1 8 0v2.7"/></svg></span>
            <input type="password" name="password_confirm" id="reg-password-confirm" placeholder="Repita a senha" autocomplete="new-password" required data-validate="confirm">
        </span>
        <small class="<?= $descreve('password_confirm') ?>"><?= $errors['password_confirm'] ?? '' ?></small>
    </label>

    <label class="auth-check auth-terms<?= isset($errors['terms']) ? ' has-error' : '' ?>">
        <input type="checkbox" name="terms" value="1" required>
        <span>Li e aceito os <a href="/termos" target="_blank" rel="noopener">Termos de Uso</a> e a <a href="/privacidade" target="_blank" rel="noopener">Política de Privacidade</a>.</span>
    </label>
    <?php if (isset($errors['terms'])): ?><small class="field-error terms-error"><?= htmlspecialchars($errors['terms']) ?></small><?php endif; ?>

    <button type="submit" class="button button-primary" data-submit-label="Criar conta">Criar conta</button>
</form>

<p class="auth-switch">Já tem conta? <a href="/login">Entrar</a></p>
<p class="auth-footnote">Seus dados financeiros ficam isolados na sua conta. Não enviamos senhas por e-mail.</p>
