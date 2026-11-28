<?php
$money = static fn($value) => 'R$ ' . number_format((float) $value, 2, ',', '.');
?>
<section class="hero-row compact-hero">
    <div>
        <span class="eyebrow">Patrimônio e rendimento</span>
        <h2 class="page-heading">Investimentos</h2>
        <p class="page-subtitle">Acompanhe o que está aplicado, o que cada conta rende e a receita estimada de cada mês.</p>
    </div>
    <div class="hero-actions">
        <a class="button button-ghost" href="/investimentos/tipos">Tipos de investimento</a>
        <a class="button button-primary" href="/investimentos/novo"><span>+</span> Nova aplicação</a>
    </div>
</section>

<section class="metrics-grid investment-metrics">
    <article class="metric-card"><span class="metric-label">Valor investido</span><strong class="metric-value"><?= $money($totals->invested ?? 0) ?></strong><span class="metric-note">Aplicações registradas</span></article>
    <article class="metric-card"><span class="metric-label">Rendimento acumulado</span><strong class="metric-value positive"><?= $money($totals->total_return ?? 0) ?></strong><span class="metric-note">Somatório informado</span></article>
    <article class="metric-card"><span class="metric-label">Patrimônio atual</span><strong class="metric-value"><?= $money($totals->current_value ?? 0) ?></strong><span class="metric-note">Aplicado + rendimentos</span></article>
    <article class="metric-card metric-highlight"><span class="metric-label">Receita estimada do mês</span><strong class="metric-value positive"><?= $money($totalEstimado ?? 0) ?></strong><span class="metric-note">Pelas taxas contratadas</span></article>
</section>

<section class="panel">
    <div class="panel-heading"><div><span class="eyebrow">Contas e instituições</span><h3>Minhas aplicações</h3></div></div>
    <?php if (!$investments): ?>
        <div class="empty-state"><span class="empty-icon">✦</span><h3>Seu patrimônio começa aqui</h3><p>Cadastre uma aplicação para acompanhar valor, rendimento e evolução.</p><a class="button button-primary" href="/investimentos/novo">Cadastrar aplicação</a></div>
    <?php else: ?>
        <div class="investment-table-wrap">
            <table class="data-table">
                <thead><tr><th>Investimento</th><th>Conta</th><th>Aplicado</th><th>Rendimento</th><th>Rentabilidade</th><th>Estimado/mês</th><th></th></tr></thead>
                <tbody>
                <?php foreach ($investments as $item): ?>
                    <?php
                    $totalReturn = (float) $item->accumulated_return;
                    $rate = (float) $item->amount_invested > 0 ? ($totalReturn / (float) $item->amount_invested) * 100 : 0;
                    $estimativa = $estimativas[(int) $item->id] ?? ['monthly_amount' => 0, 'method' => '—', 'available' => false];
                    ?>
                    <tr>
                        <td data-label="Investimento">
                            <div class="transaction-name">
                                <span class="type-dot income"></span>
                                <strong><?= htmlspecialchars($item->name) ?></strong>
                                <small><?= htmlspecialchars($item->institution) ?> · <?= htmlspecialchars($item->type_name ?? $item->investment_type) ?></small>
                            </div>
                        </td>
                        <td data-label="Conta"><?= htmlspecialchars($item->account_name) ?></td>
                        <td data-label="Aplicado"><?= $money($item->amount_invested) ?></td>
                        <td data-label="Rendimento" class="positive"><?= $money($totalReturn) ?></td>
                        <td data-label="Rentabilidade" class="positive"><?= number_format($rate, 2, ',', '.') ?>%</td>
                        <td data-label="Estimado/mês">
                            <strong class="<?= $estimativa['monthly_amount'] > 0 ? 'positive' : 'muted-text' ?>"><?= $money($estimativa['monthly_amount']) ?></strong>
                            <small class="estimate-method" title="<?= htmlspecialchars($estimativa['method']) ?>"><?= htmlspecialchars($estimativa['method']) ?></small>
                        </td>
                        <td class="row-actions">
                            <?php if ($estimativa['monthly_amount'] > 0): ?>
                                <a class="action-link" href="/investimentos/<?= (int) $item->id ?>/rendimento?estimado=1" title="Abrir o rendimento já preenchido com a estimativa">Lançar estimado</a>
                            <?php endif; ?>
                            <a class="action-link" href="/investimentos/<?= (int) $item->id ?>/rendimento">+ Rendimento</a>
                            <details class="action-menu"><summary>•••</summary><div class="action-popover">
                                <a href="/investimentos/<?= (int) $item->id ?>/editar">Editar</a>
                                <a href="/investimentos/<?= (int) $item->id ?>/historico">Histórico</a>
                                <a href="/investimentos/<?= (int) $item->id ?>/resgatar">Resgatar</a>
                            </div></details>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</section>

<section class="panel">
    <div class="panel-heading"><div><span class="eyebrow">Comparação baseada nos seus dados</span><h3>Qual conta está rendendo mais?</h3></div><div class="toggle-links"><a class="<?= $order === 'absolute' ? 'active' : '' ?>" href="/investimentos?order=absolute">Em R$</a><a class="<?= $order === 'percentage' ? 'active' : '' ?>" href="/investimentos?order=percentage">Em %</a></div></div>
    <?php if (!$ranking): ?>
        <div class="empty-state compact"><p>Registre rendimentos para criar seu ranking.</p></div>
    <?php else: ?>
        <div class="ranking-table">
            <div class="ranking-header"><span>Posição</span><span>Instituição / aplicação</span><span>Investido</span><span>Rendimento</span><span>Rentabilidade</span></div>
            <?php foreach ($ranking as $index => $row): ?>
                <div class="ranking-row"><span class="rank-number"><?= $index + 1 ?></span><span><strong><?= htmlspecialchars($row->institution) ?></strong><small><?= htmlspecialchars($row->name) ?></small></span><span><?= $money($row->amount_invested) ?></span><span class="positive"><?= $money($row->return_amount) ?></span><span class="positive"><?= number_format((float) $row->return_percentage, 2, ',', '.') ?>%</span></div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</section>
