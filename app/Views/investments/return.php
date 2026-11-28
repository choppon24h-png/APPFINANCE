<?php
$money = static fn($value) => 'R$ ' . number_format((float) $value, 2, ',', '.');
$estimativa = $estimativa ?? ['monthly_amount' => 0, 'principal' => (float) $investment->amount_invested, 'method' => '—', 'available' => false];
$sugerido = !empty($usarEstimativa) && $estimativa['monthly_amount'] > 0;
$valorInicial = $estimativa['principal'] > 0 ? $estimativa['principal'] : (float) $investment->amount_invested;
$meses = [1=>'Janeiro','2'=>'Fevereiro','3'=>'Março','4'=>'Abril','5'=>'Maio','6'=>'Junho','7'=>'Julho','8'=>'Agosto','9'=>'Setembro','10'=>'Outubro','11'=>'Novembro','12'=>'Dezembro'];
?>
<section class="form-intro">
    <a class="back-link" href="/investimentos">‹ Voltar para investimentos</a>
    <span class="eyebrow"><?= htmlspecialchars($investment->institution) ?> · <?= htmlspecialchars($investment->name) ?></span>
    <h2 class="page-heading">Registrar rendimento</h2>
    <p class="page-subtitle">Informe o rendimento apurado no mês. O cálculo percentual é feito automaticamente.</p>
</section>

<?php if ($estimativa['available'] && $estimativa['monthly_amount'] > 0): ?>
    <div class="estimate-callout">
        <div>
            <span class="eyebrow">Estimativa pela taxa contratada</span>
            <strong><?= $money($estimativa['monthly_amount']) ?> no mês</strong>
            <small><?= htmlspecialchars($estimativa['method']) ?> · patrimônio de <?= $money($estimativa['principal']) ?></small>
        </div>
        <button class="button button-ghost button-small" type="button" data-use-estimate>Usar estimativa</button>
    </div>
<?php endif; ?>

<form method="post" action="/investimentos/<?= (int) $investment->id ?>/rendimento" class="form-card compact-form" data-return-form>
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">
    <div class="return-summary">
        <div><span>Valor aplicado</span><strong><?= $money($investment->amount_invested) ?></strong></div>
        <div><span>Patrimônio atual</span><strong><?= $money($estimativa['principal']) ?></strong></div>
        <div><span>Conta</span><strong><?= htmlspecialchars($investment->account_name) ?></strong></div>
    </div>
    <div class="form-grid">
        <label class="field"><span>Mês de referência</span>
            <select name="reference_month">
                <?php foreach ($meses as $numero => $nome): ?><option value="<?= $numero ?>" <?= $numero === (int) date('n') ? 'selected' : '' ?>><?= $nome ?></option><?php endforeach; ?>
            </select>
        </label>
        <label class="field"><span>Ano de referência</span><input type="number" name="reference_year" min="2000" max="2200" value="<?= date('Y') ?>" required></label>
        <label class="field"><span>Valor inicial no período</span>
            <div class="input-prefix"><b>R$</b><input type="number" name="initial_value" step="0.01" min="0.01" value="<?= number_format($valorInicial, 2, '.', '') ?>" required></div>
        </label>
        <label class="field"><span>Rendimento do período</span>
            <div class="input-prefix"><b>R$</b><input type="number" name="return_amount" step="0.01" min="0.01" placeholder="0,00" value="<?= $sugerido ? number_format($estimativa['monthly_amount'], 2, '.', '') : '' ?>" required autofocus data-return-amount></div>
            <small class="field-note"><?= $sugerido ? 'Valor preenchido com a estimativa — confira antes de salvar.' : 'Use o valor real informado pela instituição.' ?></small>
        </label>
    </div>
    <div class="info-note">A rentabilidade será calculada como rendimento ÷ valor inicial × 100. Esse lançamento atualiza os indicadores, mas não movimenta a conta corrente.</div>
    <div class="form-actions">
        <a href="/investimentos" class="button button-ghost">Cancelar</a>
        <button class="button button-primary" type="submit">Registrar rendimento</button>
    </div>
</form>

<script>
(function () {
    var botao = document.querySelector('[data-use-estimate]');
    var campo = document.querySelector('[data-return-amount]');
    if (!botao || !campo) return;
    botao.addEventListener('click', function () {
        campo.value = <?= json_encode(number_format((float) $estimativa['monthly_amount'], 2, '.', '')) ?>;
        campo.focus();
    });
})();
</script>
