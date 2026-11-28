<?php
$editing = !empty($transaction);
$value = static fn(string $key, mixed $default = '') => htmlspecialchars((string) ($transaction->$key ?? $default));
$type = $transaction->type ?? 'expense';
$frequency = $transaction->frequency ?? 'none';
?>
<section class="form-intro"><a class="back-link" href="/lancamentos">‹ Voltar para lançamentos</a><span class="eyebrow">Movimentação financeira</span><a class="button button-ghost button-small" href="/lancamentos/importar">Lançar em lote (OFX/CSV)</a><h2 class="page-heading"><?= $editing ? 'Ajuste seu lançamento' : 'O que aconteceu?' ?></h2><p class="page-subtitle">Registre uma receita ou despesa sem perder tempo.</p></section>
<form method="post" action="<?= $editing ? '/lancamentos/' . (int) $transaction->id . '/atualizar' : '/lancamentos' ?>" class="form-card" data-transaction-form enctype="multipart/form-data">
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">
    <input type="hidden" name="document_code" value="<?= $value('document_code') ?>" data-doc-code-field>
    <?php require __DIR__ . '/_document_reader.php'; ?>
    <div class="type-switch" role="tablist" aria-label="Tipo de lançamento"><button type="button" class="type-option <?= $type === 'expense' ? 'active expense' : '' ?>" data-type="expense">Despesa</button><button type="button" class="type-option <?= $type === 'income' ? 'active income' : '' ?>" data-type="income">Receita</button><input type="hidden" name="type" value="<?= htmlspecialchars($type) ?>" data-type-input></div>
    <div class="form-grid">
        <label class="field field-wide"><span>Descrição</span><input type="text" name="description" value="<?= $value('description') ?>" placeholder="Ex.: CONTA DE LUZ" required maxlength="180" autofocus class="uppercase-input" data-uppercase><small class="field-note">Todo lançamento é salvo em MAIÚSCULAS.</small></label>
        <label class="field"><span>Valor</span><div class="input-prefix"><b>R$</b><input type="number" name="amount" value="<?= $value('amount') ?>" placeholder="0,00" step="0.01" min="0.01" required></div></label>
        <label class="field"><span>Conta</span><select name="account_id" required><option value="">Selecione</option><?php foreach ($accounts as $account): ?><option value="<?= (int) $account->id ?>" <?= ((int) ($transaction->account_id ?? 0) === (int) $account->id) ? 'selected' : '' ?>><?= htmlspecialchars($account->name) ?><?= $account->bank_name ? ' · ' . htmlspecialchars($account->bank_name) : '' ?></option><?php endforeach; ?></select><?php if (!$accounts): ?><small class="field-help">Cadastre uma conta antes de lançar.</small><?php endif; ?></label>
        <label class="field"><span>Categoria</span><select name="category_id" data-category-select><option value="">Sem categoria</option><?php foreach ($categories as $category): ?><option value="<?= (int) $category->id ?>" data-category-type="<?= htmlspecialchars($category->type) ?>" <?= ((int) ($transaction->category_id ?? 0) === (int) $category->id) ? 'selected' : '' ?>><?= htmlspecialchars($category->name) ?></option><?php endforeach; ?></select></label>
        <label class="field"><span>Centro de custo / imóvel <em>opcional</em></span><select name="cost_center_id"><?php $selected = (int) ($transaction->cost_center_id ?? 0); require __DIR__ . '/_cost_center_options.php'; ?></select></label>
        <label class="field"><span>Data do lançamento</span><input type="date" name="transaction_date" value="<?= $value('transaction_date', date('Y-m-d')) ?>" required></label>
    </div>
    <details class="advanced-options" <?= $editing ? 'open' : '' ?>><summary>Mais opções <span>Personalize vencimento, pagamento e recorrência</span></summary><div class="form-grid advanced-grid"><label class="field"><span>Vencimento</span><input type="date" name="due_date" value="<?= $value('due_date') ?>"></label><label class="field"><span>Forma de pagamento</span><select name="payment_method"><option value="">Não informado</option><?php $formas = $paymentMethods ?? []; foreach ($formas as $key => $label): ?><option value="<?= htmlspecialchars($key) ?>" <?= ($transaction->payment_method ?? '') === $key ? 'selected' : '' ?>><?= htmlspecialchars($label) ?></option><?php endforeach; ?></select><small class="field-note"><a href="/formas-pagamento">Cadastrar nova forma</a></small></label><label class="field"><span>Status</span><select name="status" data-status-select><?php $statusOptions = $type === 'income' ? ['expected'=>'Prevista','received'=>'Recebida','late'=>'Atrasada','cancelled'=>'Cancelada'] : ['pending'=>'Pendente','paid'=>'Paga','overdue'=>'Vencida','cancelled'=>'Cancelada']; foreach ($statusOptions as $key => $label): ?><option value="<?= $key ?>" <?= ($transaction->status ?? ($type === 'income' ? 'received' : 'paid')) === $key ? 'selected' : '' ?>><?= $label ?></option><?php endforeach; ?></select></label><label class="field"><span>Recorrência</span><select name="frequency" <?= $editing ? 'disabled' : '' ?>><option value="none">Não repetir</option><?php foreach (['daily'=>'Diária','weekly'=>'Semanal','biweekly'=>'Quinzenal','monthly'=>'Mensal','bimonthly'=>'Bimestral','quarterly'=>'Trimestral','semiannual'=>'Semestral','annual'=>'Anual'] as $key => $label): ?><option value="<?= $key ?>" <?= $frequency === $key ? 'selected' : '' ?>><?= $label ?></option><?php endforeach; ?></select></label><label class="field"><span>Fim da recorrência</span><input type="date" name="end_date" value="<?= $value('end_date') ?>" <?= $editing ? 'disabled' : '' ?>></label><label class="field field-wide"><span>Observação <em>opcional</em></span><textarea name="notes" rows="3" maxlength="2000" placeholder="Algum detalhe importante?" class="uppercase-input" data-uppercase><?= $value('notes') ?></textarea></label></div></details>
    <?php require __DIR__ . '/_attachment_field.php'; ?>
    <div class="form-actions"><a href="/lancamentos" class="button button-ghost">Cancelar</a><button class="button button-primary" type="submit"><?= $editing ? 'Salvar alterações' : 'Salvar lançamento' ?></button></div>
</form>
<script>
(function () {
    document.querySelectorAll('[data-uppercase]').forEach(function (field) {
        field.addEventListener('input', function () {
            var inicio = field.selectionStart;
            var fim = field.selectionEnd;
            field.value = field.value.toUpperCase();
            try { field.setSelectionRange(inicio, fim); } catch (error) { /* textarea sem seleção */ }
        });
    });
})();
</script>
