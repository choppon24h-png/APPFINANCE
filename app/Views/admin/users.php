<?php
$origemRotulo = ['local' => 'E-mail', 'google' => 'Google', 'microsoft' => 'Microsoft'];
$idade = static function (?string $nasc): string {
    if (!$nasc) return '—';
    try { return (new DateTimeImmutable($nasc))->diff(new DateTimeImmutable('today'))->y . ' anos'; }
    catch (Throwable $e) { return '—'; }
};
$baseQuery = array_filter([
    'q' => $filtros['q'] ?: null,
    'status' => $filtros['status'] ?: null,
    'role' => $filtros['role'] ?: null,
    'provider' => $filtros['provider'] ?: null,
    'de' => $filtros['de'] ?: null,
    'ate' => $filtros['ate'] ?: null,
    'sort' => $filtros['sort'] !== 'created' ? $filtros['sort'] : null,
    'dir' => $filtros['dir'] !== 'desc' ? $filtros['dir'] : null,
], static fn($v) => $v !== null);
$linkPagina = static fn(int $p) => '/admin/usuarios?' . http_build_query(array_merge($baseQuery, ['page' => $p]));
?>
<section class="hero-row compact-hero">
    <div>
        <span class="eyebrow">Administração</span>
        <h2 class="page-heading">Usuários</h2>
        <p class="page-subtitle"><?= (int) $total ?> conta(s) encontrada(s) · dados financeiros permanecem isolados por usuário.</p>
    </div>
    <div class="hero-actions">
        <a class="button button-secondary" href="/admin/usuarios/csv?<?= http_build_query($baseQuery) ?>">Exportar CSV</a>
        <a class="button button-ghost" href="/admin">Visão geral</a>
    </div>
</section>

<div class="admin-chips">
    <span class="chip">Ativos <b><?= (int) $resumo['ativos'] ?></b></span>
    <span class="chip">Inativos <b><?= (int) $resumo['inativos'] ?></b></span>
    <span class="chip">Google <b><?= (int) $resumo['google'] ?></b></span>
    <span class="chip">Microsoft <b><?= (int) $resumo['microsoft'] ?></b></span>
</div>

<form method="get" class="filter-card admin-filters">
    <label class="field field-search">
        <span>Buscar</span>
        <input type="search" name="q" value="<?= htmlspecialchars($filtros['q']) ?>" placeholder="Nome ou e-mail">
    </label>
    <label class="field">
        <span>Status</span>
        <select name="status">
            <option value="">Todos</option>
            <option value="active" <?= $filtros['status'] === 'active' ? 'selected' : '' ?>>Ativos</option>
            <option value="inactive" <?= $filtros['status'] === 'inactive' ? 'selected' : '' ?>>Inativos</option>
        </select>
    </label>
    <label class="field">
        <span>Perfil</span>
        <select name="role">
            <option value="">Todos</option>
            <?php foreach ($roles as $role): ?>
                <option value="<?= htmlspecialchars($role->slug) ?>" <?= $filtros['role'] === $role->slug ? 'selected' : '' ?>><?= htmlspecialchars($role->name) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <label class="field">
        <span>Origem</span>
        <select name="provider">
            <option value="">Todas</option>
            <option value="local" <?= $filtros['provider'] === 'local' ? 'selected' : '' ?>>E-mail e senha</option>
            <option value="google" <?= $filtros['provider'] === 'google' ? 'selected' : '' ?>>Google</option>
            <option value="microsoft" <?= $filtros['provider'] === 'microsoft' ? 'selected' : '' ?>>Microsoft</option>
        </select>
    </label>
    <label class="field">
        <span>Cadastro de</span>
        <input type="date" name="de" value="<?= htmlspecialchars($filtros['de']) ?>">
    </label>
    <label class="field">
        <span>até</span>
        <input type="date" name="ate" value="<?= htmlspecialchars($filtros['ate']) ?>">
    </label>
    <label class="field">
        <span>Ordenar</span>
        <select name="sort">
            <option value="created" <?= $filtros['sort'] === 'created' ? 'selected' : '' ?>>Data de cadastro</option>
            <option value="name" <?= $filtros['sort'] === 'name' ? 'selected' : '' ?>>Nome</option>
            <option value="last_login" <?= $filtros['sort'] === 'last_login' ? 'selected' : '' ?>>Último acesso</option>
        </select>
    </label>
    <label class="field">
        <span>Direção</span>
        <select name="dir">
            <option value="desc" <?= $filtros['dir'] === 'desc' ? 'selected' : '' ?>>Decrescente</option>
            <option value="asc" <?= $filtros['dir'] === 'asc' ? 'selected' : '' ?>>Crescente</option>
        </select>
    </label>
    <button class="button button-primary" type="submit">Filtrar</button>
</form>

<section class="panel">
    <div class="panel-heading">
        <div><span class="eyebrow">Contas de acesso</span><h3><?= count($usuarios) ?> nesta página</h3></div>
        <span class="muted-text">Página <?= (int) $page ?> de <?= (int) $pages ?></span>
    </div>

    <?php if (!$usuarios): ?>
        <div class="empty-state">
            <span class="empty-icon" aria-hidden="true">◎</span>
            <h3>Nenhum usuário encontrado</h3>
            <p>Ajuste os filtros ou limpe a busca para ver todas as contas.</p>
            <a class="button button-ghost" href="/admin/usuarios">Limpar filtros</a>
        </div>
    <?php else: ?>
        <div class="data-table-wrap">
            <table class="data-table admin-table">
                <thead>
                <tr>
                    <th>Usuário</th>
                    <th>Nascimento</th>
                    <th>Origem</th>
                    <th>Perfil</th>
                    <th>Status</th>
                    <th>Cadastro</th>
                    <th>Último acesso</th>
                    <th></th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ($usuarios as $u): ?>
                    <tr>
                        <td data-label="Usuário">
                            <div class="admin-user">
                                <?php if (!empty($u->avatar_url)): ?>
                                    <img src="<?= htmlspecialchars($u->avatar_url) ?>" alt="" width="34" height="34" referrerpolicy="no-referrer">
                                <?php else: ?>
                                    <span class="avatar avatar-sm"><?= htmlspecialchars(mb_strtoupper(mb_substr($u->name, 0, 1))) ?></span>
                                <?php endif; ?>
                                <span>
                                    <strong><?= htmlspecialchars($u->name) ?></strong>
                                    <small><?= htmlspecialchars($u->email) ?></small>
                                </span>
                            </div>
                        </td>
                        <td data-label="Nascimento">
                            <?= $u->birth_date ? date('d/m/Y', strtotime($u->birth_date)) : '—' ?>
                            <small class="muted-text"><?= $idade($u->birth_date) ?></small>
                        </td>
                        <td data-label="Origem"><span class="provider-tag provider-<?= htmlspecialchars($u->auth_provider) ?>"><?= htmlspecialchars($origemRotulo[$u->auth_provider] ?? $u->auth_provider) ?></span></td>
                        <td data-label="Perfil"><?= htmlspecialchars($u->role_name) ?></td>
                        <td data-label="Status"><span class="status-badge status-<?= $u->status === 'active' ? 'active' : 'inactive' ?>"><?= $u->status === 'active' ? 'Ativo' : 'Inativo' ?></span></td>
                        <td data-label="Cadastro"><?= date('d/m/Y', strtotime($u->created_at)) ?></td>
                        <td data-label="Último acesso"><?= $u->last_login_at ? date('d/m/Y H:i', strtotime($u->last_login_at)) : 'Nunca' ?></td>
                        <td class="row-actions"><a class="action-link" href="/admin/usuarios/<?= (int) $u->id ?>">Gerenciar</a></td>
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
