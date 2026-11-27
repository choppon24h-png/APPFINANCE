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

    /* ---------- mostrar/ocultar senha (qualquer tela) ---------- */
    // Delegacao de evento: cobre login, cadastro, confirmação de senha e
    // qualquer campo futuro com o atributo data-toggle-password.
    const initPasswordToggles = () => {
        document.addEventListener('click', (event) => {
            const toggle = event.target.closest('[data-toggle-password]');
            if (!toggle) return;
            event.preventDefault();

            const alvoId = toggle.getAttribute('aria-controls');
            const campo = toggle.closest('.field');
            const input = (alvoId && document.getElementById(alvoId))
                || campo?.querySelector('input')
                || toggle.closest('form')?.querySelector('input[type="password"], input[data-password-visible="true"]');
            if (!input) return;

            const visivel = input.type === 'text';
            input.type = visivel ? 'password' : 'text';
            input.dataset.passwordVisible = visivel ? 'false' : 'true';

            const rotulo = visivel ? 'mostrar' : 'ocultar';
            toggle.textContent = rotulo;
            toggle.setAttribute('aria-pressed', String(!visivel));
            toggle.setAttribute('aria-label', rotulo + ' senha');
            toggle.classList.toggle('is-visible', !visivel);

            // Mantem o cursor no fim do texto ao alternar a visibilidade
            try {
                const fim = input.value.length;
                input.focus({ preventScroll: true });
                input.setSelectionRange(fim, fim);
            } catch (error) {
                input.focus({ preventScroll: true });
            }
        });
    };

    /* ---------- login ---------- */
    const initLogin = () => {
        const form = document.querySelector('[data-login-form]');
        if (!form) return;

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


    /* ---------- cadastro: validação e força da senha ---------- */
    const initRegister = () => {
        const form = document.querySelector('[data-register-form]');
        if (!form) return;

        const name = form.querySelector('#reg-name');
        const email = form.querySelector('#reg-email');
        const birth = form.querySelector('#reg-birth');
        const pass = form.querySelector('#reg-password');
        const confirm = form.querySelector('#reg-password-confirm');
        const strength = form.querySelector('[data-strength]');
        const strengthLabel = strength?.querySelector('.strength-label');
        const minAge = Number(form.dataset.minAge || 18);

        const setError = (input, message) => {
            if (!input) return;
            const field = input.closest('.field');
            const small = field?.querySelector('small');
            if (!field || !small) return;
            field.classList.toggle('has-error', Boolean(message));
            small.textContent = message || small.dataset.hint || '';
            small.className = message ? 'field-error' : 'field-hint';
        };

        // guarda as dicas originais para restaurar
        form.querySelectorAll('.field > small').forEach((small) => {
            small.dataset.hint = small.textContent.trim();
        });

        const idade = (valor) => {
            if (!/^\d{4}-\d{2}-\d{2}$/.test(valor)) return null;
            const nasc = new Date(valor + 'T00:00:00');
            if (Number.isNaN(nasc.getTime())) return null;
            const hoje = new Date();
            let anos = hoje.getFullYear() - nasc.getFullYear();
            const m = hoje.getMonth() - nasc.getMonth();
            if (m < 0 || (m === 0 && hoje.getDate() < nasc.getDate())) anos--;
            return anos;
        };

        const checarNome = () => {
            const valor = (name.value || '').replace(/\s+/g, ' ').trim();
            if (valor.length < 3) return 'Informe seu nome completo.';
            if (valor.length > 120) return 'O nome deve ter até 120 caracteres.';
            if (valor.split(' ').length < 2) return 'Informe nome e sobrenome.';
            if (!/^[\p{L}\s'’\-]+$/u.test(valor)) return 'Use apenas letras, espaços, hífen e apóstrofo.';
            return '';
        };

        const checarEmail = () => {
            const valor = (email.value || '').trim().toLowerCase();
            if (!valor) return 'Informe seu e-mail.';
            if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(valor)) return 'Informe um e-mail válido.';
            return '';
        };

        const checarNascimento = () => {
            if (!birth.value) return 'Informe sua data de nascimento.';
            const anos = idade(birth.value);
            if (anos === null) return 'Informe uma data válida.';
            if (anos < 0) return 'A data não pode estar no futuro.';
            if (Number(birth.value.slice(0, 4)) < 1900) return 'Informe um ano a partir de 1900.';
            if (anos < minAge) return `É necessário ter pelo menos ${minAge} anos.`;
            return '';
        };

        const forca = (valor) => {
            let pontos = 0;
            if (valor.length >= 8) pontos++;
            if (/[A-Z]/.test(valor) && /[a-z]/.test(valor)) pontos++;
            if (/\d/.test(valor)) pontos++;
            if (/[^A-Za-z0-9]/.test(valor)) pontos++;
            if (valor.length >= 12 && pontos === 4) pontos = 4;
            return Math.min(4, pontos);
        };

        const rotulos = ['Muito fraca', 'Fraca', 'Média', 'Boa', 'Forte'];

        const atualizarForca = () => {
            if (!strength || !pass) return;
            const valor = pass.value || '';
            strength.hidden = valor.length === 0;
            const nivel = forca(valor);
            strength.dataset.score = String(nivel);
            if (strengthLabel) strengthLabel.textContent = valor ? rotulos[nivel] : 'Força da senha';
        };

        const checarSenha = () => {
            const valor = pass.value || '';
            if (valor.length < 8) return 'A senha deve ter pelo menos 8 caracteres.';
            if (!/[A-Z]/.test(valor)) return 'Inclua pelo menos uma letra maiúscula.';
            if (!/[a-z]/.test(valor)) return 'Inclua pelo menos uma letra minúscula.';
            if (!/\d/.test(valor)) return 'Inclua pelo menos um número.';
            if (!/[^A-Za-z0-9]/.test(valor)) return 'Inclua pelo menos um símbolo.';
            return '';
        };

        const checarConfirmacao = () => {
            if (!confirm.value) return 'Confirme a senha.';
            if (confirm.value !== pass.value) return 'As senhas não conferem.';
            return '';
        };

        const validadores = [
            [name, checarNome],
            [email, checarEmail],
            [birth, checarNascimento],
            [pass, checarSenha],
            [confirm, checarConfirmacao],
        ];

        validadores.forEach(([input, fn]) => {
            if (!input) return;
            input.addEventListener('blur', () => setError(input, fn()));
            input.addEventListener('input', () => {
                if (input.closest('.field')?.classList.contains('has-error')) {
                    setError(input, fn());
                }
                if (input === pass) {
                    atualizarForca();
                    if (confirm.value) setError(confirm, checarConfirmacao());
                }
            });
        });

        form.addEventListener('submit', (event) => {
            let primeiro = null;
            validadores.forEach(([input, fn]) => {
                const erro = fn();
                setError(input, erro);
                if (erro && !primeiro) primeiro = input;
            });

            const termos = form.querySelector('input[name="terms"]');
            if (termos && !termos.checked) {
                if (!primeiro) primeiro = termos;
            }

            if (primeiro) {
                event.preventDefault();
                primeiro.focus();
            }
        });
    };

    /* ---------- bootstrap ---------- */
    ready(() => {
        initShell();
        initForms();
        initPasswordToggles();
        initLogin();
        initRegister();

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
