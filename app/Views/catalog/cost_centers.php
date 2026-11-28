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
        <p class="page-subtitle">Digite o CEP para preencher o endereço automaticamente e cadastre o número de instalação/medidor para a leitura de contas reconhecer o imóvel sozinha. Use os outros tipos para carro, empresa ou projeto.</p>
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

            <div class="field field-wide address-block" data-address-field>
                <span>Endereço <em>opcional</em></span>
                <div class="cep-row">
                    <label class="field">
                        <span>CEP</span>
                        <div class="input-action">
                            <input type="text" name="zip_code" value="<?= $centerValue('zip_code') ?>" placeholder="00000-000" maxlength="9" inputmode="numeric" autocomplete="postal-code" data-cep-input>
                            <button class="button button-ghost button-small" type="button" data-cep-search>Buscar CEP</button>
                        </div>
                    </label>
                    <p class="field-note cep-status" data-cep-status>Digite o CEP e o endereço é preenchido por ViaCEP, BrasilAPI ou OpenCEP.</p>
                </div>
                <div class="form-grid address-grid">
                    <label class="field field-wide"><span>Rua / logradouro</span><input type="text" name="street" value="<?= $centerValue('street') ?>" placeholder="Rua, avenida, praça" maxlength="160" data-cep-street></label>
                    <label class="field"><span>Número</span><input type="text" name="address_number" value="<?= $centerValue('address_number') ?>" placeholder="123" maxlength="20" data-cep-number></label>
                    <label class="field"><span>Complemento</span><input type="text" name="complement" value="<?= $centerValue('complement') ?>" placeholder="Apto, bloco" maxlength="80" data-cep-complement></label>
                    <label class="field"><span>Bairro</span><input type="text" name="neighborhood" value="<?= $centerValue('neighborhood') ?>" maxlength="80" data-cep-neighborhood></label>
                    <label class="field"><span>Cidade</span><input type="text" name="city" value="<?= $centerValue('city') ?>" maxlength="80" data-cep-city></label>
                    <label class="field field-small"><span>UF</span><input type="text" name="state" value="<?= $centerValue('state') ?>" maxlength="2" placeholder="MG" data-cep-state></label>
                </div>
            </div>

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

            <input type="hidden" name="address" value="<?= $centerValue('address') ?>">
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
                var valor = tipo ? tipo.value : 'property';
                var temEndereco = valor === 'property' || valor === 'company';
                form.querySelectorAll('[data-address-field]').forEach(function (f) { f.hidden = !temEndereco; });
                form.querySelectorAll('[data-property-field]').forEach(function (f) { f.hidden = valor !== 'property'; });
            }
            form.querySelectorAll('[data-kind-option]').forEach(function (r) { r.addEventListener('change', atualizar); });
            atualizar();
        })();
        </script>
        <script src="/assets/js/cep.js" defer></script>
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
                        <?php if (!empty($center->address) || !empty($center->zip_code)): ?>
                            <p class="center-address"><?php if (!empty($center->zip_code)): ?><span class="doc-chip">CEP <?= htmlspecialchars($center->zip_code) ?></span> <?php endif; ?><?= htmlspecialchars($center->address ?? '') ?></p>
                        <?php endif; ?>
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
