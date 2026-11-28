<?php
/** Lancamento em lote (OFX/CSV). A grade e montada por import.js. */
$opcoes = [
    'categories' => array_map(static fn($c) => ['id' => (int) $c->id, 'name' => $c->name], $categories),
    'costCenters' => array_map(static fn($c) => ['id' => (int) $c->id, 'name' => $c->name, 'kind' => $c->kind ?? 'general'], $costCenters),
];
?>
<section class="form-intro">
    <a class="back-link" href="/lancamentos">‹ Voltar para lançamentos</a>
    <span class="eyebrow">Importação</span>
    <h2 class="page-heading">Lançar em lote</h2>
    <p class="page-subtitle">Suba o extrato do banco (OFX ou CSV), revise as linhas e confirme. O que já foi importado é ignorado automaticamente.</p>
</section>

<div class="import-card" data-import
     data-preview-url="/lancamentos/importar/extrato"
     data-confirm-url="/lancamentos/importar/confirmar"
     data-csrf="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>">

    <form class="form-grid" data-import-form>
        <label class="field">
            <span>Conta de destino</span>
            <select name="account_id" required>
                <option value="">Selecione a conta</option>
                <?php foreach ($accounts as $account): ?>
                    <option value="<?= (int) $account->id ?>"><?= htmlspecialchars($account->name) ?></option>
                <?php endforeach; ?>
            </select>
            <small class="field-note">Os lançamentos entram nesta conta e afetam o saldo.</small>
        </label>

        <label class="field">
            <span>Arquivo OFX ou CSV</span>
            <input type="file" name="file" accept=".ofx,.csv,.txt,text/csv,application/x-ofx" data-import-file>
            <small class="field-note">OFX do internet banking ou CSV com data, descrição e valor (até 8 MB).</small>
        </label>

        <details class="field field-wide import-paste">
            <summary>Colar o conteúdo do arquivo</summary>
            <textarea rows="5" data-import-content placeholder="Data;Descrição;Valor&#10;05/11/2026;Conta de luz;-157,90"></textarea>
        </details>

        <div class="form-actions">
            <button type="submit" class="button button-primary" data-import-preview>Ler extrato</button>
        </div>
    </form>

    <div class="doc-status" data-import-status hidden>
        <div class="doc-status-text" data-import-status-text>Lendo extrato…</div>
        <div class="progress-track is-brand"><span class="progress-bar" data-import-progress style="width:0%"></span></div>
    </div>

    <div class="import-summary" data-import-summary hidden></div>

    <div class="import-grid-wrap" data-import-grid-wrap hidden>
        <div class="import-grid-head">
            <div>
                <h3>Revise antes de salvar</h3>
                <p class="field-note" data-import-count></p>
            </div>
            <div class="import-grid-actions">
                <button type="button" class="button button-ghost button-small" data-import-toggle-all>Marcar/desmarcar tudo</button>
                <button type="button" class="button button-primary" data-import-confirm>Importar selecionados</button>
            </div>
        </div>
        <div class="import-grid-scroll">
            <table class="import-grid">
                <thead>
                    <tr>
                        <th><span class="sr-only">Incluir</span></th>
                        <th>Data</th>
                        <th>Descrição</th>
                        <th>Valor</th>
                        <th>Tipo</th>
                        <th>Categoria</th>
                        <th>Imóvel / centro</th>
                        <th>Situação</th>
                    </tr>
                </thead>
                <tbody data-import-rows></tbody>
            </table>
        </div>
    </div>

    <div class="doc-result" data-import-result hidden></div>
</div>

<script type="application/json" id="import-options"><?= json_encode($opcoes, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?></script>
<script src="/assets/js/import.js?v=1" defer></script>
