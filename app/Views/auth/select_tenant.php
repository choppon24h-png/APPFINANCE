<?php $csrf = $_SESSION['csrf_token'] ?? ''; ?>
<div class="auth-welcome">
    <span class="eyebrow">SOMASE</span>
    <h1>Selecione a empresa</h1>
    <p>Escolha com qual organização você quer trabalhar agora.</p>
</div>
<form method="POST" action="/selecionar-empresa">
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">
    <div class="tenant-list" role="radiogroup" aria-label="Empresas disponíveis">
        <?php foreach ($tenants as $t): ?>
            <label class="tenant-option">
                <input type="radio" name="tenant_id" value="<?= (int) $t->tenant_id ?>" required>
                <span><?= htmlspecialchars($t->name) ?></span>
            </label>
        <?php endforeach; ?>
    </div>
    <button type="submit" class="button button-primary">Continuar</button>
</form>
