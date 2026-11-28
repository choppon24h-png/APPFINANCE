/* ============================================================
   SOMASE — Busca de CEP com fallback no servidor
   O endpoint /api/cep tenta ViaCEP, BrasilAPI e OpenCEP em ordem.
   Nenhuma chave de API no navegador.
   ============================================================ */
(() => {
    'use strict';

    const onlyDigits = (value) => (value || '').replace(/\D/g, '').slice(0, 8);
    const mask = (digits) => digits.length > 5 ? digits.slice(0, 5) + '-' + digits.slice(5) : digits;

    const setup = (form) => {
        const input = form.querySelector('[data-cep-input]');
        const button = form.querySelector('[data-cep-search]');
        const status = form.querySelector('[data-cep-status]');
        if (!input || !button) return;

        const fields = {
            street: form.querySelector('[data-cep-street]'),
            complement: form.querySelector('[data-cep-complement]'),
            neighborhood: form.querySelector('[data-cep-neighborhood]'),
            city: form.querySelector('[data-cep-city]'),
            state: form.querySelector('[data-cep-state]'),
        };

        let lastLookup = '';
        let controller = null;
        let timer = null;

        const setStatus = (message, kind) => {
            if (!status) return;
            status.textContent = message;
            status.dataset.state = kind || '';
        };

        const fill = (data) => {
            const map = {
                street: data.street,
                complement: data.complement,
                neighborhood: data.neighborhood,
                city: data.city,
                state: data.state,
            };
            Object.entries(map).forEach(([key, value]) => {
                const field = fields[key];
                if (!field || !value) return;
                // Complemento só é preenchido quando o campo está vazio.
                if (key === 'complement' && field.value.trim() !== '') return;
                field.value = value;
                field.dispatchEvent(new Event('input', { bubbles: true }));
            });
            if (fields.state && data.state) fields.state.value = String(data.state).toUpperCase().slice(0, 2);
        };

        const lookup = async (force) => {
            const digits = onlyDigits(input.value);
            if (digits.length !== 8) {
                if (force) setStatus('Informe os 8 dígitos do CEP.', 'error');
                return;
            }
            if (!force && digits === lastLookup) return;
            lastLookup = digits;

            if (controller) controller.abort();
            controller = new AbortController();
            button.disabled = true;
            setStatus('Buscando endereço…', 'loading');

            try {
                const response = await fetch('/api/cep?cep=' + encodeURIComponent(digits), {
                    headers: { Accept: 'application/json' },
                    signal: controller.signal,
                });
                const data = await response.json().catch(() => ({}));
                if (!response.ok || !data.ok) {
                    setStatus(data.error || 'CEP não encontrado. Preencha o endereço manualmente.', 'error');
                    return;
                }
                fill(data);
                const fonte = data.source ? ' · ' + data.source : '';
                const cache = data.cached ? ' (cache)' : '';
                setStatus('Endereço preenchido' + fonte + cache + '. Confira o número.', 'ok');
            } catch (error) {
                if (error.name === 'AbortError') return;
                setStatus('Não foi possível consultar o CEP agora. Preencha manualmente.', 'error');
            } finally {
                button.disabled = false;
            }
        };

        input.addEventListener('input', () => {
            const digits = onlyDigits(input.value);
            input.value = mask(digits);
            if (digits.length === 8) {
                clearTimeout(timer);
                timer = setTimeout(() => lookup(false), 350);
            } else {
                lastLookup = '';
            }
        });

        input.addEventListener('blur', () => {
            const digits = onlyDigits(input.value);
            if (digits.length === 8 && digits !== lastLookup) lookup(false);
        });

        button.addEventListener('click', () => lookup(true));

        // Ao abrir a edição de um imóvel já com CEP, não consulta de novo.
        if (onlyDigits(input.value).length === 8) lastLookup = onlyDigits(input.value);
    };

    const start = () => document.querySelectorAll('[data-center-form]').forEach(setup);
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start);
    } else {
        start();
    }
})();
