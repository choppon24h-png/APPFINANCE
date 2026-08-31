(() => {
    const ready = (callback) => document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', callback) : callback();

    ready(() => {
        const shell = document.querySelector('.app-shell');
        document.querySelectorAll('[data-nav-open]').forEach((button) => button.addEventListener('click', () => shell?.classList.add('nav-open')));
        document.querySelectorAll('[data-nav-close]').forEach((button) => button.addEventListener('click', () => shell?.classList.remove('nav-open')));
        document.querySelectorAll('.nav-item').forEach((link) => link.addEventListener('click', () => shell?.classList.remove('nav-open')));

        document.querySelectorAll('[data-dismiss]').forEach((button) => button.addEventListener('click', () => button.closest('.flash')?.remove()));
        document.querySelectorAll('[data-confirm]').forEach((form) => form.addEventListener('submit', (event) => {
            if (!window.confirm(form.dataset.confirm || 'Confirmar esta ação?')) event.preventDefault();
        }));
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

        const canvas = document.getElementById('evolution-chart');
        if (canvas && window.HTMLCanvasElement) {
            const labels = JSON.parse(canvas.dataset.labels || '[]');
            const income = JSON.parse(canvas.dataset.income || '[]');
            const expense = JSON.parse(canvas.dataset.expense || '[]');
            const drawChart = () => {
                const ratio = window.devicePixelRatio || 1;
                const width = Math.max(280, canvas.clientWidth);
                const height = Math.max(170, canvas.clientHeight);
                canvas.width = width * ratio; canvas.height = height * ratio;
                const ctx = canvas.getContext('2d'); ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
                ctx.clearRect(0, 0, width, height);
                const pad = { top: 16, right: 12, bottom: 28, left: 42 };
                const plotWidth = width - pad.left - pad.right, plotHeight = height - pad.top - pad.bottom;
                const max = Math.max(1, ...income, ...expense) * 1.15;
                ctx.font = '10px system-ui, sans-serif'; ctx.lineWidth = 1;
                for (let step = 0; step <= 4; step++) {
                    const y = pad.top + plotHeight - (plotHeight * step / 4);
                    ctx.strokeStyle = '#edf1f5'; ctx.beginPath(); ctx.moveTo(pad.left, y); ctx.lineTo(width - pad.right, y); ctx.stroke();
                    ctx.fillStyle = '#94a1b2'; ctx.textAlign = 'right'; ctx.fillText('R$ ' + Math.round(max * step / 4).toLocaleString('pt-BR'), pad.left - 8, y + 3);
                }
                const x = (index) => labels.length <= 1 ? pad.left : pad.left + (plotWidth * index / (labels.length - 1));
                const y = (value) => pad.top + plotHeight - (plotHeight * Number(value || 0) / max);
                const line = (values, color) => {
                    ctx.strokeStyle = color; ctx.lineWidth = 2.5; ctx.lineJoin = 'round'; ctx.lineCap = 'round'; ctx.beginPath();
                    values.forEach((value, index) => index ? ctx.lineTo(x(index), y(value)) : ctx.moveTo(x(index), y(value)));
                    ctx.stroke();
                    values.forEach((value, index) => { ctx.fillStyle = '#fff'; ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(x(index), y(value), 3, 0, Math.PI * 2); ctx.fill(); ctx.stroke(); });
                };
                line(income, '#159570'); line(expense, '#d94b62');
                ctx.fillStyle = '#94a1b2'; ctx.textAlign = 'center';
                labels.forEach((label, index) => { if (labels.length < 13 || index % 2 === 0 || index === labels.length - 1) ctx.fillText(label, x(index), height - 8); });
            };
            new ResizeObserver(drawChart).observe(canvas.parentElement);
            drawChart();
        }
    });
})();
