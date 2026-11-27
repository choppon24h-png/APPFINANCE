<?php
use App\Core\Auth;

$origemRotulo = ['local' => 'E-mail e senha', 'google' => 'Google', 'microsoft' => 'Microsoft'];
$csrf     = $_SESSION['csrf_token'] ?? '';
$eu       = Auth::user();
$souEu    = (int) $eu->id === (int) $usuario->id;
$super    = Auth::isSuperAdmin();
$papel    = $usuario->role_slug ?? 'user';
$bloqueia = !$super && $papel === 'superadmin';
$temporaria = $_SESSION['_senha_temporaria'] ?? null;
if ($temporaria && (int) $temporaria['user_id'] !== (int) $usuario->id) {
    $temporaria = null;
}
unset($_SESSION['_senha_temporaria']);
?>
<section class="hero-row compact-hero">
    <div>
        <span class="eyebrow"><a class="text-link" href="/admin/usuarios">← Usuários</a></span>
        <h2 class="page-heading"><?= htmlspecialchars($usuario->name) ?></h2>
        <p class="page-subtitle"><?= htmlspecialchars($usuario->email) ?> · cadastrado em <?= date('d/m/Y', strtotime($usuario->created_at)) ?></p>
    </div>
    <div class="hero-actions">
        <span class="status-badge status-<?= $usuario->status === 'active' ? 'active' : 'inactive' ?>"><?= $usuario->status === 'active' ? 'Ativo' : 'Inativo' ?></span>
        <a class="button button-ghost" href="/admin/usuarios">Voltar</a>
    </div>
</section>

<?php if ($temporaria): ?>
    <div class="temp-password" role="status">
        <span class="eyebrow">Senha temporária — exibida uma única vez</span>
        <strong><?= htmlspecialchars($temporaria['senha']) ?></strong>
        <p>Repasse para <b><?= htmlspecialchars($temporaria['nome']) ?></b> por um canal seguro. Ao sair desta tela ela não poderá ser consultada novamente.</p>
    </div>
<?php endif; ?>

<div class="dashboard-grid admin-grid">
    <section class="panel">
        <div class="panel-heading"><div><span class="eyebrow">Conta</span><h3>Dados do usuário</h3></div></div>
        <dl class="admin-dl">
            <div><dt>Nome</dt><dd><?= htmlspecialchars($usuario->name) ?></dd></div>
            <div><dt>E-mail</dt><dd><?= htmlspecialchars($usuario->email) ?> <?= $usuario->email_verified_at ? '<span class="badge-soft">verificado</span>' : '<span class="badge-soft muted">não verificado</span>' ?></dd></div>
            <div><dt>Nascimento</dt><dd><?= $usuario->birth_date ? date('d/m/Y', strtotime($usuario->birth_date)) . ' · ' . (int) $idade . ' anos' : 'Não informado' ?></dd></div>
            <div><dt>Origem</dt><dd><?= htmlspecialchars($origemRotulo[$usuario->auth_provider] ?? $usuario->auth_provider) ?></dd></div>
            <div><dt>Perfil</dt><dd><?= htmlspecialchars($usuario->role_name) ?></dd></div>
            <div><dt>Status</dt><dd><?= $usuario->status === 'active' ? 'Ativo' : 'Inativo' ?></dd></div>
            <div><dt>Cadastro</dt><dd><?= date('d/m/Y H:i', strtotime($usuario->created_at)) ?></dd></div>
            <div><dt>Último acesso</dt><dd><?= $usuario->last_login_at ? date('d/m/Y H:i', strtotime($usuario->last_login_at)) : 'Nunca' ?></dd></div>
            <div><dt>IP do cadastro</dt><dd><?= htmlspecialchars($usuario->registration_ip ?? '—') ?></dd></div>
            <div><dt>Termos aceitos</dt><dd><?= $usuario->terms_accepted_at ? date('d/m/Y H:i', strtotime($usuario->terms_accepted_at)) : 'Pendente' ?></dd></div>
            <div><dt>Falhas de login (30d)</dt><dd><?= (int) $falhas ?></dd></div>
        </dl>
    </section>

    <section class="panel">
        <div class="panel-heading"><div><span class="eyebrow">Editar</span><h3>Nome, perfil e status</h3></div></div>

        <?php if ($bloqueia): ?>
            <div class="auth-alert warning"><span aria-hidden="true">!</span><span>Somente o superadministrador pode alterar uma conta de superadministrador.</span></div>
        <?php endif; ?>

        <form method="post" action="/admin/usuarios/<?= (int) $usuario->id ?>/atualizar" class="form-grid admin-form" data-confirm="Salvar alterações deste usuário?">
            <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">
            <label class="field field-wide">
                <span>Nome completo</span>
                <input type="text" name="name" value="<?= htmlspecialchars($usuario->name) ?>" minlength="3" maxlength="120" required <?= $bloqueia ? 'disabled' : '' ?>>
            </label>
            <label class="field">
                <span>Perfil</span>
                <select name="role_id" <?= $bloqueia || $souEu ? 'disabled' : '' ?>>
                    <?php foreach ($roles as $role): ?>
                        <?php $opcaoAdmin = in_array($role->slug, ['admin', 'superadmin'], true); ?>
                        <option value="<?= (int) $role->id ?>"
                            <?= (int) $usuario->role_id === (int) $role->id ? 'selected' : '' ?>
                            <?= (!$super && $opcaoAdmin) ? 'disabled' : '' ?>>
                            <?= htmlspecialchars($role->name) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
                <?php if ($souEu): ?><small class="field-hint">Você não pode alterar o próprio perfil.</small><?php endif; ?>
            </label>
            <label class="field">
                <span>Status</span>
                <select name="status" <?= $bloqueia || $souEu ? 'disabled' : '' ?>>
                    <option value="active" <?= $usuario->status === 'active' ? 'selected' : '' ?>>Ativo</option>
                    <option value="inactive" <?= $usuario->status === 'inactive' ? 'selected' : '' ?>>Inativo</option>
                </select>
            </label>
            <div class="form-actions field-wide">
                <button type="submit" class="button button-primary" <?= $bloqueia ? 'disabled' : '' ?>>Salvar alterações</button>
            </div>
        </form>
    </section>
</div>

<div class="dashboard-grid admin-grid">
    <section class="panel">
        <div class="panel-heading"><div><span class="eyebrow">Segurança</span><h3>Ações da conta</h3></div></div>

        <?php if (!$souEu && !$bloqueia): ?>
            <form method="post" action="/admin/usuarios/<?= (int) $usuario->id ?>/toggle" data-confirm="<?= $usuario->status === 'active' ? 'Desativar este usuário? Ele perderá o acesso imediatamente.' : 'Reativar este usuário?' ?>">
                <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                <button type="submit" class="button <?= $usuario->status === 'active' ? 'button-danger' : 'button-secondary' ?>">
                    <?= $usuario->status === 'active' ? 'Desativar acesso' : 'Reativar acesso' ?>
                </button>
            </form>
        <?php else: ?>
            <p class="muted-text"><?= $souEu ? 'Você não pode desativar a própria conta.' : 'Ação indisponível para este perfil.' ?></p>
        <?php endif; ?>

        <?php if (!$bloqueia): ?>
            <form method="post" action="/admin/usuarios/<?= (int) $usuario->id ?>/senha" class="admin-action-form" data-confirm="Gerar uma senha temporária para <?= htmlspecialchars($usuario->name) ?>? A senha atual deixará de funcionar.">
                <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($csrf) ?>">
                <button type="submit" class="button button-ghost">Redefinir senha (temporária)</button>
            </form>
            <p class="field-hint">A senha temporária aparece uma única vez nesta tela. Nenhum e-mail é enviado.</p>
        <?php endif; ?>
    </section>

    <section class="panel">
        <div class="panel-heading"><div><span class="eyebrow">OAuth</span><h3>Contas vinculadas</h3></div></div>
        <?php if (!$identidades): ?>
            <div class="empty-state compact"><p>Nenhuma conta Google/Microsoft vinculada.</p></div>
        <?php else: ?>
            <ul class="admin-list">
                <?php foreach ($identidades as $identidade): ?>
                    <li>
                        <span class="provider-tag provider-<?= htmlspecialchars($identidade->provider) ?>"><?= htmlspecialchars(ucfirst($identidade->provider)) ?></span>
                        <span class="admin-list-main">
                            <strong><?= htmlspecialchars($identidade->email ?? '—') ?></strong>
                            <small>vínculo desde <?= date('d/m/Y', strtotime($identidade->created_at)) ?></small>
                        </span>
                    </li>
                <?php endforeach; ?>
            </ul>
        <?php endif; ?>
    </section>
</div>

<section class="panel">
    <div class="panel-heading">
        <div><span class="eyebrow">Auditoria</span><h3>Histórico deste usuário</h3></div>
        <a class="text-link" href="/admin/auditoria?usuario=<?= (int) $usuario->id ?>">Filtrar na auditoria</a>
    </div>
    <?php if (!$acoes): ?>
        <div class="empty-state compact"><p>Nenhuma ação registrada para este usuário.</p></div>
    <?php else: ?>
        <div class="data-table-wrap">
            <table class="data-table">
                <thead><tr><th>Quando</th><th>Ação</th><th>Entidade</th><th>Detalhes</th><th>IP</th></tr></thead>
                <tbody>
                <?php foreach ($acoes as $acao): ?>
                    <tr>
                        <td data-label="Quando"><?= date('d/m/Y H:i', strtotime($acao->created_at)) ?></td>
                        <td data-label="Ação"><span class="audit-action"><?= htmlspecialchars($acao->action) ?></span></td>
                        <td data-label="Entidade"><?= htmlspecialchars($acao->entity ?? '—') ?></td>
                        <td data-label="Detalhes"><small class="muted-text"><?= htmlspecialchars(\App\Support\AuditDetails::text($acao->details ?? null, 90)) ?></small></td>
                        <td data-label="IP"><?= htmlspecialchars($acao->ip ?? '—') ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</section>
