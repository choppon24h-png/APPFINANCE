<?php
/** Formas de pagamento: catálogo do sistema + formas próprias do usuário. */
$editing = !empty($editMethod);
$valor = static fn(string $key, mixed $default = '') => htmlspecialchars((string) ($editMethod->$key ?? $default));
$padrao = array_values(array_filter($methods, static fn($m) => $m->user_id === null));
$proprias = array_values(array_filter($methods, static fn($m) => $m->user_id !== null));
$icones = ['bank' => '🏦', 'card' => '💳', 'cash' => '💵', 'transfer' => '🔁', 'other' => '🏷️'];
?>
<section class="hero-row compact-hero">
    <div>
        <span class="eyebrow">Cadastros</span>
        <h2 class="page-heading">Formas de pagamento</h2>
        <p class="page-subtitle">Escolha como o dinheiro saiu ou entrou. As formas padrão já incluem <b>DÉBITO EM CONTA</b>; cadastre as suas quando precisar.</p>
    </div>
</section>

<div class="catalog-layout">
    <section class="panel">
        <div class="panel-heading">
            <div>
                <span class="eyebrow"><?= $editing ? 'Editar' : 'Nova' ?></span>
                <h3><?= $editing ? 'Atualizar forma de pagamento' : 'Adicionar forma de pagamento' ?></h3>
            </div>
        </div>
        <form method="post" action="<?= $editing ? '/formas-pagamento/' . (int) $editMethod->id . '/atualizar' : '/formas-pagamento' ?>" class="inline-form">
            <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">
            <label class="field">
                <span>Nome</span>
                <input type="text" name="name" value="<?= $valor('name') ?>" placeholder="Ex.: DÉBITO EM CONTA" maxlength="80" required autofocus>
                <small class="field-note">O nome aparece no lançamento. Use maiúsculas para manter o padrão.</small>
            </label>
            <label class="field">
                <span>Tipo</span>
                <select name="kind">
                    <?php foreach ($kinds as $chave => $rotulo): ?>
                        <option value="<?= $chave ?>" <?= ($editMethod->kind ?? 'other') === $chave ? 'selected' : '' ?>><?= $icones[$chave] ?? '' ?> <?= $rotulo ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="field">
                <span>Código interno <em>opcional</em></span>
                <input type="text" name="slug" value="<?= $valor('slug') ?>" placeholder="debito_conta" maxlength="40" pattern="[a-zA-Z0-9_\-]+">
                <small class="field-note">Se ficar vazio, o sistema cria a partir do nome. Não pode repetir.</small>
            </label>
            <label class="field">
                <span>Ordem <em>opcional</em></span>
                <input type="number" name="sort_order" value="<?= $valor('sort_order', '0') ?>" min="0" max="999" step="1">
            </label>
            <?php if ($editing): ?>
                <label class="field">
                    <span>Status</span>
                    <select name="status">
                        <option value="active" <?= ($editMethod->status ?? 'active') === 'active' ? 'selected' : '' ?>>Ativa</option>
                        <option value="inactive" <?= ($editMethod->status ?? '') === 'inactive' ? 'selected' : '' ?>>Inativa</option>
                    </select>
                </label>
            <?php endif; ?>
            <div class="form-actions">
                <button class="button button-primary" type="submit"><?= $editing ? 'Salvar' : 'Adicionar' ?></button>
                <?php if ($editing): ?><a class="button button-ghost" href="/formas-pagamento">Cancelar</a><?php endif; ?>
            </div>
        </form>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div>
                <span class="eyebrow">Disponíveis no lançamento</span>
                <h3><?= count($methods) ?> forma(s)</h3>
            </div>
        </div>

        <h4 class="center-group-title">Padrão do sistema</h4>
        <div class="catalog-list">
            <?php foreach ($padrao as $method): ?>
                <div class="catalog-item">
                    <span class="payment-icon"><?= $icones[$method->kind] ?? '🏷️' ?></span>
                    <div>
                        <strong><?= htmlspecialchars($method->name) ?></strong>
                        <small><?= htmlspecialchars($kinds[$method->kind] ?? 'Outro') ?> · <?= htmlspecialchars($method->slug) ?><?= $method->status === 'active' ? '' : ' · inativa' ?></small>
                    </div>
                    <span class="status-badge status-<?= $method->status ?>"><?= $method->status === 'active' ? 'Ativa' : 'Inativa' ?></span>
                </div>
            <?php endforeach; ?>
        </div>

        <h4 class="center-group-title">Minhas formas</h4>
        <div class="catalog-list">
            <?php if (!$proprias): ?><p class="empty-note">Nenhuma forma própria ainda. As padrão acima já podem ser usadas.</p><?php endif; ?>
            <?php foreach ($proprias as $method): ?>
                <div class="catalog-item">
                    <span class="payment-icon"><?= $icones[$method->kind] ?? '🏷️' ?></span>
                    <div>
                        <strong><?= htmlspecialchars($method->name) ?></strong>
                        <small><?= htmlspecialchars($kinds[$method->kind] ?? 'Outro') ?> · <?= htmlspecialchars($method->slug) ?></small>
                    </div>
                    <span class="status-badge status-<?= $method->status ?>"><?= $method->status === 'active' ? 'Ativa' : 'Inativa' ?></span>
                    <details class="action-menu">
                        <summary>•••</summary>
                        <div class="action-popover">
                            <a href="/formas-pagamento?edit=<?= (int) $method->id ?>">Editar</a>
                            <form method="post" action="/formas-pagamento/<?= (int) $method->id ?>/toggle"><input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"><button type="submit"><?= $method->status === 'active' ? 'Desativar' : 'Ativar' ?></button></form>
                            <form method="post" action="/formas-pagamento/<?= (int) $method->id ?>/excluir" data-confirm="Excluir esta forma de pagamento?"><input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"><button type="submit" class="danger-text">Excluir</button></form>
                        </div>
                    </details>
                </div>
            <?php endforeach; ?>
        </div>
    </section>
</div>
