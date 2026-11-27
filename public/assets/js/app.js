/* ============================================================
   SOMASE — Controle Financeiro
   Interacoes globais, graficos SVG e helpers de login
   JavaScript puro, sem dependencias.
   ============================================================ */
(() => {
    'use strict';

    const ready = (callback) => document.readyState === 'loading'
        ? document.addEventListener('DOMContentLoaded', callback)
        : callback();

    const SVG_NS = 'http://www.w3.org/2000/svg';
    const brl = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
    const brlShort = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 });
    const money = (value) => brl.format(Number(value) || 0);
    const moneyShort = (value) => {
        const number = Number(value) || 0;
        const abs = Math.abs(number);
        if (abs >= 1000000) return 'R$ ' + (number / 1000000).toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 }) + ' mi';
        if (abs >= 1000) return 'R$ ' + (number / 1000).toLocaleString('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 }) + ' mil';
        return brlShort.format(number);
    };
    const svgEl = (name, attrs = {}) => {
        const node = document.createElementNS(SVG_NS, name);
        Object.entries(attrs).forEach(([key, value]) => node.setAttribute(key, value));
        return node;
    };
    const parseData = (node, key, fallback) => {
        try {
            const parsed = JSON.parse(node.dataset[key] || '');
            return parsed ?? fallback;
        } catch (error) {
            return fallback;
        }
    };

    /* ---------- grafico de evolucao (barras + linha) ---------- */
    const renderEvolution = (wrap) => {
        const svg = wrap.querySelector('.chart-svg');
        if (!svg) return;
        const tooltip = wrap.querySelector('.chart-tooltip');
        const labels = parseData(wrap, 'labels', []);
        const income = parseData(wrap, 'income', []);
        const expense = parseData(wrap, 'expense', []);
        const result = parseData(wrap, 'result', []);
        if (!labels.length) return;

        const width = Math.max(280, wrap.clientWidth);
        const height = Math.max(180, wrap.clientHeight);
        const pad = { top: 14, right: 8, bottom: 26, left: width < 420 ? 38 : 52 };
        const plotW = Math.max(10, width - pad.left - pad.right);
        const plotH = Math.max(10, height - pad.top - pad.bottom);

        const values = [...income, ...expense, ...result, 0];
        const maxValue = Math.max(...values);
        const minValue = Math.min(...values);
        const top = maxValue > 0 ? maxValue * 1.12 : 10;
        const bottom = minValue < 0 ? minValue * 1.15 : 0;
        const span = top - bottom || 1;
        const y = (value) => pad.top + plotH - ((Number(value) - bottom) / span) * plotH;

        svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
        svg.setAttribute('width', width);
        svg.setAttribute('height', height);
        svg.replaceChildren();

        const defs = svgEl('defs');
        const gradIncome = svgEl('linearGradient', { id: 'gradIncome', x1: '0', y1: '0', x2: '0', y2: '1' });
        gradIncome.append(svgEl('stop', { offset: '0%', 'stop-color': '#8fe03a' }), svgEl('stop', { offset: '100%', 'stop-color': '#2f9e2a' }));
        const gradExpense = svgEl('linearGradient', { id: 'gradExpense', x1: '0', y1: '0', x2: '0', y2: '1' });
        gradExpense.append(svgEl('stop', { offset: '0%', 'stop-color': '#ff8a9a' }), svgEl('stop', { offset: '100%', 'stop-color': '#e03b53' }));
        defs.append(gradIncome, gradExpense);
        svg.append(defs);

        const steps = 4;
        for (let step = 0; step <= steps; step++) {
            const value = bottom + (span * step) / steps;
            const lineY = y(value);
            svg.append(svgEl('line', {
                x1: pad.left, y1: lineY, x2: width - pad.right, y2: lineY,
                class: 'chart-grid-line', 'stroke-dasharray': step === 0 ? '0' : '3 5',
            }));
            const label = svgEl('text', {
                x: pad.left - 8, y: lineY + 3, 'text-anchor': 'end', class: 'chart-axis-label',
            });
            label.textContent = moneyShort(value);
            svg.append(label);
        }

        const band = plotW / labels.length;
        const barW = Math.max(3, Math.min(16, band * 0.3));
        const gap = Math.max(2, barW * 0.25);
        const labelStep = width < 420 ? Math.ceil(labels.length / 4) : (width < 640 ? Math.ceil(labels.length / 6) : Math.ceil(labels.length / 8));

        labels.forEach((label, index) => {
            const center = pad.left + band * index + band / 2;
            const incomeValue = Number(income[index]) || 0;
            const expenseValue = Number(expense[index]) || 0;

            const hover = svgEl('rect', {
                x: pad.left + band * index, y: pad.top, width: band, height: plotH,
                class: 'chart-hit', 'data-index': index, tabindex: '0', role: 'button',
                'aria-label': `${label}: receitas ${money(incomeValue)}, despesas ${money(expenseValue)}`,
            });
            svg.append(hover);

            svg.append(svgEl('rect', {
                x: center - barW - gap / 2,
                y: incomeValue >= 0 ? y(incomeValue) : y(0),
                width: barW,
                height: Math.max(1.5, Math.abs(y(incomeValue) - y(0))),
                rx: Math.min(3, barW / 2),
                class: 'chart-bar-income',
            }));
            svg.append(svgEl('rect', {
                x: center + gap / 2,
                y: expenseValue >= 0 ? y(expenseValue) : y(0),
                width: barW,
                height: Math.max(1.5, Math.abs(y(expenseValue) - y(0))),
                rx: Math.min(3, barW / 2),
                class: 'chart-bar-expense',
            }));

            if (labels.length <= 6 || index % labelStep === 0 || index === labels.length - 1) {
                const text = svgEl('text', {
                    x: center, y: height - 8, 'text-anchor': 'middle', class: 'chart-axis-label',
                });
                text.textContent = label;
                svg.append(text);
            }
        });

        const points = result.map((value, index) => ({
            x: pad.left + band * index + band / 2,
            y: y(Number(value) || 0),
        }));
        if (points.length > 1) {
            svg.append(svgEl('polyline', {
                points: points.map((point) => `${point.x},${point.y}`).join(' '),
                class: 'chart-line-result',
            }));
        }
        points.forEach((point) => {
            svg.append(svgEl('circle', { cx: point.x, cy: point.y, r: 2.6, class: 'chart-dot-result' }));
        });

        const showTooltip = (index) => {
            if (!tooltip) return;
            const incomeValue = Number(income[index]) || 0;
            const expenseValue = Number(expense[index]) || 0;
            const resultValue = Number(result[index]) || 0;
            tooltip.innerHTML = `
                <strong>${labels[index]}</strong>
                <span><em><i style="background:#43c13a"></i>Receitas</em><b>${money(incomeValue)}</b></span>
                <span><em><i style="background:#ff5d73"></i>Despesas</em><b>${money(expenseValue)}</b></span>
                <span><em><i style="background:#cfe2ff"></i>Resultado</em><b>${money(resultValue)}</b></span>`;
            tooltip.classList.add('is-visible');
            const center = pad.left + band * index + band / 2;
            const left = Math.min(Math.max(center, 86), width - 86);
            tooltip.style.left = `${left}px`;
            tooltip.style.top = `${Math.max(6, pad.top)}px`;
        };
        const hideTooltip = () => tooltip?.classList.remove('is-visible');

        svg.querySelectorAll('.chart-hit').forEach((hit) => {
            const index = Number(hit.dataset.index);
            hit.addEventListener('mouseenter', () => showTooltip(index));
            hit.addEventListener('focus', () => showTooltip(index));
            hit.addEventListener('mouseleave', hideTooltip);
            hit.addEventListener('blur', hideTooltip);
            hit.addEventListener('touchstart', () => showTooltip(index), { passive: true });
            hit.addEventListener('click', () => showTooltip(index));
        });
    };

    /* ---------- donut de despesas por categoria ---------- */
    const renderDonut = (wrap) => {
        const svg = wrap.querySelector('.donut-svg');
        const series = parseData(wrap, 'series', []);
        if (!svg || !series.length) return;
        const total = series.reduce((sum, item) => sum + (Number(item.value) || 0), 0);
        if (total <= 0) return;

        const radius = 46;
        const circumference = 2 * Math.PI * radius;
        const gap = 1.6;
        let offset = 0;
        svg.replaceChildren();

        series.forEach((item) => {
            const share = (Number(item.value) || 0) / total;
            const length = Math.max(0, share * circumference - gap);
            const segment = svgEl('circle', {
                cx: 60, cy: 60, r: radius,
                class: 'donut-seg',
                stroke: item.color,
                'stroke-dasharray': `${length} ${circumference - length}`,
                'stroke-dashoffset': -offset,
            });
            const title = svgEl('title');
            title.textContent = `${item.label}: ${money(item.value)} (${(share * 100).toFixed(0)}%)`;
            segment.append(title);
            svg.append(segment);
            offset += share * circumference;
        });
    };

    /* ---------- navegacao / sidebar ---------- */
    const initShell = () => {
        const shell = document.querySelector('.app-shell');
        if (!shell) return;
        const open = () => shell.classList.add('nav-open');
        const close = () => shell.classList.remove('nav-open');
        document.querySelectorAll('[data-nav-open]').forEach((button) => button.addEventListener('click', open));
        document.querySelectorAll('[data-nav-close]').forEach((button) => button.addEventListener('click', close));
        document.querySelectorAll('.nav-item').forEach((link) => link.addEventListener('click', close));
        document.addEventListener('keydown', (event) => { if (event.key === 'Escape') close(); });
    };

    /* ---------- formularios ---------- */
    const initForms = () => {
        document.querySelectorAll('[data-dismiss]').forEach((button) => {
            button.addEventListener('click', () => button.closest('.flash')?.remove());
        });
        document.querySelectorAll('[data-confirm]').forEach((form) => {
            form.addEventListener('submit', (event) => {
                if (!window.confirm(form.dataset.confirm || 'Confirmar esta ação?')) event.preventDefault();
            });
        });
        document.addEventListener('click', (event) => {
            document.querySelectorAll('.action-menu[open]').forEach((menu) => {
                if (!menu.contains(event.target)) menu.removeAttribute('open');
            });
        });

        const form = document.querySelector('[data-transaction-form]');
        if (form) {
            const typeInput = form.querySelector('[data-type-input]');
            const typeOptions = form.querySelectorAll('[data-type]');
            const categorySelect = form.querySelector('[data-category-select]');
            const statusSelect = form.querySelector('[data-status-select]');
            const statusOptions = {
                income: [['expected', 'Prevista'], ['received', 'Recebida'], ['late', 'Atrasada'], ['cancelled', 'Cancelada']],
                expense: [['pending', 'Pendente'], ['paid', 'Paga'], ['overdue', 'Vencida'], ['cancelled', 'Cancelada']],
            };
            const applyType = (type) => {
                if (!typeInput) return;
                typeInput.value = type;
                typeOptions.forEach((option) => option.classList.toggle('active', option.dataset.type === type));
                categorySelect?.querySelectorAll('option[data-category-type]').forEach((option) => {
                    option.hidden = option.dataset.categoryType !== type;
                    if (option.hidden && option.selected) categorySelect.value = '';
                });
                if (statusSelect) {
                    const current = statusSelect.value;
                    statusSelect.innerHTML = '';
                    (statusOptions[type] || []).forEach(([value, label]) => {
                        const option = new Option(label, value);
                        if (value === current || (!current && value === (type === 'income' ? 'received' : 'paid'))) option.selected = true;
                        statusSelect.add(option);
                    });
                }
            };
            typeOptions.forEach((option) => option.addEventListener('click', () => applyType(option.dataset.type)));
            applyType(typeInput?.value || 'expense');
        }
    };

    /* ---------- login ---------- */
    const initLogin = () => {
        const form = document.querySelector('[data-login-form]');
        if (!form) return;

        const password = form.querySelector('#login-password');
        const toggle = form.querySelector('[data-toggle-password]');
        toggle?.addEventListener('click', () => {
            const visible = password.type === 'text';
            password.type = visible ? 'password' : 'text';
            toggle.textContent = visible ? 'mostrar' : 'ocultar';
            toggle.setAttribute('aria-pressed', String(!visible));
            password.focus({ preventScroll: true });
        });

        const email = form.querySelector('#login-email');
        const remember = form.querySelector('[data-remember-email]');
        const storageKey = 'somase_email';
        try {
            const saved = window.localStorage.getItem(storageKey);
            if (saved && email && !email.value) {
                email.value = saved;
                if (remember) remember.checked = true;
            }
        } catch (error) { /* armazenamento indisponivel */ }

        form.addEventListener('submit', () => {
            try {
                if (remember?.checked && email?.value) window.localStorage.setItem(storageKey, email.value);
                else window.localStorage.removeItem(storageKey);
            } catch (error) { /* ignora */ }
            const submit = form.querySelector('[type="submit"]');
            if (submit) {
                submit.classList.add('is-loading');
                submit.disabled = true;
                submit.textContent = 'Entrando...';
            }
        });
    };

    /* ---------- bootstrap ---------- */
    ready(() => {
        initShell();
        initForms();
        initLogin();

        const charts = document.querySelectorAll('[data-chart="evolution"]');
        const donuts = document.querySelectorAll('[data-chart="donut"]');
        if (!charts.length && !donuts.length) return;

        const draw = () => {
            charts.forEach(renderEvolution);
            donuts.forEach(renderDonut);
        };
        draw();

        if ('ResizeObserver' in window) {
            let frame = 0;
            const observer = new ResizeObserver(() => {
                cancelAnimationFrame(frame);
                frame = requestAnimationFrame(draw);
            });
            charts.forEach((chart) => observer.observe(chart));
        } else {
            window.addEventListener('resize', draw);
        }
    });
})();
