<?php
/** Catálogo de tipos de investimento (CDB, Tesouro, CDI...). */
$editing = !empty($editType);
$valor = static fn(string $key, mixed $default = '') => htmlspecialchars((string) ($editType->$key ?? $default));
$padrao = array_values(array_filter($types, static fn($t) => $t->user_id === null));
$proprios = array_values(array_filter($types, static fn($t) => $t->user_id !== null));
?>
<section class="hero-row compact-hero">
    <div>
        <span class="eyebrow">Investimentos</span>
        <h2 class="page-heading">Tipos de investimento</h2>
        <p class="page-subtitle">O tipo define o índice usado na estimativa de rendimento (CDI, Selic, IPCA ou prefixado). Ajuste a taxa de referência no lançamento.</p>
    </div>
    <div class="hero-actions"><a class="button button-ghost" href="/investimentos">‹ Carteira</a></div>
</section>

<div class="catalog-layout">
    <section class="panel">
        <div class="panel-heading">
            <div>
                <span class="eyebrow"><?= $editing ? 'Editar' : 'Novo' ?></span>
                <h3><?= $editing ? 'Atualizar tipo' : 'Adicionar tipo de investimento' ?></h3>
            </div>
        </div>
        <form method="post" action="<?= $editing ? '/investimentos/tipos/' . (int) $editType->id . '/atualizar' : '/investimentos/tipos' ?>" class="inline-form">
            <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">
            <label class="field"><span>Nome</span><input type="text" name="name" value="<?= $valor('name') ?>" placeholder="Ex.: CDB" maxlength="80" required autofocus></label>
            <label class="field">
                <span>Índice de referência</span>
                <select name="benchmark">
                    <?php foreach ($benchmarks as $chave => $rotulo): ?>
                        <option value="<?= $chave ?>" <?= ($editType->benchmark ?? 'none') === $chave ? 'selected' : '' ?>><?= $rotulo ?><?= isset($referenceRates[$chave]) && $referenceRates[$chave] > 0 ? ' (' . number_format($referenceRates[$chave], 2, ',', '.') . '% a.a.)' : '' ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="field">
                <span>Taxa sugerida <em>opcional</em></span>
                <div class="input-suffix"><input type="number" name="default_rate" value="<?= $valor('default_rate') ?>" step="0.000001" min="0" placeholder="Ex.: 110"><b>%</b></div>
                <small class="field-note">Para CDB/LCI é o percentual do índice; para prefixado é a taxa cheia.</small>
            </label>
            <label class="field">
                <span>Periodicidade da taxa</span>
                <select name="default_rate_period">
                    <option value="annual" <?= ($editType->default_rate_period ?? 'annual') === 'annual' ? 'selected' : '' ?>>Ao ano</option>
                    <option value="monthly" <?= ($editType->default_rate_period ?? '') === 'monthly' ? 'selected' : '' ?>>Ao mês</option>
                </select>
            </label>
            <label class="field">
                <span>Código interno <em>opcional</em></span>
                <input type="text" name="slug" value="<?= $valor('slug') ?>" placeholder="cdb" maxlength="40" pattern="[a-zA-Z0-9_\-]+">
            </label>
            <?php if ($editing): ?>
                <label class="field"><span>Status</span>
                    <select name="status">
                        <option value="active" <?= ($editType->status ?? 'active') === 'active' ? 'selected' : '' ?>>Ativo</option>
                        <option value="inactive" <?= ($editType->status ?? '') === 'inactive' ? 'selected' : '' ?>>Inativo</option>
                    </select>
                </label>
            <?php endif; ?>
            <div class="form-actions">
                <button class="button button-primary" type="submit"><?= $editing ? 'Salvar' : 'Adicionar' ?></button>
                <?php if ($editing): ?><a class="button button-ghost" href="/investimentos/tipos">Cancelar</a><?php endif; ?>
            </div>
        </form>
    </section>

    <section class="panel">
        <div class="panel-heading"><div><span class="eyebrow">Catálogo</span><h3><?= count($types) ?> tipo(s)</h3></div></div>
        <h4 class="center-group-title">Padrão do sistema</h4>
        <div class="catalog-list">
            <?php foreach ($padrao as $type): ?>
                <div class="catalog-item">
                    <span class="category-dot center-dot"></span>
                    <div>
                        <strong><?= htmlspecialchars($type->name) ?></strong>
                        <small><?= htmlspecialchars($benchmarks[$type->benchmark] ?? 'Sem índice') ?><?= $type->default_rate !== null ? ' · ' . rtrim(rtrim(number_format((float) $type->default_rate, 4, ',', '.'), '0'), ',') . '% ' . ($type->default_rate_period === 'monthly' ? 'ao mês' : 'ao ano') : '' ?></small>
                    </div>
                    <span class="status-badge status-<?= $type->status ?>"><?= $type->status === 'active' ? 'Ativo' : 'Inativo' ?></span>
                </div>
            <?php endforeach; ?>
        </div>
        <h4 class="center-group-title">Meus tipos</h4>
        <div class="catalog-list">
            <?php if (!$proprios): ?><p class="empty-note">Nenhum tipo próprio ainda.</p><?php endif; ?>
            <?php foreach ($proprios as $type): ?>
                <div class="catalog-item">
                    <span class="category-dot center-dot"></span>
                    <div>
                        <strong><?= htmlspecialchars($type->name) ?></strong>
                        <small><?= htmlspecialchars($benchmarks[$type->benchmark] ?? 'Sem índice') ?><?= $type->default_rate !== null ? ' · ' . rtrim(rtrim(number_format((float) $type->default_rate, 4, ',', '.'), '0'), ',') . '% ' . ($type->default_rate_period === 'monthly' ? 'ao mês' : 'ao ano') : '' ?></small>
                    </div>
                    <span class="status-badge status-<?= $type->status ?>"><?= $type->status === 'active' ? 'Ativo' : 'Inativo' ?></span>
                    <details class="action-menu">
                        <summary>•••</summary>
                        <div class="action-popover">
                            <a href="/investimentos/tipos?edit=<?= (int) $type->id ?>">Editar</a>
                            <form method="post" action="/investimentos/tipos/<?= (int) $type->id ?>/toggle"><input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"><button type="submit"><?= $type->status === 'active' ? 'Desativar' : 'Ativar' ?></button></form>
                            <form method="post" action="/investimentos/tipos/<?= (int) $type->id ?>/excluir" data-confirm="Excluir este tipo?"><input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"><button type="submit" class="danger-text">Excluir</button></form>
                        </div>
                    </details>
                </div>
            <?php endforeach; ?>
        </div>
    </section>
</div>
