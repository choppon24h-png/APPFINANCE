<?php
$money = static fn($v) => number_format((float) $v, 0, ',', '.');
$origemRotulo = ['local' => 'E-mail e senha', 'google' => 'Google', 'microsoft' => 'Microsoft'];
$totalOrigem = array_sum(array_map(static fn($r) => (int) $r->total, $porOrigem)) ?: 1;
?>
<section class="hero-row">
    <div>
        <span class="eyebrow">Administração</span>
        <h2 class="page-heading">Visão geral</h2>
        <p class="page-subtitle">Contas de acesso do SOMASE, origens de cadastro e atividade recente.</p>
    </div>
    <div class="hero-actions">
        <a class="button button-secondary" href="/admin/usuarios">Gerenciar usuários</a>
        <a class="button button-ghost" href="/admin/auditoria">Ver auditoria</a>
    </div>
</section>

<section class="metrics-grid admin-metrics">
    <article class="metric-card">
        <span class="metric-label">Usuários totais</span>
        <strong class="metric-value"><?= $money($stats['total']) ?></strong>
        <span class="metric-note"><?= $money($stats['novos7']) ?> novos em 7 dias</span>
    </article>
    <article class="metric-card">
        <span class="metric-label">Ativos</span>
        <strong class="metric-value positive"><?= $money($stats['ativos']) ?></strong>
        <span class="metric-note">Podem acessar o sistema</span>
    </article>
    <article class="metric-card">
        <span class="metric-label">Inativos</span>
        <strong class="metric-value negative"><?= $money($stats['inativos']) ?></strong>
        <span class="metric-note">Acesso bloqueado</span>
    </article>
    <article class="metric-card">
        <span class="metric-label">Novos (7 dias)</span>
        <strong class="metric-value"><?= $money($stats['novos7']) ?></strong>
        <span class="metric-note">Cadastros na última semana</span>
    </article>
    <article class="metric-card">
        <span class="metric-label">Novos (30 dias)</span>
        <strong class="metric-value"><?= $money($stats['novos30']) ?></strong>
        <span class="metric-note">Cadastros no mês</span>
    </article>
</section>

<div class="dashboard-grid admin-grid">
    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Origem</span><h3>Como as contas foram criadas</h3></div>
        </div>
        <div class="source-list">
            <?php foreach ($porOrigem as $linha):
                $rotulo = $origemRotulo[$linha->origem] ?? $linha->origem;
                $pct = round(((int) $linha->total / $totalOrigem) * 100);
                ?>
                <div class="ranking-item">
                    <div class="ranking-line">
                        <strong><?= htmlspecialchars($rotulo) ?></strong>
                        <span><?= (int) $linha->total ?> · <?= $pct ?>%</span>
                    </div>
                    <div class="progress-track is-brand"><span style="width: <?= max(3, $pct) ?>%"></span></div>
                </div>
            <?php endforeach; ?>
        </div>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Perfis</span><h3>Distribuição por perfil de acesso</h3></div>
        </div>
        <ul class="admin-list">
            <?php foreach ($porPerfil as $perfil): ?>
                <li>
                    <span class="admin-list-main">
                        <strong><?= htmlspecialchars($perfil->perfil) ?></strong>
                        <small><?= htmlspecialchars($perfil->slug) ?></small>
                    </span>
                    <span class="admin-count"><?= (int) $perfil->total ?></span>
                </li>
            <?php endforeach; ?>
        </ul>
    </section>
</div>

<div class="dashboard-grid admin-grid">
    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Acessos</span><h3>Últimos logins</h3></div>
            <a class="text-link" href="/admin/usuarios?sort=last_login&dir=desc">Ver todos</a>
        </div>
        <?php if (!$ultimosAcessos): ?>
            <div class="empty-state compact"><p>Nenhum acesso registrado ainda.</p></div>
        <?php else: ?>
            <ul class="admin-list">
                <?php foreach ($ultimosAcessos as $acesso): ?>
                    <li>
                        <span class="avatar avatar-sm"><?= htmlspecialchars(mb_strtoupper(mb_substr($acesso->name, 0, 1))) ?></span>
                        <span class="admin-list-main">
                            <strong><?= htmlspecialchars($acesso->name) ?></strong>
                            <small><?= htmlspecialchars($acesso->email) ?></small>
                        </span>
                        <span class="admin-when"><?= date('d/m H:i', strtotime($acesso->last_login_at)) ?></span>
                    </li>
                <?php endforeach; ?>
            </ul>
        <?php endif; ?>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div><span class="eyebrow">Cadastros</span><h3>Mais recentes</h3></div>
        </div>
        <?php if (!$ultimosCadastros): ?>
            <div class="empty-state compact"><p>Nenhum cadastro ainda.</p></div>
        <?php else: ?>
            <ul class="admin-list">
                <?php foreach ($ultimosCadastros as $novo): ?>
                    <li>
                        <span class="avatar avatar-sm"><?= htmlspecialchars(mb_strtoupper(mb_substr($novo->name, 0, 1))) ?></span>
                        <span class="admin-list-main">
                            <strong><?= htmlspecialchars($novo->name) ?></strong>
                            <small><?= htmlspecialchars($origemRotulo[$novo->auth_provider] ?? $novo->auth_provider) ?> · <?= date('d/m/Y', strtotime($novo->created_at)) ?></small>
                        </span>
                        <a class="text-link" href="/admin/usuarios/<?= (int) $novo->id ?>">Ver</a>
                    </li>
                <?php endforeach; ?>
            </ul>
        <?php endif; ?>
    </section>
</div>

<section class="panel">
    <div class="panel-heading">
        <div><span class="eyebrow">Auditoria</span><h3>Últimas ações administrativas</h3></div>
        <a class="text-link" href="/admin/auditoria">Abrir auditoria</a>
    </div>
    <?php if (!$ultimasAcoes): ?>
        <div class="empty-state compact"><p>Nenhuma ação registrada.</p></div>
    <?php else: ?>
        <div class="data-table-wrap">
            <table class="data-table">
                <thead><tr><th>Quando</th><th>Quem</th><th>Ação</th><th>Entidade</th><th>IP</th></tr></thead>
                <tbody>
                <?php foreach ($ultimasAcoes as $acao): ?>
                    <tr>
                        <td data-label="Quando"><?= date('d/m/Y H:i', strtotime($acao->created_at)) ?></td>
                        <td data-label="Quem"><?= htmlspecialchars($acao->user_name ?? 'Sistema') ?></td>
                        <td data-label="Ação"><span class="audit-action"><?= htmlspecialchars($acao->action) ?></span></td>
                        <td data-label="Entidade"><?= htmlspecialchars($acao->entity ?? '—') ?><?= $acao->entity_id ? ' #' . (int) $acao->entity_id : '' ?></td>
                        <td data-label="IP"><?= htmlspecialchars($acao->ip ?? '—') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</section>
