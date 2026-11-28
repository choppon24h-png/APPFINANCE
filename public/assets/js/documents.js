/**
 * Leitura de boletos, contas e cupons no navegador.
 *
 * - PDF: texto das 3 primeiras paginas (pdf.js); se vier pouco texto,
 *   renderiza a pagina 1 e tenta codigo de barras + OCR.
 * - Imagem: reduz para no maximo 2400 px, le QR/ITF com ZXing e depois OCR.
 * - Bibliotecas so sao baixadas quando o usuario escolhe um arquivo.
 * - O texto/codigo vai para POST /lancamentos/ler-documento (PHP).
 */
(function () {
    'use strict';

    var root = document.querySelector('[data-doc-reader]');
    if (!root) return;

    var form = root.closest('form');
    var readUrl = root.dataset.readUrl || '/lancamentos/ler-documento';
    var csrf = root.dataset.csrf || '';
    var maxMb = parseInt(root.dataset.maxMb || '10', 10);

    var fileInput = root.querySelector('[data-doc-file]');
    var cameraInput = root.querySelector('[data-doc-camera-file]');
    var drop = root.querySelector('[data-doc-drop]');
    var statusBox = root.querySelector('[data-doc-status]');
    var statusText = root.querySelector('[data-doc-status-text]');
    var progress = root.querySelector('[data-doc-progress]');
    var resultBox = root.querySelector('[data-doc-result]');
    var codeBox = root.querySelector('[data-doc-code-box]');
    var codeInput = root.querySelector('[data-doc-code]');
    var pendingFile = null;
    var busy = false;

    var CDN = {
        pdf: 'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.min.js',
        pdfWorker: 'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js',
        zxing: 'https://cdn.jsdelivr.net/npm/@zxing/library@0.23.0/umd/index.min.js',
        tesseract: 'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js'
    };

    function loadScript(url, globalName) {
        if (globalName && window[globalName]) return Promise.resolve(window[globalName]);
        return new Promise(function (resolve, reject) {
            var existing = document.querySelector('script[src="' + url + '"]');
            if (existing) {
                existing.addEventListener('load', function () { resolve(window[globalName]); });
                existing.addEventListener('error', reject);
                return;
            }
            var s = document.createElement('script');
            s.src = url;
            s.async = true;
            s.onload = function () { resolve(globalName ? window[globalName] : true); };
            s.onerror = function () { reject(new Error('Falha ao carregar ' + url)); };
            document.head.appendChild(s);
        });
    }

    function setStatus(text, pct) {
        statusBox.hidden = false;
        statusText.textContent = text;
        progress.style.width = Math.max(0, Math.min(100, pct || 0)) + '%';
    }

    function hideStatus() {
        window.setTimeout(function () { statusBox.hidden = true; }, 600);
    }

    function chip(text, type) {
        var span = document.createElement('span');
        span.className = 'doc-chip' + (type ? ' doc-chip-' + type : '');
        span.textContent = text;
        return span;
    }

    function clearResult() {
        resultBox.hidden = true;
        resultBox.innerHTML = '';
    }

    function setField(name, value) {
        if (value === null || value === undefined || value === '') return false;
        var el = form.querySelector('[name="' + name + '"]');
        if (!el) return false;
        if (el.tagName === 'SELECT') {
            var option = el.querySelector('option[value="' + String(value) + '"]');
            if (!option) return false;
        }
        el.value = String(value);
        el.classList.add('field-applied');
        window.setTimeout(function () { el.classList.remove('field-applied'); }, 4000);
        return true;
    }

    function applySuggestion(s) {
        setField('description', s.description);
        if (s.amount) setField('amount', Number(s.amount).toFixed(2));
        if (s.due_date) setField('due_date', s.due_date);
        if (s.transaction_date) setField('transaction_date', s.transaction_date);
        if (s.status) setField('status', s.status);
        if (s.payment_method) setField('payment_method', s.payment_method);
        if (s.category_id) setField('category_id', s.category_id);
        if (s.cost_center_id) setField('cost_center_id', s.cost_center_id);
        if (s.document_code) setField('document_code', s.document_code);

        if (s.due_date || s.payment_method || s.status) {
            var advanced = form.querySelector('details.advanced-options');
            if (advanced) advanced.open = true;
        }
    }

    function renderResult(data) {
        var s = data.suggestion || {};
        resultBox.hidden = false;
        resultBox.innerHTML = '';
        resultBox.appendChild(chip(s.label || 'Documento lido', 'ok'));
        if (s.code_valid === false) resultBox.appendChild(chip('Dígito verificador não confere', 'warn'));
        if (s.duplicate) resultBox.appendChild(chip('Este código já foi lançado antes', 'warn'));
        (s.details || []).forEach(function (d) { resultBox.appendChild(chip(d)); });
        (s.warnings || []).forEach(function (w) { resultBox.appendChild(chip(w, 'warn')); });
        if (s.payee) resultBox.appendChild(chip('Beneficiário: ' + s.payee));
        if (s.cost_center_name) resultBox.appendChild(chip('Imóvel: ' + s.cost_center_name, 'ok'));

        var note = document.createElement('p');
        note.className = 'field-note doc-result-note';
        note.textContent = 'Confira os campos destacados antes de salvar.';
        resultBox.appendChild(note);
    }

    function postJson(url, payload) {
        return fetch(url, {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf, 'Accept': 'application/json' },
            body: JSON.stringify(payload)
        }).then(function (r) {
            return r.json().catch(function () { return {}; }).then(function (json) {
                if (!r.ok || json.ok === false) {
                    throw new Error(json.error || 'Não foi possível interpretar o documento.');
                }
                return json;
            });
        });
    }

    function analyze(text, codes) {
        setStatus('Interpretando documento…', 92);
        return postJson(readUrl, { text: text || '', codes: codes || [] }).then(function (data) {
            applySuggestion(data.suggestion || {});
            renderResult(data);
            setStatus('Leitura concluída.', 100);
            hideStatus();
            return data;
        });
    }

    function fileToCanvas(file, maxSide) {
        return new Promise(function (resolve, reject) {
            var url = URL.createObjectURL(file);
            var img = new Image();
            img.onload = function () {
                var scale = Math.min(1, (maxSide || 2400) / Math.max(img.width, img.height));
                var canvas = document.createElement('canvas');
                canvas.width = Math.round(img.width * scale);
                canvas.height = Math.round(img.height * scale);
                canvas.getContext('2d').drawImage(img, 0, 0, canvas.width, canvas.height);
                URL.revokeObjectURL(url);
                resolve(canvas);
            };
            img.onerror = function () { URL.revokeObjectURL(url); reject(new Error('Imagem inválida.')); };
            img.src = url;
        });
    }

    function decodeBarcode(canvas) {
        return loadScript(CDN.zxing, 'ZXing').then(function (ZXing) {
            var hints = new Map();
            hints.set(ZXing.DecodeHintType.TRY_HARDER, true);
            hints.set(ZXing.DecodeHintType.POSSIBLE_FORMATS, [
                ZXing.BarcodeFormat.QR_CODE, ZXing.BarcodeFormat.ITF, ZXing.BarcodeFormat.CODE_128,
                ZXing.BarcodeFormat.CODE_39, ZXing.BarcodeFormat.EAN_13, ZXing.BarcodeFormat.DATA_MATRIX
            ]);
            var reader = new ZXing.BrowserMultiFormatReader(hints, 700);
            function attempt(c) {
                return reader.decodeFromCanvas(c).then(function (r) { return r.getText(); }).catch(function () { return null; });
            }
            return attempt(canvas).then(function (code) {
                if (code) return code;
                var small = document.createElement('canvas');
                small.width = Math.round(canvas.width / 2);
                small.height = Math.round(canvas.height / 2);
                small.getContext('2d').drawImage(canvas, 0, 0, small.width, small.height);
                return attempt(small);
            }).catch(function () { return null; });
        }).catch(function () { return null; });
    }

    function runOcr(canvas, basePct) {
        return loadScript(CDN.tesseract, 'Tesseract').then(function (Tesseract) {
            return Tesseract.recognize(canvas, 'por', {
                logger: function (m) {
                    if (m.status === 'recognizing text') {
                        setStatus('Lendo o texto da imagem…', basePct + Math.round(m.progress * 40));
                    }
                }
            }).then(function (res) {
                return (res && res.data && res.data.text) ? res.data.text : '';
            });
        });
    }

    function ocrSpaceFallback(file) {
        if (file.size > 1024 * 1024) return Promise.resolve('');
        var fd = new FormData();
        fd.append('file', file);
        return fetch('/lancamentos/ler-documento/ocr', {
            method: 'POST', credentials: 'same-origin',
            headers: { 'X-CSRF-Token': csrf, 'Accept': 'application/json' },
            body: fd
        }).then(function (r) { return r.json(); }).then(function (j) { return j && j.ok ? (j.text || '') : ''; })
          .catch(function () { return ''; });
    }

    function handlePdf(file) {
        setStatus('Abrindo o PDF…', 15);
        return loadScript(CDN.pdf, 'pdfjsLib').then(function (pdfjsLib) {
            pdfjsLib.GlobalWorkerOptions.workerSrc = CDN.pdfWorker;
            return file.arrayBuffer();
        }).then(function (buffer) {
            return window.pdfjsLib.getDocument({ data: buffer }).promise;
        }).then(function (pdf) {
            var paginas = Math.min(3, pdf.numPages);
            var textos = [];
            var cadeia = Promise.resolve();
            for (var i = 1; i <= paginas; i++) {
                (function (n) {
                    cadeia = cadeia.then(function () {
                        setStatus('Lendo texto da página ' + n + '…', 20 + n * 10);
                        return pdf.getPage(n).then(function (page) { return page.getTextContent(); })
                            .then(function (content) {
                                textos.push(content.items.map(function (it) { return it.str; }).join(' '));
                            });
                    });
                })(i);
            }
            return cadeia.then(function () { return pdf.getPage(1); }).then(function (page) {
                var viewport = page.getViewport({ scale: 2 });
                var canvas = document.createElement('canvas');
                canvas.width = viewport.width;
                canvas.height = viewport.height;
                return page.render({ canvasContext: canvas.getContext('2d'), viewport: viewport }).promise.then(function () { return canvas; });
            }).then(function (canvas) {
                return { text: textos.join('\n').trim(), canvas: canvas };
            });
        }).then(function (r) {
            if (r.text.length >= 40) {
                return analyze(r.text, []);
            }
            setStatus('Procurando código de barras…', 55);
            return decodeBarcode(r.canvas).then(function (code) {
                setStatus('Lendo o texto do PDF…', 65);
                return runOcr(r.canvas, 65).catch(function () { return ''; }).then(function (texto) {
                    if (!texto) return ocrSpaceFallback(file);
                    return texto;
                }).then(function (texto) {
                    return analyze(texto || r.text, code ? [code] : []);
                });
            });
        });
    }

    function handleImage(file) {
        setStatus('Preparando a imagem…', 15);
        return fileToCanvas(file, 2400).then(function (canvas) {
            setStatus('Procurando código de barras…', 40);
            return decodeBarcode(canvas).then(function (code) {
                setStatus(code ? 'Código encontrado. Lendo o texto…' : 'Lendo o texto da imagem…', 55);
                return runOcr(canvas, 55).catch(function () { return ''; }).then(function (texto) {
                    if (!texto) return ocrSpaceFallback(file);
                    return texto;
                }).then(function (texto) {
                    return analyze(texto, code ? [code] : []);
                });
            });
        });
    }

    function handleFile(file) {
        if (busy) return;
        if (!file) return;
        if (file.size > maxMb * 1024 * 1024) {
            clearResult();
            resultBox.hidden = false;
            resultBox.appendChild(chip('Arquivo maior que ' + maxMb + ' MB.', 'warn'));
            return;
        }
        busy = true;
        pendingFile = file;
        clearResult();
        var isPdf = file.type === 'application/pdf' || /\.pdf$/i.test(file.name);
        setStatus('Lendo ' + file.name + '…', 8);
        var tarefa = isPdf ? handlePdf(file) : handleImage(file);
        tarefa.catch(function (e) {
            resultBox.hidden = false;
            resultBox.innerHTML = '';
            resultBox.appendChild(chip(e.message || 'Não foi possível ler o arquivo.', 'warn'));
            resultBox.appendChild(chip('Você ainda pode digitar o código de barras.', ''));
            setStatus('Leitura não concluída.', 100);
            hideStatus();
        }).then(function () {
            busy = false;
        });
    }

    root.querySelector('[data-doc-pick]').addEventListener('click', function () { fileInput.click(); });
    root.querySelector('[data-doc-camera]').addEventListener('click', function () { cameraInput.click(); });
    fileInput.addEventListener('change', function () { handleFile(fileInput.files[0]); });
    cameraInput.addEventListener('change', function () { handleFile(cameraInput.files[0]); });

    drop.addEventListener('click', function () { fileInput.click(); });
    drop.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fileInput.click(); }
    });
    ['dragenter', 'dragover'].forEach(function (ev) {
        drop.addEventListener(ev, function (e) { e.preventDefault(); drop.classList.add('doc-drop-over'); });
    });
    ['dragleave', 'drop'].forEach(function (ev) {
        drop.addEventListener(ev, function (e) { e.preventDefault(); drop.classList.remove('doc-drop-over'); });
    });
    drop.addEventListener('drop', function (e) {
        if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) handleFile(e.dataTransfer.files[0]);
    });

    root.querySelector('[data-doc-code-toggle]').addEventListener('click', function () {
        codeBox.hidden = !codeBox.hidden;
        if (!codeBox.hidden) codeInput.focus();
    });
    root.querySelector('[data-doc-code-send]').addEventListener('click', function () {
        var code = (codeInput.value || '').replace(/\D+/g, '');
        if (code.length < 44) {
            clearResult();
            resultBox.hidden = false;
            resultBox.appendChild(chip('Informe 44, 47 ou 48 dígitos.', 'warn'));
            return;
        }
        clearResult();
        setStatus('Interpretando o código…', 70);
        analyze('', [code]).catch(function (e) {
            resultBox.hidden = false;
            resultBox.innerHTML = '';
            resultBox.appendChild(chip(e.message, 'warn'));
        }).then(function () { hideStatus(); });
    });

    // Se o usuário leu um arquivo, ele também pode virar anexo do lançamento.
    if (form) {
        form.addEventListener('submit', function () {
            var attachment = form.querySelector('[name="attachment"]');
            if (!pendingFile || !attachment || (attachment.files && attachment.files.length)) return;
            try {
                var dt = new DataTransfer();
                dt.items.add(pendingFile);
                attachment.files = dt.files;
            } catch (e) { /* navegadores antigos: segue sem anexo */ }
        });
    }
})();
