<?php
$csrf     = $csrf ?? ($_SESSION['csrf_token'] ?? '');
$errors   = $errors ?? [];
$old      = $old ?? ['birth_date' => ''];
$minAge   = $minAge ?? 18;
$provider = $user->auth_provider ?? 'local';
$rotulo   = ['google' => 'Google', 'microsoft' => 'Microsoft'][$provider] ?? 'e-mail';
?>
<div class="auth-welcome">
    <h1>Falta pouco</h1>
    <p>Confirme dois dados para liberar o SOMASE</p>
</div>

<div class="auth-provider">
    <?php if (!empty($user->avatar_url)): ?>
        <img src="<?= htmlspecialchars($user->avatar_url) ?>" alt="" width="40" height="40" referrerpolicy="no-referrer">
    <?php else: ?>
        <span class="avatar"><?= htmlspecialchars(mb_strtoupper(mb_substr($user->name ?? 'U', 0, 1))) ?></span>
    <?php endif; ?>
    <div>
        <strong><?= htmlspecialchars($user->name ?? '') ?></strong>
        <small><?= htmlspecialchars($user->email ?? '') ?> · conta <?= htmlspecialchars($rotulo) ?></small>
    </div>
</div>

<?php if (!empty($errors['form'])): ?>
    <div class="auth-alert" role="alert"><span aria-hidden="true">!</span><span><?= htmlspecialchars($errors['form']) ?></span></div>
<?php endif; ?>

<form method="POST" action="/cadastro/completar" class="auth-form">
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">

    <label class="field<?= isset($errors['birth_date']) ? ' has-error' : '' ?>">
        <span>Data de nascimento <em>(dd/mm/aaaa)</em></span>
        <input type="date" name="birth_date" required min="1900-01-01" value="<?= htmlspecialchars($old['birth_date'] ?? '') ?>">
        <small class="<?= isset($errors['birth_date']) ? 'field-error' : 'field-hint' ?>"><?= $errors['birth_date'] ?? 'É necessário ter pelo menos ' . (int) $minAge . ' anos.' ?></small>
    </label>

    <label class="auth-check auth-terms<?= isset($errors['terms']) ? ' has-error' : '' ?>">
        <input type="checkbox" name="terms" value="1" required>
        <span>Li e aceito os <a href="/termos" target="_blank" rel="noopener">Termos de Uso</a> e a <a href="/privacidade" target="_blank" rel="noopener">Política de Privacidade</a>.</span>
    </label>
    <?php if (isset($errors['terms'])): ?><small class="field-error terms-error"><?= htmlspecialchars($errors['terms']) ?></small><?php endif; ?>

    <button type="submit" class="button button-primary" data-submit-label="Concluir cadastro">Concluir cadastro</button>
</form>

<p class="auth-switch"><a href="/logout">Sair desta conta</a></p>
