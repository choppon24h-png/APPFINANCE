<?php
$money = static fn($value) => 'R$ ' . number_format((float) $value, 2, ',', '.');
$income = (float) ($summary->income ?? 0);
$expense = (float) ($summary->expense ?? 0);
$result = $income - $expense;
$invested = (float) ($investTotals->invested ?? 0);
$return = (float) ($investTotals->total_return ?? 0);
$evolutionMap = [];
foreach ($evolution as $row) $evolutionMap[$row->period] = ['income' => (float) $row->income, 'expense' => (float) $row->expense];
$chartLabels = [];
$chartIncome = [];
$chartExpense = [];
$cursor = new DateTimeImmutable('first day of this month');
$cursor = $cursor->modify('-' . ($period - 1) . ' months');
for ($i = 0; $i < $period; $i++) {
    $key = $cursor->format('Y-m'); $chartLabels[] = $cursor->format('M/y');
    $chartIncome[] = $evolutionMap[$key]['income'] ?? 0; $chartExpense[] = $evolutionMap[$key]['expense'] ?? 0;
    $cursor = $cursor->modify('+1 month');
}
$maxExpense = max(array_map(static fn($row) => (float) $row->total, $expenseRanking) ?: [1]);
?>
<section class="hero-row">
    <div><p class="eyebrow">Resumo de <?= htmlspecialchars($monthLabel) ?></p><h2 class="page-heading">Olá, <?= htmlspecialchars(explode(' ', trim($usuarioLogado->name ?? ''))[0] ?: 'olá') ?>.</h2><p class="page-subtitle">Veja como está sua vida financeira e escolha o próximo passo.</p></div>
    <div class="period-switcher" aria-label="Período do dashboard">
        <?php foreach ([6, 12, 24] as $option): ?><a class="period-option <?= $period === $option ? 'active' : '' ?>" href="/dashboard?period=<?= $option ?>"><?= $option ?>m</a><?php endforeach; ?>
    </div>
</section>
<section class="metrics-grid" aria-label="Indicadores principais">
    <article class="metric-card metric-primary"><span class="metric-label">Saldo total</span><strong class="metric-value"><?= $money($totalBalance) ?></strong><span class="metric-note">Disponível nas contas ativas</span><span class="metric-icon">◒</span></article>
    <article class="metric-card"><span class="metric-label">Receitas do mês</span><strong class="metric-value positive"><?= $money($income) ?></strong><span class="metric-note">Valores recebidos</span><span class="metric-icon icon-income">↗</span></article>
    <article class="metric-card"><span class="metric-label">Despesas do mês</span><strong class="metric-value negative"><?= $money($expense) ?></strong><span class="metric-note">Pagamentos realizados</span><span class="metric-icon icon-expense">↘</span></article>
    <article class="metric-card"><span class="metric-label">Resultado do mês</span><strong class="metric-value <?= $result >= 0 ? 'positive' : 'negative' ?>"><?= $money($result) ?></strong><span class="metric-note">Receitas menos despesas</span><span class="metric-icon">=</span></article>
    <article class="metric-card"><span class="metric-label">Total investido</span><strong class="metric-value"><?= $money($invested) ?></strong><span class="metric-note">Patrimônio aplicado</span><span class="metric-icon">✦</span></article>
    <article class="metric-card"><span class="metric-label">Rendimentos</span><strong class="metric-value positive"><?= $money($return) ?></strong><span class="metric-note">Acumulado informado</span><span class="metric-icon">↗</span></article>
</section>
<?php if ($overdueCount > 0): ?><div class="alert alert-warning"><span class="alert-symbol">!</span><div><strong>Atenção aos vencimentos</strong><p>Você tem <?= (int) $overdueCount ?> lançamento(s) vencido(s) ou pendente(s). Organize seus próximos pagamentos.</p></div><a href="/lancamentos?status=overdue">Ver lançamentos</a></div><?php endif; ?>
<div class="dashboard-grid">
    <section class="panel panel-chart"><div class="panel-heading"><div><span class="eyebrow">Evolução financeira</span><h3>Entradas e saídas</h3></div><span class="legend"><i class="legend-income"></i> Receitas <i class="legend-expense"></i> Despesas</span></div><div class="chart-wrap"><canvas id="evolution-chart" data-labels='<?= htmlspecialchars(json_encode($chartLabels, JSON_UNESCAPED_UNICODE)) ?>' data-income='<?= htmlspecialchars(json_encode($chartIncome)) ?>' data-expense='<?= htmlspecialchars(json_encode($chartExpense)) ?>' aria-label="Gráfico da evolução financeira"></canvas></div></section>
    <section class="panel"><div class="panel-heading"><div><span class="eyebrow">Prioridades</span><h3>Próximos vencimentos</h3></div><a class="text-link" href="/lancamentos">Ver todos</a></div><?php if (!$upcoming): ?><div class="empty-state compact"><span class="empty-icon">✓</span><p>Nenhum vencimento nos próximos 30 dias.</p></div><?php else: ?><div class="upcoming-list"><?php foreach ($upcoming as $item): ?><div class="upcoming-item"><div class="date-chip"><b><?= date('d', strtotime($item->due_date)) ?></b><small><?= date('M', strtotime($item->due_date)) ?></small></div><div class="upcoming-info"><strong><?= htmlspecialchars($item->description) ?></strong><small><?= htmlspecialchars($item->account_name) ?></small></div><b class="amount <?= $item->type === 'income' ? 'positive' : 'negative' ?>"><?= $item->type === 'income' ? '+' : '-' ?><?= $money($item->amount) ?></b></div><?php endforeach; ?></div><?php endif; ?></section>
</div>
<div class="dashboard-grid lower-grid">
    <section class="panel"><div class="panel-heading"><div><span class="eyebrow">Despesas</span><h3>Onde estou gastando?</h3></div><a class="text-link" href="/lancamentos?type=expense">Detalhar</a></div><?php if (!$expenseRanking): ?><div class="empty-state compact"><span class="empty-icon">◌</span><p>Registre despesas para visualizar sua composição.</p></div><?php else: ?><div class="ranking-list"><?php foreach ($expenseRanking as $row): $percent = $maxExpense > 0 ? ((float) $row->total / $maxExpense) * 100 : 0; ?><a href="/lancamentos?type=expense" class="ranking-item"><div class="ranking-line"><strong><?= htmlspecialchars($row->label) ?></strong><span><?= $money($row->total) ?></span></div><div class="progress-track"><span style="width: <?= min(100, $percent) ?>%"></span></div></a><?php endforeach; ?></div><?php endif; ?></section>
    <section class="panel"><div class="panel-heading"><div><span class="eyebrow">Receitas</span><h3>Maiores fontes</h3></div><a class="text-link" href="/lancamentos?type=income">Detalhar</a></div><?php if (!$incomeRanking): ?><div class="empty-state compact"><span class="empty-icon">↗</span><p>Registre receitas para ver suas principais fontes.</p></div><?php else: ?><div class="source-list"><?php foreach ($incomeRanking as $index => $row): ?><a href="/lancamentos?type=income" class="source-item"><span class="rank-number"><?= $index + 1 ?></span><span><strong><?= htmlspecialchars($row->label) ?></strong><small><?= (int) $row->items ?> lançamento(s)</small></span><b class="positive"><?= $money($row->total) ?></b></a><?php endforeach; ?></div><?php endif; ?></section>
    <section class="panel"><div class="panel-heading"><div><span class="eyebrow">Investimentos</span><h3>Qual conta rende mais?</h3></div><a class="text-link" href="/investimentos">Ver investimentos</a></div><div class="toggle-links"><a class="<?= ($_GET['investment_order'] ?? 'absolute') === 'absolute' ? 'active' : '' ?>" href="/dashboard?investment_order=absolute">Maior rendimento</a><a class="<?= ($_GET['investment_order'] ?? '') === 'percentage' ? 'active' : '' ?>" href="/dashboard?investment_order=percentage">Maior percentual</a></div><?php if (!$bestInvestments): ?><div class="empty-state compact"><span class="empty-icon">✦</span><p>Cadastre um investimento e seus rendimentos.</p></div><?php else: ?><div class="investment-list"><?php foreach ($bestInvestments as $row): ?><div class="investment-item"><div><strong><?= htmlspecialchars($row->institution) ?></strong><small><?= htmlspecialchars($row->name) ?></small></div><div class="investment-result"><b><?= $money($row->return_amount) ?></b><small><?= number_format((float) $row->return_percentage, 2, ',', '.') ?>%</small></div></div><?php endforeach; ?></div><?php endif; ?></section>
    <section class="panel panel-cta"><span class="cta-symbol">+</span><h3>Registre uma nova movimentação</h3><p>Receitas, despesas e recorrências em uma única tela.</p><a href="/lancamentos/novo" class="button button-light">Novo lançamento</a></section>
</div>
<script>window.APP_DASHBOARD = true;</script>
