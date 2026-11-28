<?php
$editing = !empty($investment);
$valor = static fn(string $key, mixed $default = '') => htmlspecialchars((string) ($investment->$key ?? $default));
$tipoAtual = (int) ($investment->investment_type_id ?? 0);
?>
<section class="form-intro">
    <a class="back-link" href="/investimentos">‹ Voltar para investimentos</a>
    <span class="eyebrow">Construção de patrimônio</span>
    <h2 class="page-heading"><?= $editing ? 'Ajustar investimento' : 'Nova aplicação' ?></h2>
    <p class="page-subtitle">Informe a taxa contratada e o sistema estima a receita de cada mês. Você confirma o rendimento quando quiser.</p>
</section>

<form method="post" action="<?= $editing ? '/investimentos/' . (int) $investment->id . '/atualizar' : '/investimentos' ?>" class="form-card" data-investment-form>
    <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">
    <div class="form-grid">
        <label class="field field-wide"><span>Nome da aplicação</span><input type="text" name="name" value="<?= $valor('name') ?>" placeholder="Ex.: CDB Liquidez diária" maxlength="150" required autofocus></label>
        <label class="field"><span>Instituição financeira</span><input type="text" name="institution" value="<?= $valor('institution') ?>" placeholder="Ex.: Banco X" maxlength="120" required></label>
        <label class="field"><span>Conta de origem</span>
            <select name="account_id" required>
                <option value="">Selecione</option>
                <?php foreach ($accounts as $account): ?>
                    <option value="<?= (int) $account->id ?>" <?= ((int) ($investment->account_id ?? 0) === (int) $account->id) ? 'selected' : '' ?>><?= htmlspecialchars($account->name) ?> · R$ <?= number_format((float) $account->current_balance, 2, ',', '.') ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label class="field"><span>Tipo de investimento</span>
            <select name="investment_type_id" data-type-select>
                <option value="">Outros (texto livre)</option>
                <?php foreach ($investmentTypes as $type): ?>
                    <option value="<?= (int) $type->id ?>"
                            data-benchmark="<?= htmlspecialchars($type->benchmark) ?>"
                            data-rate="<?= $type->default_rate !== null ? htmlspecialchars((string) $type->default_rate) : '' ?>"
                            data-period="<?= htmlspecialchars($type->default_rate_period) ?>"
                            <?= $tipoAtual === (int) $type->id ? 'selected' : '' ?>><?= htmlspecialchars($type->name) ?></option>
                <?php endforeach; ?>
            </select>
            <small class="field-note"><a href="/investimentos/tipos">Gerenciar tipos</a> (CDB, LCI, Tesouro, CDI…).</small>
        </label>
        <label class="field"><span>Valor aplicado</span>
            <div class="input-prefix"><b>R$</b><input type="number" name="amount_invested" value="<?= $valor('amount_invested') ?>" step="0.01" min="0.01" placeholder="0,00" required <?= $editing ? 'readonly' : '' ?> data-principal></div>
            <?php if ($editing): ?><small class="field-note">Para mudar o valor aplicado, registre um novo aporte.</small><?php endif; ?>
        </label>
        <label class="field"><span>Data da aplicação</span><input type="date" name="application_date" value="<?= $valor('application_date', date('Y-m-d')) ?>" required <?= $editing ? 'readonly' : '' ?>></label>

        <label class="field"><span>Taxa contratada <em>opcional</em></span>
            <div class="input-suffix"><input type="number" name="interest_rate" value="<?= $valor('interest_rate') ?>" step="0.000001" min="0" placeholder="Ex.: 110" data-contract-rate><b>%</b></div>
            <small class="field-note">CDB de 110% do CDI → 110. Prefixado de 12% a.a. → 12.</small>
        </label>
        <label class="field"><span>Periodicidade da taxa</span>
            <select name="rate_period" data-rate-period>
                <option value="annual" <?= ($investment->rate_period ?? 'annual') === 'annual' ? 'selected' : '' ?>>Ao ano</option>
                <option value="monthly" <?= ($investment->rate_period ?? '') === 'monthly' ? 'selected' : '' ?>>Ao mês</option>
            </select>
        </label>
        <label class="field"><span>Taxa de referência <em>opcional</em></span>
            <div class="input-suffix"><input type="number" name="benchmark_rate" value="<?= $valor('benchmark_rate') ?>" step="0.01" min="0" placeholder="CDI 10,65" data-reference-rate><b>% a.a.</b></div>
            <small class="field-note">CDI, Selic ou IPCA usados na conta. Ajuste se o índice mudar.</small>
        </label>
    </div>

    <div class="estimate-box" data-estimate-box>
        <div>
            <span class="eyebrow">Estimativa automática</span>
            <strong data-estimate-value>R$ 0,00</strong>
            <small data-estimate-note>Informe o valor aplicado e a taxa contratada.</small>
        </div>
        <span class="estimate-badge" data-estimate-method>—</span>
    </div>

    <details class="advanced-options" <?= $editing ? 'open' : '' ?>>
        <summary>Mais opções <span>Benchmark, liquidez, vencimento e observações</span></summary>
        <div class="form-grid advanced-grid">
            <label class="field"><span>Benchmark</span><input type="text" name="benchmark" value="<?= $valor('benchmark') ?>" placeholder="Ex.: CDI" maxlength="80"></label>
            <label class="field"><span>Tipo de rentabilidade</span><input type="text" name="rate_type" value="<?= $valor('rate_type') ?>" placeholder="Ex.: CDI, IPCA+, prefixado" maxlength="40"></label>
            <label class="field"><span>Liquidez</span><input type="text" name="liquidity" value="<?= $valor('liquidity') ?>" placeholder="Ex.: D+1" maxlength="80"></label>
            <label class="field"><span>Data de vencimento</span><input type="date" name="maturity_date" value="<?= $valor('maturity_date') ?>"></label>
            <label class="field"><span>Status</span>
                <select name="status">
                    <option value="active" <?= ($investment->status ?? 'active') === 'active' ? 'selected' : '' ?>>Ativo</option>
                    <option value="matured" <?= ($investment->status ?? '') === 'matured' ? 'selected' : '' ?>>Vencido</option>
                    <option value="inactive" <?= ($investment->status ?? '') === 'inactive' ? 'selected' : '' ?>>Inativo</option>
                </select>
            </label>
            <label class="field field-wide"><span>Observações</span><textarea name="notes" rows="4" maxlength="2000" placeholder="Detalhes sobre a aplicação"><?= $valor('notes') ?></textarea></label>
        </div>
    </details>

    <div class="form-actions">
        <a href="/investimentos" class="button button-ghost">Cancelar</a>
        <button class="button button-primary" type="submit"><?= $editing ? 'Salvar investimento' : 'Salvar aplicação' ?></button>
    </div>
</form>

<script>
(function () {
    var form = document.querySelector('[data-investment-form]');
    if (!form) return;
    var tipo = form.querySelector('[data-type-select]');
    var principal = form.querySelector('[data-principal]');
    var taxa = form.querySelector('[data-contract-rate]');
    var periodo = form.querySelector('[data-rate-period]');
    var referencia = form.querySelector('[data-reference-rate]');
    var valor = form.querySelector('[data-estimate-value]');
    var nota = form.querySelector('[data-estimate-note]');
    var metodo = form.querySelector('[data-estimate-method]');
    var brl = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });

    function benchmark() {
        var opcao = tipo.options[tipo.selectedIndex];
        var valor = (opcao && opcao.dataset.benchmark) ? opcao.dataset.benchmark : 'none';
        if (valor === 'none') {
            var texto = (form.querySelector('[name="rate_type"]').value || '') + ' ' + (form.querySelector('[name="benchmark"]').value || '');
            texto = texto.toLowerCase();
            if (texto.indexOf('cdi') >= 0) return 'cdi';
            if (texto.indexOf('selic') >= 0) return 'selic';
            if (texto.indexOf('ipca') >= 0) return 'ipca';
            if (texto.indexOf('pre') >= 0 || texto.indexOf('fixad') >= 0) return 'prefixado';
        }
        return valor;
    }

    function calcular() {
        var p = parseFloat(principal.value) || 0;
        var r = parseFloat(taxa.value) || 0;
        var ref = parseFloat(referencia.value) || 0;
        var indice = benchmark();
        var periodoAtual = periodo.value;
        var contratadaAnual = periodoAtual === 'monthly' ? (Math.pow(1 + r / 100, 12) - 1) : (r / 100);
        var refAnual = ref / 100;
        var anual = 0;
        var disponivel = true;
        if (indice === 'cdi' || indice === 'selic') {
            anual = (r > 0 ? r / 100 : 1) * refAnual;
            if (refAnual <= 0) disponivel = false;
        } else if (indice === 'ipca') {
            anual = refAnual > 0 ? ((1 + refAnual) * (1 + contratadaAnual) - 1) : contratadaAnual;
        } else {
            anual = contratadaAnual > 0 ? contratadaAnual : refAnual;
            if (anual <= 0) disponivel = false;
        }
        var mensal = disponivel && p > 0 ? p * (Math.pow(1 + anual, 1 / 12) - 1) : 0;
        valor.textContent = brl.format(mensal) + ' / mês';
        if (!disponivel || p <= 0) {
            nota.textContent = 'Informe o valor aplicado e a taxa (ou a referência) para estimar.';
        } else {
            nota.textContent = 'Aproximadamente ' + brl.format(p * anual) + ' por ano · ' + (anual * 100).toFixed(2).replace('.', ',') + '% a.a. efetivos.';
        }
        var rotulos = { cdi: 'CDI', selic: 'Selic', ipca: 'IPCA +', prefixado: 'Prefixado', none: 'Sem índice' };
        metodo.textContent = rotulos[indice] || '—';
    }

    tipo.addEventListener('change', function () {
        var opcao = tipo.options[tipo.selectedIndex];
        var indice = opcao ? opcao.dataset.benchmark : 'none';
        var referenciaSugerida = <?= json_encode($referenceRates) ?>;
        if (indice && referenciaSugerida[indice] && !referencia.value) {
            referencia.value = referenciaSugerida[indice];
        }
        if (opcao && opcao.dataset.rate && !taxa.value) {
            taxa.value = opcao.dataset.rate;
        }
        if (opcao && opcao.dataset.period) {
            periodo.value = opcao.dataset.period;
        }
        calcular();
    });
    [principal, taxa, referencia, periodo].forEach(function (campo) { campo.addEventListener('input', calcular); });
    periodo.addEventListener('change', calcular);
    calcular();
})();
</script>
