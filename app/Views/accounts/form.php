<?php
$editing = !empty($account);
$value = static fn(string $key, mixed $default = '') => htmlspecialchars((string) ($account->$key ?? $default));
$codigoAtual = trim((string) ($account->bank_code ?? ''));
?>
<section class="form-intro">
    <a class="back-link" href="/contas">‹ Voltar para contas</a>
    <span class="eyebrow">Organização financeira</span>
    <h2 class="page-heading"><?= $editing ? 'Editar conta' : 'Nova conta' ?></h2>
    <p class="page-subtitle">Cadastre onde o seu dinheiro fica guardado.</p>
</section>

<form method="post" action="<?= $editing ? '/contas/' . (int) $account->id . '/atualizar' : '/contas' ?>" class="form-card">
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">

    <div class="form-grid">
        <label class="field field-wide">
            <span>Nome da conta</span>
            <input type="text" name="name" value="<?= $value('name') ?>" placeholder="Ex.: Conta principal" required maxlength="120" autofocus>
        </label>

        <div class="field bank-field">
            <span id="bank-label">Banco ou instituição <em>opcional</em></span>
            <div class="bank-picker<?= $codigoAtual !== '' ? ' has-code' : '' ?>"
                 data-bank-picker
                 data-endpoint="/api/bancos">
                <span class="bank-code-chip" data-bank-chip <?= $codigoAtual === '' ? 'hidden' : '' ?>><?= htmlspecialchars($codigoAtual) ?></span>
                <input type="text"
                       id="bank-search"
                       name="bank_name"
                       value="<?= $value('bank_name') ?>"
                       placeholder="Digite o nome ou o código (ex.: 260, Nubank)"
                       maxlength="120"
                       autocomplete="off"
                       spellcheck="false"
                       role="combobox"
                       aria-expanded="false"
                       aria-autocomplete="list"
                       aria-controls="bank-list"
                       aria-labelledby="bank-label"
                       data-bank-input>
                <input type="hidden" name="bank_code" value="<?= $value('bank_code') ?>" data-bank-code>
                <ul class="bank-list" id="bank-list" role="listbox" aria-label="Bancos brasileiros" hidden data-bank-list></ul>
            </div>
            <small class="field-hint">Lista oficial do Banco Central (código COMPE): digite o nome ou o número — 001, 260, 341…</small>
        </div>

        <label class="field">
            <span>Tipo de conta</span>
            <select name="account_type" required>
                <?php foreach (['checking' => 'Conta corrente', 'savings' => 'Conta poupança', 'investment' => 'Conta investimento', 'cash' => 'Carteira / dinheiro', 'other' => 'Outros'] as $key => $label): ?>
                    <option value="<?= $key ?>" <?= ($account->account_type ?? 'checking') === $key ? 'selected' : '' ?>><?= $label ?></option>
                <?php endforeach; ?>
            </select>
        </label>

        <?php if (!$editing): ?>
            <label class="field">
                <span>Saldo inicial</span>
                <div class="input-prefix">
                    <b>R$</b>
                    <input type="number" name="initial_balance" value="<?= $value('initial_balance', '0.00') ?>" step="0.01" min="0" required>
                </div>
            </label>

            <label class="field">
                <span>Data do saldo inicial</span>
                <input type="date" name="initial_date" value="<?= $value('initial_date', date('Y-m-d')) ?>" required>
            </label>
        <?php endif; ?>

        <label class="field">
            <span>Agência <em>opcional</em></span>
            <input type="text" name="agency" value="<?= $value('agency') ?>" maxlength="40">
        </label>

        <label class="field">
            <span>Número da conta <em>opcional</em></span>
            <input type="text" name="account_number" value="<?= $value('account_number') ?>" maxlength="80">
        </label>

        <label class="field">
            <span>Status</span>
            <select name="status">
                <option value="active" <?= ($account->status ?? 'active') === 'active' ? 'selected' : '' ?>>Ativa</option>
                <option value="inactive" <?= ($account->status ?? '') === 'inactive' ? 'selected' : '' ?>>Inativa</option>
            </select>
        </label>

        <label class="field field-wide">
            <span>Observações <em>opcional</em></span>
            <textarea name="notes" rows="4" maxlength="2000" placeholder="Detalhes úteis sobre esta conta"><?= $value('notes') ?></textarea>
        </label>
    </div>

    <div class="form-actions">
        <a href="/contas" class="button button-ghost">Cancelar</a>
        <button class="button button-primary" type="submit"><?= $editing ? 'Salvar conta' : 'Cadastrar conta' ?></button>
    </div>
</form>
