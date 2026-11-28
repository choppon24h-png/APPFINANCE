<?php
/** Imóveis e centros de custo. */
$editing = !empty($editCenter);
$centerValue = static fn(string $key, mixed $default = '') => htmlspecialchars((string) ($editCenter->$key ?? $default));
$kindAtual = $editCenter->kind ?? 'property';
$tipos = [
    'property' => ['Imóvel', '🏠'],
    'vehicle' => ['Veículo', '🚗'],
    'company' => ['Empresa', '🏢'],
    'project' => ['Projeto', '📁'],
    'general' => ['Outro', '🏷️'],
];
$imoveis = array_values(array_filter($costCenters, static fn($c) => ($c->kind ?? 'general') === 'property'));
$outros = array_values(array_filter($costCenters, static fn($c) => ($c->kind ?? 'general') !== 'property'));
$totalMes = array_sum($totais ?? []);
$mes = $mesReferencia ?? date('m/Y');
?>
<section class="hero-row compact-hero">
    <div>
        <span class="eyebrow">Organização</span>
        <h2 class="page-heading">Imóveis e centros de custo</h2>
        <p class="page-subtitle">Cadastre cada imóvel com o número de instalação/medidor para a leitura de contas reconhecer sozinha. Use os outros tipos para carro, empresa ou projeto.</p>
    </div>
</section>

<div class="catalog-layout">
    <section class="panel">
        <div class="panel-heading">
            <div>
                <span class="eyebrow"><?= $editing ? 'Editar' : 'Novo' ?></span>
                <h3><?= $editing ? 'Atualizar cadastro' : 'Adicionar imóvel ou centro' ?></h3>
            </div>
        </div>
        <form method="post" action="<?= $editing ? '/centros-custo/' . (int) $editCenter->id . '/atualizar' : '/centros-custo' ?>" class="inline-form" data-center-form>
            <input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">

            <div class="field field-wide">
                <span>Tipo</span>
                <div class="kind-pills" role="radiogroup" aria-label="Tipo de centro de custo">
                    <?php foreach ($tipos as $chave => [$rotulo, $icone]): ?>
                        <label class="kind-pill">
                            <input type="radio" name="kind" value="<?= $chave ?>" <?= $kindAtual === $chave ? 'checked' : '' ?> data-kind-option>
                            <span><?= $icone ?> <?= $rotulo ?></span>
                        </label>
                    <?php endforeach; ?>
                </div>
            </div>

            <label class="field"><span>Nome</span><input type="text" name="name" value="<?= $centerValue('name') ?>" placeholder="Ex.: Apartamento Centro" maxlength="120" required></label>
            <label class="field"><span>Código <em>opcional</em></span><input type="text" name="code" value="<?= $centerValue('code') ?>" placeholder="Ex.: APTO" maxlength="40"></label>

            <label class="field field-wide" data-property-field>
                <span>Endereço do imóvel <em>opcional</em></span>
                <input type="text" name="address" value="<?= $centerValue('address') ?>" placeholder="Rua, número, bairro, cidade" maxlength="255">
            </label>

            <label class="field field-wide" data-property-field>
                <span>Números que identificam o imóvel <em>opcional</em></span>
                <input type="text" name="identifiers" value="<?= $centerValue('identifiers') ?>" placeholder="Ex.: 99887766, 123456789 (instalação, medidor, matrícula)" maxlength="500">
                <small class="field-note">Separe por vírgula. Ao ler uma conta de luz/água, o sistema procura esses números no documento e já seleciona o imóvel.</small>
            </label>

            <label class="field field-wide"><span>Descrição <em>opcional</em></span><input type="text" name="description" value="<?= $centerValue('description') ?>" maxlength="255"></label>

            <?php if ($editing): ?>
                <label class="field"><span>Status</span>
                    <select name="status">
                        <option value="active" <?= ($editCenter->status ?? 'active') === 'active' ? 'selected' : '' ?>>Ativo</option>
                        <option value="inactive" <?= ($editCenter->status ?? '') === 'inactive' ? 'selected' : '' ?>>Inativo</option>
                    </select>
                </label>
            <?php endif; ?>

            <div class="form-actions">
                <button class="button button-primary" type="submit"><?= $editing ? 'Salvar' : 'Adicionar' ?></button>
                <?php if ($editing): ?><a class="button button-ghost" href="/centros-custo">Cancelar</a><?php endif; ?>
            </div>
        </form>
        <script>
        (function () {
            var form = document.querySelector('[data-center-form]');
            if (!form) return;
            function atualizar() {
                var tipo = form.querySelector('[data-kind-option]:checked');
                var imovel = tipo && tipo.value === 'property';
                form.querySelectorAll('[data-property-field]').forEach(function (f) { f.hidden = !imovel; });
            }
            form.querySelectorAll('[data-kind-option]').forEach(function (r) { r.addEventListener('change', atualizar); });
            atualizar();
        })();
        </script>
    </section>

    <section class="panel">
        <div class="panel-heading">
            <div>
                <span class="eyebrow">Seus cadastros</span>
                <h3><?= count($costCenters) ?> centro(s)</h3>
                <p class="field-note">Despesas do mês: <b>R$ <?= number_format($totalMes, 2, ',', '.') ?></b> · <?= htmlspecialchars($mes) ?></p>
            </div>
        </div>

        <div class="kind-filters">
            <a class="kind-filter <?= ($tipo ?? '') === '' ? 'active' : '' ?>" href="/centros-custo">Todos</a>
            <?php foreach ($tipos as $chave => [$rotulo, $icone]): ?>
                <a class="kind-filter <?= ($tipo ?? '') === $chave ? 'active' : '' ?>" href="/centros-custo?tipo=<?= $chave ?>"><?= $icone ?> <?= $rotulo ?>s</a>
            <?php endforeach; ?>
        </div>

        <?php if ($imoveis): ?>
            <h4 class="center-group-title">Imóveis</h4>
            <div class="center-cards">
                <?php foreach ($imoveis as $center): ?>
                    <article class="center-card">
                        <header>
                            <strong><?= htmlspecialchars($center->name) ?></strong>
                            <span class="status-badge status-<?= $center->status ?>"><?= $center->status === 'active' ? 'Ativo' : 'Inativo' ?></span>
                        </header>
                        <?php if (!empty($center->address)): ?><p class="center-address"><?= htmlspecialchars($center->address) ?></p><?php endif; ?>
                        <?php if (!empty($center->identifiers)): ?>
                            <p class="center-ids"><?php foreach (array_filter(array_map('trim', explode(',', $center->identifiers))) as $id): ?><span class="doc-chip"><?= htmlspecialchars($id) ?></span><?php endforeach; ?></p>
                        <?php endif; ?>
                        <p class="center-total">R$ <?= number_format((float) ($totais[(int) $center->id] ?? 0), 2, ',', '.') ?> <small>no mês</small></p>
                        <footer>
                            <a class="button button-ghost button-small" href="/lancamentos?cost_center_id=<?= (int) $center->id ?>&date_from=<?= date('Y-m-01') ?>&date_to=<?= date('Y-m-t') ?>">Ver gastos</a>
                            <?php if ($center->user_id !== null): ?>
                                <a class="button button-ghost button-small" href="/centros-custo?edit=<?= (int) $center->id ?>">Editar</a>
                                <form method="post" action="/centros-custo/<?= (int) $center->id ?>/toggle"><input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"><button class="button button-ghost button-small" type="submit"><?= $center->status === 'active' ? 'Desativar' : 'Ativar' ?></button></form>
                            <?php endif; ?>
                        </footer>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>

        <h4 class="center-group-title">Outros centros</h4>
        <div class="catalog-list">
            <?php if (!$outros): ?><p class="empty-note">Nenhum centro deste tipo ainda.</p><?php endif; ?>
            <?php foreach ($outros as $center): ?>
                <div class="catalog-item">
                    <span class="category-dot center-dot"></span>
                    <div>
                        <strong><?= htmlspecialchars($center->name) ?></strong>
                        <small><?= htmlspecialchars(($tipos[$center->kind ?? 'general'][0] ?? 'Outro')) ?><?= $center->code ? ' · ' . htmlspecialchars($center->code) : '' ?><?= $center->user_id === null ? ' · padrão' : '' ?> · R$ <?= number_format((float) ($totais[(int) $center->id] ?? 0), 2, ',', '.') ?> no mês</small>
                    </div>
                    <span class="status-badge status-<?= $center->status ?>"><?= $center->status === 'active' ? 'Ativo' : 'Inativo' ?></span>
                    <?php if ($center->user_id !== null): ?>
                        <details class="action-menu">
                            <summary>•••</summary>
                            <div class="action-popover">
                                <a href="/centros-custo?edit=<?= (int) $center->id ?>">Editar</a>
                                <form method="post" action="/centros-custo/<?= (int) $center->id ?>/toggle"><input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"><button type="submit"><?= $center->status === 'active' ? 'Desativar' : 'Ativar' ?></button></form>
                                <form method="post" action="/centros-custo/<?= (int) $center->id ?>/excluir" data-confirm="Excluir este centro de custo?"><input type="hidden" name="_csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"><button type="submit" class="danger-text">Excluir</button></form>
                            </div>
                        </details>
                    <?php endif; ?>
                </div>
            <?php endforeach; ?>
        </div>
    </section>
</div>
