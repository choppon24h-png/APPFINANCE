<?php
/** Anexo do lancamento (PDF/imagem). Guardado fora de public/ e servido por rota autenticada. */
$maxMb = (int) ($_ENV['ATTACHMENT_MAX_MB'] ?? 10);
$anexo = $editing ? (string) ($transaction->attachment_path ?? '') : '';
?>
<div class="attachment-field">
    <label class="field">
        <span>Anexo <em>opcional</em></span>
        <input type="file" name="attachment" accept="application/pdf,image/jpeg,image/png,image/webp,image/heic">
        <small class="field-note">PDF ou foto do comprovante, até <?= $maxMb ?> MB. Fica privado: só você acessa.</small>
    </label>
    <?php if ($anexo !== ''): ?>
        <div class="attachment-current">
            <span>📎 <a href="/lancamentos/<?= (int) $transaction->id ?>/anexo" target="_blank" rel="noopener">Ver anexo atual</a></span>
            <label class="check-inline"><input type="checkbox" name="remove_attachment" value="1"> Remover anexo</label>
        </div>
    <?php endif; ?>
</div>
