/**
 * Grade de revisao da importacao de extrato (OFX/CSV).
 * Le o arquivo via POST /lancamentos/importar/extrato e grava em
 * POST /lancamentos/importar/confirmar (ate 300 linhas).
 */
(function () {
    'use strict';

    var root = document.querySelector('[data-import]');
    if (!root) return;

    var form = root.querySelector('[data-import-form]');
    var statusBox = root.querySelector('[data-import-status]');
    var statusText = root.querySelector('[data-import-status-text]');
    var progress = root.querySelector('[data-import-progress]');
    var summary = root.querySelector('[data-import-summary]');
    var gridWrap = root.querySelector('[data-import-grid-wrap]');
    var tbody = root.querySelector('[data-import-rows]');
    var countLabel = root.querySelector('[data-import-count]');
    var resultBox = root.querySelector('[data-import-result]');
    var csrf = root.dataset.csrf || '';
    var opcoes = JSON.parse(document.getElementById('import-options').textContent || '{}');
    var state = { rows: [], accountId: null };

    function setStatus(text, pct) {
        statusBox.hidden = false;
        statusText.textContent = text;
        progress.style.width = Math.max(0, Math.min(100, pct || 0)) + '%';
    }

    function hideStatus() { window.setTimeout(function () { statusBox.hidden = true; }, 500); }

    function el(tag, attrs, children) {
        var node = document.createElement(tag);
        Object.keys(attrs || {}).forEach(function (k) {
            if (k === 'text') node.textContent = attrs[k];
            else if (k === 'className') node.className = attrs[k];
            else node.setAttribute(k, attrs[k]);
        });
        (children || []).forEach(function (c) { node.appendChild(c); });
        return node;
    }

    function selectOptions(list, selected, emptyLabel) {
        var frag = document.createDocumentFragment();
        frag.appendChild(el('option', { value: '', text: emptyLabel }));
        list.forEach(function (item) {
            var opt = el('option', { value: item.id, text: item.name });
            if (Number(selected) === Number(item.id)) opt.selected = true;
            frag.appendChild(opt);
        });
        return frag;
    }

    function badge(row) {
        if (row.duplicate === 'imported') {
            var b = el('span', { className: 'import-badge import-badge-imported', text: 'Já importado' });
            if (row.duplicate_hint) b.title = 'Lançamento existente: ' + row.duplicate_hint;
            return b;
        }
        if (row.duplicate === 'similar') {
            var s = el('span', { className: 'import-badge import-badge-similar', text: 'Parecido' });
            if (row.duplicate_hint) s.title = 'Já existe: ' + row.duplicate_hint;
            return s;
        }
        return el('span', { className: 'import-badge', text: 'Novo' });
    }

    function addRow(row, index) {
        var tr = el('tr', { 'data-index': index });
        if (row.duplicate === 'imported') tr.className = 'import-row-imported';

        var include = el('input', { type: 'checkbox', 'data-row-include': '1' });
        include.checked = row.duplicate !== 'imported';
        if (row.duplicate === 'imported') include.disabled = true;
        tr.appendChild(el('td', { className: 'import-check' }, [include]));

        var date = el('input', { type: 'date', value: row.date || '', 'data-field': 'date' });
        tr.appendChild(el('td', {}, [date]));

        var desc = el('input', { type: 'text', value: row.description || '', maxlength: '180', 'data-field': 'description' });
        tr.appendChild(el('td', { className: 'import-desc' }, [desc]));

        var amount = el('input', { type: 'number', step: '0.01', min: '0.01', value: row.amount ? Number(row.amount).toFixed(2) : '', 'data-field': 'amount' });
        tr.appendChild(el('td', {}, [amount]));

        var type = el('select', { 'data-field': 'type' });
        [['expense', 'Despesa'], ['income', 'Receita']].forEach(function (t) {
            var opt = el('option', { value: t[0], text: t[1] });
            if ((row.type || 'expense') === t[0]) opt.selected = true;
            type.appendChild(opt);
        });
        tr.appendChild(el('td', {}, [type]));

        var category = el('select', { 'data-field': 'category_id' });
        category.appendChild(selectOptions(opcoes.categories || [], row.category_id, 'Sem categoria'));
        tr.appendChild(el('td', {}, [category]));

        var center = el('select', { 'data-field': 'cost_center_id' });
        center.appendChild(selectOptions(opcoes.costCenters || [], row.cost_center_id, 'Sem centro'));
        tr.appendChild(el('td', {}, [center]));

        tr.appendChild(el('td', { className: 'import-status' }, [badge(row)]));
        tr.dataset.importRef = row.import_ref || '';
        tbody.appendChild(tr);
    }

    function render(rows) {
        tbody.innerHTML = '';
        state.rows = rows;
        rows.forEach(addRow);
        gridWrap.hidden = false;
        var novos = rows.filter(function (r) { return r.duplicate !== 'imported'; }).length;
        countLabel.textContent = rows.length + ' linha(s) no arquivo · ' + novos + ' para importar';
        summary.hidden = false;
        summary.innerHTML = '';
        summary.appendChild(el('strong', { text: rows.length + ' lançamentos encontrados' }));
        summary.appendChild(el('span', { text: novos + ' novos · ' + (rows.length - novos) + ' já importados (desmarcados)' }));
    }

    function collect() {
        var rows = [];
        Array.prototype.forEach.call(tbody.querySelectorAll('tr'), function (tr) {
            var include = tr.querySelector('[data-row-include]');
            if (!include || !include.checked) return;
            function val(name) { var f = tr.querySelector('[data-field="' + name + '"]'); return f ? f.value : ''; }
            rows.push({
                date: val('date'),
                description: val('description'),
                amount: val('amount'),
                type: val('type'),
                category_id: val('category_id') || null,
                cost_center_id: val('cost_center_id') || null,
                import_ref: tr.dataset.importRef || ''
            });
        });
        return rows;
    }

    function post(url, body) {
        return fetch(url, {
            method: 'POST',
            credentials: 'same-origin',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf, 'Accept': 'application/json' },
            body: JSON.stringify(body)
        }).then(function (r) {
            return r.json().catch(function () { return {}; }).then(function (json) {
                if (!r.ok || json.ok === false) throw new Error(json.error || 'Falha na importação.');
                return json;
            });
        });
    }

    form.addEventListener('submit', function (e) {
        e.preventDefault();
        var accountId = form.querySelector('[name="account_id"]').value;
        if (!accountId) {
            summary.hidden = false;
            summary.textContent = 'Selecione a conta de destino.';
            return;
        }
        var fileInput = form.querySelector('[data-import-file]');
        var content = (form.querySelector('[data-import-content]') || {}).value || '';
        if ((!fileInput.files || !fileInput.files.length) && !content.trim()) {
            summary.hidden = false;
            summary.textContent = 'Escolha um arquivo OFX/CSV ou cole o conteúdo.';
            return;
        }
        state.accountId = accountId;
        var fd = new FormData();
        fd.append('account_id', accountId);
        fd.append('_csrf_token', csrf);
        if (fileInput.files && fileInput.files[0]) fd.append('file', fileInput.files[0]);
        if (content.trim()) fd.append('content', content);
        setStatus('Lendo o extrato…', 25);
        fetch(root.dataset.previewUrl, {
            method: 'POST', credentials: 'same-origin',
            headers: { 'X-CSRF-Token': csrf, 'Accept': 'application/json' },
            body: fd
        }).then(function (r) {
            return r.json().catch(function () { return {}; }).then(function (json) {
                if (!r.ok || json.ok === false) throw new Error(json.error || 'Não foi possível ler o extrato.');
                return json;
            });
        }).then(function (data) {
            setStatus('Montando a grade…', 80);
            render(data.rows || []);
            if (data.truncated) {
                summary.appendChild(el('em', { text: ' Mostrando as primeiras ' + data.rows.length + ' linhas de ' + data.total + '.' }));
            }
            setStatus('Pronto para revisar.', 100);
            hideStatus();
        }).catch(function (err) {
            summary.hidden = false;
            summary.textContent = err.message;
            setStatus('Leitura não concluída.', 100);
            hideStatus();
        });
    });

    root.querySelector('[data-import-confirm]').addEventListener('click', function () {
        var rows = collect();
        if (!rows.length) {
            resultBox.hidden = false;
            resultBox.innerHTML = '';
            var importados = tbody.querySelectorAll('.import-badge-imported').length;
            resultBox.appendChild(el('p', {
                className: 'import-done',
                text: importados
                    ? 'Nada novo para importar: ' + importados + ' linha(s) já estavam no sistema.'
                    : 'Marque ao menos uma linha para importar.'
            }));
            return;
        }
        var botao = this;
        botao.disabled = true;
        setStatus('Importando ' + rows.length + ' lançamento(s)…', 50);
        post(root.dataset.confirmUrl, { account_id: state.accountId, rows: rows }).then(function (data) {
            setStatus(data.message || 'Importação concluída.', 100);
            resultBox.hidden = false;
            resultBox.innerHTML = '';
            var p = el('p', { className: 'import-done', text: data.message });
            resultBox.appendChild(p);
            if (data.errors && data.errors.length) {
                var ul = el('ul', { className: 'import-errors' });
                data.errors.forEach(function (e) { ul.appendChild(el('li', { text: e })); });
                resultBox.appendChild(ul);
            }
            var link = el('a', { className: 'button button-primary', href: '/lancamentos', text: 'Ver lançamentos' });
            resultBox.appendChild(link);
            rows.forEach(function () {});
            hideStatus();
            gridWrap.hidden = true;
        }).catch(function (err) {
            resultBox.hidden = false;
            resultBox.textContent = err.message;
            setStatus('Importação não concluída.', 100);
            hideStatus();
        }).then(function () { botao.disabled = false; });
    });

    root.querySelector('[data-import-toggle-all]').addEventListener('click', function () {
        var boxes = tbody.querySelectorAll('[data-row-include]:not(:disabled)');
        var todosMarcados = Array.prototype.every.call(boxes, function (b) { return b.checked; });
        Array.prototype.forEach.call(boxes, function (b) { b.checked = !todosMarcados; });
    });
})();
