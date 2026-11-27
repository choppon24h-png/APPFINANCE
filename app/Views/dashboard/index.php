<?php
use App\Core\Auth;

$usuarioLogado = Auth::user();
$money = static fn($value) => 'R$ ' . number_format((float) $value, 2, ',', '.');
$percent = static fn($value) => number_format((float) $value, 1, ',', '.') . '%';
$firstName = explode(' ', trim((string) ($usuarioLogado->name ?? '')))[0] ?: 'tudo bem';
$csrf = $_SESSION['csrf_token'] ?? '';

$income = (float) ($summary->income ?? 0);
$expense = (float) ($summary->expense ?? 0);
$expectedIncome = (float) ($summary->expected_income ?? 0);
$pendingExpense = (float) ($summary->pending_expense ?? 0);
$result = $income - $expense;
$invested = (float) ($investTotals->invested ?? 0);
$totalReturn = (float) ($investTotals->total_return ?? 0);
$monthlyReturn = (float) ($investTotals->monthly_return ?? 0);
$currentValue = (float) ($investTotals->current_value ?? 0);

$evolutionMap = [];
foreach ($evolution as $row) {
    $evolutionMap[$row->period] = ['income' => (float) $row->income, 'expense' => (float) $row->expense];
}
$chartLabels = [];
$chartIncome = [];
$chartExpense = [];
$cursor = (new DateTimeImmutable('first day of this month'))->modify('-' . ($period - 1) . ' months');
for ($i = 0; $i < $period; $i++) {
    $key = $cursor->format('Y-m');
    $chartLabels[] = $cursor->format('M/y');
    $chartIncome[] = $evolutionMap[$key]['income'] ?? 0;
    $chartExpense[] = $evolutionMap[$key]['expense'] ?? 0;
    $cursor = $cursor->modify('+1 month');
}
$chartResult = array_map(static fn($i, $e) => $i - $e, $chartIncome, $chartExpense);
$chartTotal = array_sum($chartIncome) + array_sum($chartExpense);
$hasChart = $chartTotal > 0;
$averageExpense = $period > 0 ? array_sum($chartExpense) / $period : 0;

$currentMonthIncome = $chartIncome ? end($chartIncome) : 0;
$previousMonthIncome = count($chartIncome) > 1 ? $chartIncome[count($chartIncome) - 2] : 0;
$currentMonthExpense = $chartExpense ? end($chartExpense) : 0;
$previousMonthExpense = count($chartExpense) > 1 ? $chartExpense[count($chartExpense) - 2] : 0;
$incomeDelta = $previousMonthIncome > 0 ? (($currentMonthIncome - $previousMonthIncome) / $previousMonthIncome) * 100 : null;
$expenseDelta = $previousMonthExpense > 0 ? (($currentMonthExpense - $previousMonthExpense) / $previousMonthExpense) * 100 : null;

$palette = ['#ff5d73', '#ff8a5b', '#f5b83d', '#c084fc', '#3b8bff', '#8b9bff', '#ff9ec4', '#f97316'];
$expenseSeries = [];
$expenseRankTotal = 0.0;
foreach ($expenseRanking as $index => $row) {
    $value = (float) $row->total;
    $expenseRankTotal += $value;
    $expenseSeries[] = [
        'label' => (string) $row->label,
        'value' => $value,
        'color' => $palette[$index % count($palette)],
    ];
}
$maxIncome = max(array_map(static fn($row) => (float) $row->total, $incomeRanking) ?: [1]);
$statusLabels = ['pending' => 'Pendente', 'paid' => 'Paga', 'overdue' => 'Vencida', 'cancelled' => 'Cancelada', 'expected' => 'Prevista', 'received' => 'Recebida', 'late' => 'Atrasada'];
$today = date('Y-m-d');
$hasAnyData = $income > 0 || $expense > 0 || (float) $totalBalance !== 0.0 || $invested > 0;
$investmentOrder = $_GET['investment_order'] ?? 'absolute';
$chartAria = 'Gráfico de receitas e despesas dos últimos ' . (int) $period . ' meses. Receitas totais ' . $money(array_sum($chartIncome)) . ', despesas totais ' . $money(array_sum($chartExpense)) . '.';
?>
<section class="hero-row">
    <div>
        <span class="eyebrow">SOMASE · <?= htmlspecialchars($monthLabel) ?></span>
        <h2 class="page-heading">Olá, <?= htmlspecialchars($firstName) ?></h2>
        <p class="page-subtitle">Seu controle financeiro dos últimos <?= (int) $period ?> meses, com saldo, receitas, despesas e investimentos.</p>
    </div>
    <div class="period-switcher" role="group" aria-label="Período do resumo">
        <?php foreach ([6, 12, 24] as $option): ?>
            <a class="period-option <?= $period === $option ? 'active' : '' ?>" href="/dashboard?period=<?= $option ?>"<?= $period === $option ? ' aria-current="true"' : '' ?>><?= $option ?> meses</a>
        <?php endforeach; ?>
    </div>
</section>

<?php if ($overdueCount > 0): ?>
    <div class="alert alert-warning" role="alert">
        <span class="alert-symbol" aria-hidden="true">!</span>
        <div>
            <strong>Você tem <?= (int) $overdueCount ?> lançamento<?= $overdueCount > 1 ? 's' : '' ?> em atraso</strong>
            <p>Regularize os vencimentos para manter o saldo das contas correto.</p>
        </div>
        <a href="/lancamentos?status=overdue">Ver atrasados</a>
    </div>
<?php endif; ?>

<section class="kpi-grid" aria-label="Indicadores principais">
    <article class="kpi-card kpi-primary">
        <span class="kpi-label">Saldo total</span>
        <strong class="kpi-value"><?= $money($totalBalance) ?></strong>
        <span class="kpi-note">Somado das contas ativas</span>
        <span class="kpi-icon " aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><circle cx="16.5" cy="14.5" r="1.1" fill="currentColor" stroke="none"/></svg></span>
    </article>
    <article class="kpi-card">
        <span class="kpi-label">Receitas do período</span>
        <strong class="kpi-value positive"><?= $money($income) ?></strong>
        <?php if ($incomeDelta !== null): ?>
            <span class="kpi-delta <?= $incomeDelta >= 0 ? 'up' : 'down' ?>"><?= $incomeDelta >= 0 ? '▲' : '▼' ?> <?= $percent(abs($incomeDelta)) ?> no mês</span>
        <?php else: ?>
            <span class="kpi-note"><?= $expectedIncome > 0 ? 'Previstas: ' . $money($expectedIncome) : 'Valores recebidos' ?></span>
        <?php endif; ?>
        <span class="kpi-icon green" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M7 17 17 7"/><path d="M9 7h8v8"/></svg></span>
    </article>
    <article class="kpi-card">
        <span class="kpi-label">Despesas do período</span>
        <strong class="kpi-value negative"><?= $money($expense) ?></strong>
        <?php if ($expenseDelta !== null): ?>
            <span class="kpi-delta <?= $expenseDelta <= 0 ? 'up' : 'down' ?>"><?= $expenseDelta <= 0 ? '▼' : '▲' ?> <?= $percent(abs($expenseDelta)) ?> no mês</span>
        <?php else: ?>
            <span class="kpi-note"><?= $pendingExpense > 0 ? 'A pagar: ' . $money($pendingExpense) : 'Pagamentos realizados' ?></span>
        <?php endif; ?>
        <span class="kpi-icon red" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7l10 10"/><path d="M17 9v8H9"/></svg></span>
    </article>
    <article class="kpi-card">
        <span class="kpi-label">Resultado</span>
        <strong class="kpi-value <?= $result >= 0 ? 'positive' : 'negative' ?>"><?= $money($result) ?></strong>
        <span class="kpi-note">Receitas menos despesas</span>
        <span class="kpi-icon amber" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M5 9h14"/><path d="M5 15h14"/></svg></span>
    </article>
    <article class="kpi-card">
        <span class="kpi-label">Total investido</span>
        <strong class="kpi-value"><?= $money($invested) ?></strong>
        <span class="kpi-note">Rendimentos <?= $money($totalReturn) ?></span>
        <span class="kpi-icon " aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M4 18V9"/><path d="M10 18V5"/><path d="M16 18v-6"/><path d="M20 18H2"/></svg></span>
    </article>
</section>

<?php if (!$hasAnyData): ?>
    <section class="panel" style="margin-bottom:14px">
        <div class="empty-state">
            <span class="empty-icon" aria-hidden="true">Σ</span>
            <h3>Bem-vindo ao SOMASE</h3>
            <p>Cadastre sua primeira conta e registre um lançamento para ver os indicadores ganharem vida.</p>
            <div class="hero-actions">
                <a class="button button-primary" href="/contas/nova">Cadastre sua primeira conta</a>
                <a class="button button-ghost" href="/lancamentos/novo">Novo lançamento</a>
            </div>
        </div>
    </section>
<?php endif; ?>

<div class="dashboard-grid">
    <section class="panel panel-chart">
        <div class="panel-heading">
            <div><span class="eyebrow">Evolução financeira</span><h3>Receitas × despesas</h3></div>
            <span class="legend">
                <span><i class="legend-income"></i>Receitas</span>
                <span><i class="legend-expense"></i>Despesas</span>
                <span><i class="legend-result"></i>Resultado</span>
            </span>
        </div>
        <?php if (!$hasChart): ?>
            <div class="empty-state compact">
                <span class="empty-icon" aria-hidden="true">◌</span>
                <p>Sem movimentações nos últimos <?= (int) $period ?> meses. Registre receitas e despesas para ver a evolução.</p>
                <a class="button button-secondary" href="/lancamentos/novo">Novo lançamento</a>
            </div>
        <?php else: ?>
            <div class="chart-wrap" data-chart="evolution"
                 data-labels='<?= htmlspecialchars(json_encode($chartLabels, JSON_UNESCAPED_UNICODE), ENT_QUOTES) ?>'
                 data-income='<?= htmlspecialchars(json_encode($chartIncome), ENT_QUOTES) ?>'
                 data-expense='<?= htmlspecialchars(json_encode($chartExpense), ENT_QUOTES) ?>'
                 data-result='<?= htmlspecialchars(json_encode($chartResult), ENT_QUOTES) ?>'>
                <svg class="chart-svg" role="img" aria-label="<?= htmlspecialchars($chartAria) ?>" preserveAspectRatio="none"></svg>
                <div class="chart-tooltip" role="status" aria-live="polite"></div>
            </div>
            <div class="chart-footer">
                <div><span>Receitas</span><strong class="positive"><?= $money(array_sum($chartIncome)) ?></strong></div>
                <div><span>Despesas</span><strong class="negative"><?= $money(array_sum($chartExpense)) ?></strong></div>
                <div><span>Resultado</span><strong><?= $money(array_sum($chartResult)) ?></strong></div>
                <div><span>Despesa média</span><strong><?= $money($averageExpense) ?></strong></div>
            </div>
        <?php endif; ?>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Prioridades</span><h3>Próximos 30 dias</h3></div>
            <a class="text-link" href="/lancamentos">Ver todos</a>
        </div>
        <?php if (!$upcoming): ?>
            <div class="empty-state compact">
                <span class="empty-icon" aria-hidden="true">✓</span>
                <p>Nenhum vencimento nos próximos 30 dias.</p>
                <a class="button button-ghost" href="/lancamentos/novo">Agendar lançamento</a>
            </div>
        <?php else: ?>
            <div class="upcoming-list">
                <?php foreach ($upcoming as $item):
                    $isLate = ($item->due_date ?? '') < $today;
                    $isIncome = $item->type === 'income';
                    $nextStatus = $isIncome ? 'received' : 'paid';
                    ?>
                    <div class="upcoming-item <?= $isLate ? 'is-late' : '' ?>">
                        <div class="date-chip"><b><?= date('d', strtotime($item->due_date)) ?></b><small><?= date('M', strtotime($item->due_date)) ?></small></div>
                        <div class="upcoming-info">
                            <strong><?= htmlspecialchars($item->description) ?></strong>
                            <small><?= htmlspecialchars($item->account_name) ?> · <?= htmlspecialchars($statusLabels[$item->status] ?? $item->status) ?></small>
                        </div>
                        <div class="upcoming-side">
                            <b class="amount <?= $isIncome ? 'positive' : 'negative' ?>"><?= $isIncome ? '+' : '-' ?><?= $money($item->amount) ?></b>
                            <form method="post" action="/lancamentos/<?= (int) $item->id ?>/status">
                                <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                                <input type="hidden" name="status" value="<?= $nextStatus ?>">
                                <button type="submit" class="pay-now" title="<?= $isIncome ? 'Marcar como recebida' : 'Marcar como paga' ?>" aria-label="<?= $isIncome ? 'Marcar ' . htmlspecialchars($item->description) . ' como recebida' : 'Marcar ' . htmlspecialchars($item->description) . ' como paga' ?>">✓</button>
                            </form>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </section>
</div>

<div class="dashboard-grid lower-grid">
    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Despesas</span><h3>Onde o dinheiro foi</h3></div>
            <a class="text-link" href="/lancamentos?type=expense">Detalhar</a>
        </div>
        <?php if (!$expenseSeries): ?>
            <div class="empty-state compact">
                <span class="empty-icon" aria-hidden="true">◌</span>
                <p>Registre despesas para ver a composição por categoria.</p>
                <a class="button button-ghost" href="/lancamentos/novo">Novo lançamento</a>
            </div>
        <?php else: ?>
            <div class="donut-layout" data-chart="donut" data-series='<?= htmlspecialchars(json_encode($expenseSeries, JSON_UNESCAPED_UNICODE), ENT_QUOTES) ?>'>
                <div class="donut-wrap">
                    <svg class="donut-svg" viewBox="0 0 120 120" role="img" aria-label="Distribuição das despesas por categoria"></svg>
                    <div class="donut-center"><strong><?= $money($expenseRankTotal) ?></strong><span>Despesas</span></div>
                </div>
                <div class="ranking-list">
                    <?php foreach ($expenseSeries as $slice):
                        $share = $expenseRankTotal > 0 ? ($slice['value'] / $expenseRankTotal) * 100 : 0;
                        ?>
                        <a class="ranking-item" href="/lancamentos?type=expense">
                            <div class="ranking-line">
                                <strong><span class="cat-dot" style="background: <?= htmlspecialchars($slice['color']) ?>"></span><?= htmlspecialchars($slice['label']) ?></strong>
                                <span><?= $money($slice['value']) ?> · <?= number_format($share, 0, ',', '.') ?>%</span>
                            </div>
                            <div class="progress-track"><span style="width: <?= min(100, $share) ?>%; background: <?= htmlspecialchars($slice['color']) ?>"></span></div>
                        </a>
                    <?php endforeach; ?>
                </div>
            </div>
        <?php endif; ?>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Receitas</span><h3>Maiores fontes</h3></div>
            <a class="text-link" href="/lancamentos?type=income">Detalhar</a>
        </div>
        <?php if (!$incomeRanking): ?>
            <div class="empty-state compact">
                <span class="empty-icon" aria-hidden="true">↗</span>
                <p>Registre receitas para identificar suas principais fontes.</p>
                <a class="button button-ghost" href="/lancamentos/novo">Novo lançamento</a>
            </div>
        <?php else: ?>
            <div class="source-list">
                <?php foreach ($incomeRanking as $index => $row):
                    $share = $maxIncome > 0 ? ((float) $row->total / $maxIncome) * 100 : 0;
                    ?>
                    <a href="/lancamentos?type=income" class="ranking-item">
                        <div class="ranking-line">
                            <strong><span class="rank-number" style="display:inline-grid;vertical-align:middle;margin-right:7px"><?= $index + 1 ?></span><?= htmlspecialchars($row->label) ?></strong>
                            <span><?= $money($row->total) ?></span>
                        </div>
                        <div class="progress-track is-income"><span style="width: <?= min(100, $share) ?>%"></span></div>
                    </a>
                <?php endforeach; ?>
            </div>
            <div class="source-total">
                <span>Total recebido no período</span>
                <strong class="positive"><?= $money($income) ?></strong>
            </div>
        <?php endif; ?>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Investimentos</span><h3>Melhores rendimentos</h3></div>
            <a class="text-link" href="/investimentos">Ver todos</a>
        </div>
        <div class="toggle-links" style="margin-bottom:12px">
            <a class="<?= $investmentOrder === 'absolute' ? 'active' : '' ?>" href="/dashboard?period=<?= (int) $period ?>&investment_order=absolute">Valor</a>
            <a class="<?= $investmentOrder === 'percentage' ? 'active' : '' ?>" href="/dashboard?period=<?= (int) $period ?>&investment_order=percentage">Percentual</a>
        </div>
        <?php if (!$bestInvestments): ?>
            <div class="empty-state compact">
                <span class="empty-icon" aria-hidden="true">✦</span>
                <p>Cadastre um investimento e informe os rendimentos mensais.</p>
                <a class="button button-ghost" href="/investimentos/novo">Novo investimento</a>
            </div>
        <?php else: ?>
            <div class="investment-list">
                <?php foreach ($bestInvestments as $row): ?>
                    <div class="investment-item">
                        <div>
                            <strong><?= htmlspecialchars($row->institution) ?></strong>
                            <small><?= htmlspecialchars($row->name) ?> · investido <?= $money($row->amount_invested) ?></small>
                        </div>
                        <div class="investment-result">
                            <b><?= $money($row->return_amount) ?></b>
                            <small><?= number_format((float) $row->return_percentage, 2, ',', '.') ?>%</small>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
            <div class="chart-footer">
                <div><span>Investido</span><strong><?= $money($invested) ?></strong></div>
                <div><span>Valor atual</span><strong><?= $money($currentValue) ?></strong></div>
                <div><span>Rendimento no mês</span><strong class="positive"><?= $money($monthlyReturn) ?></strong></div>
            </div>
        <?php endif; ?>
    </section>

    <section class="panel panel-cta">
        <span class="cta-symbol" aria-hidden="true">+</span>
        <h3>Registre uma nova movimentação</h3>
        <p>Receitas, despesas e recorrências em uma única tela, com atualização automática do saldo.</p>
        <a href="/lancamentos/novo" class="button button-light">Novo lançamento</a>
    </section>
</div>
<script>window.APP_DASHBOARD = true;</script>
