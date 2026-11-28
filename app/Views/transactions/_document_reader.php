<?php
/** Card de leitura de boleto/conta/cupom. O OCR roda no navegador (documents.js). */
$maxMb = (int) ($_ENV['ATTACHMENT_MAX_MB'] ?? 10);
?>
<section class="doc-reader" data-doc-reader
         data-read-url="/lancamentos/ler-documento"
         data-csrf="<?= htmlspecialchars($_SESSION['csrf_token'] ?? '') ?>"
         data-max-mb="<?= $maxMb ?>">
    <div class="doc-reader-head">
        <div>
            <span class="eyebrow">Leitura automática</span>
            <h3>Ler boleto, conta ou cupom</h3>
            <p class="field-note">Foto, PDF ou código digitado. O texto é lido no seu navegador; o arquivo só é enviado se você anexar ao lançamento.</p>
        </div>
        <span class="doc-reader-badge" aria-hidden="true">📄</span>
    </div>

    <div class="doc-actions">
        <button type="button" class="button button-primary" data-doc-pick>Escolher arquivo</button>
        <button type="button" class="button button-ghost" data-doc-camera>Usar câmera</button>
        <button type="button" class="button button-ghost" data-doc-code-toggle>Digitar código</button>
    </div>

    <input type="file" accept="image/*,application/pdf" data-doc-file hidden>
    <input type="file" accept="image/*" capture="environment" data-doc-camera-file hidden>

    <div class="doc-drop" data-doc-drop tabindex="0" role="button" aria-label="Arraste um arquivo ou toque para escolher">
        <strong>Arraste o arquivo aqui</strong>
        <span>PDF, JPG, PNG ou WEBP — até <?= $maxMb ?> MB</span>
    </div>

    <div class="doc-code" data-doc-code-box hidden>
        <label class="field">
            <span>Linha digitável, código de barras ou chave da NFC-e</span>
            <input type="text" inputmode="numeric" autocomplete="off" placeholder="47, 48 ou 44 dígitos" data-doc-code>
        </label>
        <button type="button" class="button button-primary" data-doc-code-send>Usar este código</button>
    </div>

    <div class="doc-status" data-doc-status hidden>
        <div class="doc-status-text" data-doc-status-text>Preparando leitura…</div>
        <div class="progress-track is-brand"><span class="progress-bar" data-doc-progress style="width:0%"></span></div>
    </div>

    <div class="doc-result" data-doc-result hidden></div>

    <details class="doc-help">
        <summary>O que é lido automaticamente?</summary>
        <ul>
            <li><b>Boleto bancário:</b> linha digitável de 47 dígitos ou código de barras de 44 — valor e vencimento saem do próprio código.</li>
            <li><b>Conta de consumo (água, luz, telefone, IPTU):</b> linha de 48 dígitos começando com 8; valor e segmento vêm do código.</li>
            <li><b>Cupom fiscal (NFC-e):</b> chave de 44 dígitos (ou QR Code) e valor total impresso.</li>
            <li><b>Imóvel:</b> se o número de instalação/medidor estiver cadastrado no imóvel, ele já vem selecionado.</li>
        </ul>
    </details>
</section>
<script src="/assets/js/documents.js?v=1" defer></script>
