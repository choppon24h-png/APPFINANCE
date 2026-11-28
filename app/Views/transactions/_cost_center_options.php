<?php
/**
 * Opcoes de centro de custo agrupadas por tipo (imoveis primeiro).
 * Espera: $costCenters (lista), $selected (id atual), $emptyLabel (opcional).
 */
$selected = (int) ($selected ?? 0);
$emptyLabel = $emptyLabel ?? 'Sem centro de custo';
$grupos = ['property' => 'Imóveis', 'vehicle' => 'Veículos', 'company' => 'Empresas', 'project' => 'Projetos', 'general' => 'Outros'];
$porTipo = [];
foreach ($costCenters as $center) {
    $tipo = in_array($center->kind ?? 'general', array_keys($grupos), true) ? ($center->kind ?? 'general') : 'general';
    $porTipo[$tipo][] = $center;
}
?>
<option value=""><?= htmlspecialchars($emptyLabel) ?></option>
<?php foreach ($grupos as $tipo => $rotulo): ?>
    <?php if (empty($porTipo[$tipo])) continue; ?>
    <optgroup label="<?= htmlspecialchars($rotulo) ?>">
        <?php foreach ($porTipo[$tipo] as $center): ?>
            <option value="<?= (int) $center->id ?>" <?= $selected === (int) $center->id ? 'selected' : '' ?>><?= htmlspecialchars($center->name) ?><?= $tipo === 'property' && !empty($center->address) ? ' — ' . htmlspecialchars($center->address) : '' ?></option>
        <?php endforeach; ?>
    </optgroup>
<?php endforeach; ?>
