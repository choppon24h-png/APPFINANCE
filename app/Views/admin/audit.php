<?php
$baseQuery = array_filter([
    'usuario' => $filtros['usuario'] ?: null,
    'acao' => $filtros['acao'] ?: null,
    'de' => $filtros['de'] ?: null,
    'ate' => $filtros['ate'] ?: null,
], static fn($v) => $v !== null);
$linkPagina = static fn(int $p) => '/admin/auditoria?' . http_build_query(array_merge($baseQuery, ['page' => $p]));
?>
<section class="hero-row compact-hero">
    <div>
        <span class="eyebrow">Administração</span>
        <h2 class="page-heading">Auditoria</h2>
        <p class="page-subtitle"><?= (int) $total ?> registro(s) · quem fez o quê, quando e de qual IP.</p>
    </div>
    <div class="hero-actions">
        <a class="button button-ghost" href="/admin">Visão geral</a>
    </div>
</section>

<form method="get" class="filter-card admin-filters">
    <label class="field">
        <span>Usuário</span>
        <select name="usuario">
            <option value="">Todos</option>
            <?php foreach ($usuarios as $u): ?>
                <option value="<?= (int) $u->id ?>" <?= (int) $filtros['usuario'] === (int) $u->id ? 'selected' : '' ?>><?= htmlspecialchars($u->name) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <label class="field">
        <span>Ação</span>
        <select name="acao">
            <option value="">Todas</option>
            <?php foreach ($acoes as $acao): ?>
                <option value="<?= htmlspecialchars($acao) ?>" <?= $filtros['acao'] === $acao ? 'selected' : '' ?>><?= htmlspecialchars($acao) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <label class="field"><span>De</span><input type="date" name="de" value="<?= htmlspecialchars($filtros['de']) ?>"></label>
    <label class="field"><span>Até</span><input type="date" name="ate" value="<?= htmlspecialchars($filtros['ate']) ?>"></label>
    <button class="button button-primary" type="submit">Filtrar</button>
    <a class="button button-ghost" href="/admin/auditoria">Limpar</a>
</form>

<section class="panel">
    <div class="panel-heading">
        <div><span class="eyebrow">Registros</span><h3><?= count($logs) ?> nesta página</h3></div>
        <span class="muted-text">Página <?= (int) $page ?> de <?= (int) $pages ?></span>
    </div>

    <?php if (!$logs): ?>
        <div class="empty-state"><span class="empty-icon" aria-hidden="true">◫</span><h3>Nenhum registro</h3><p>Ajuste os filtros para ampliar a busca.</p></div>
    <?php else: ?>
        <div class="data-table-wrap">
            <table class="data-table admin-table">
                <thead><tr><th>Quando</th><th>Usuário</th><th>Ação</th><th>Entidade</th><th>Detalhes</th><th>IP</th></tr></thead>
                <tbody>
                <?php foreach ($logs as $log): ?>
                    <tr>
                        <td data-label="Quando"><?= date('d/m/Y H:i:s', strtotime($log->created_at)) ?></td>
                        <td data-label="Usuário">
                            <?php if ($log->user_id): ?>
                                <a class="text-link" href="/admin/usuarios/<?= (int) $log->user_id ?>"><?= htmlspecialchars($log->user_name ?? 'Usuário #' . (int) $log->user_id) ?></a>
                                <small class="muted-text"><?= htmlspecialchars($log->user_email ?? '') ?></small>
                            <?php else: ?>
                                <span class="muted-text">Sistema</span>
                            <?php endif; ?>
                        </td>
                        <td data-label="Ação"><span class="audit-action"><?= htmlspecialchars($log->action) ?></span></td>
                        <td data-label="Entidade"><?= htmlspecialchars($log->entity ?? '—') ?><?= $log->entity_id ? ' #' . (int) $log->entity_id : '' ?></td>
                        <td data-label="Detalhes"><small class="muted-text"><?= htmlspecialchars(\App\Support\AuditDetails::text($log->details ?? null, 110)) ?></small></td>
                        <td data-label="IP"><?= htmlspecialchars($log->ip ?? '—') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>

        <?php if ($pages > 1): ?>
            <div class="pagination">
                <?php if ($page > 1): ?><a href="<?= $linkPagina($page - 1) ?>">‹ Anterior</a><?php endif; ?>
                <span><?= (int) $page ?> / <?= (int) $pages ?></span>
                <?php if ($page < $pages): ?><a href="<?= $linkPagina($page + 1) ?>">Próxima ›</a><?php endif; ?>
            </div>
        <?php endif; ?>
    <?php endif; ?>
</section>
