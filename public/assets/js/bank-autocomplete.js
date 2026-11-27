/**
 * SOMASE — Autocomplete de bancos brasileiros.
 *
 * Transforma o campo "Banco ou instituição" em uma combobox que consulta
 * /api/bancos?q=... (catalogo COMPE da migration 0005) e mostra codigo,
 * nome e logotipo. Sem JS o campo continua funcionando como texto livre.
 */
(function () {
    'use strict';

    var DEBOUNCE = 160;

    function escapar(texto) {
        return String(texto == null ? '' : texto)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function normalizar(texto) {
        return String(texto || '')
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '');
    }

    /** Destaca o trecho digitado dentro do nome (sem quebrar o HTML). */
    function destacar(texto, termo) {
        var seguro = escapar(texto);
        var alvo = normalizar(termo).trim();
        if (alvo.length < 2) {
            return seguro;
        }
        var indice = normalizar(texto).indexOf(alvo);
        if (indice < 0) {
            return seguro;
        }
        var antes = escapar(texto.slice(0, indice));
        var meio = escapar(texto.slice(indice, indice + alvo.length));
        var depois = escapar(texto.slice(indice + alvo.length));

        return antes + '<mark>' + meio + '</mark>' + depois;
    }

    function criar(picker) {
        var input = picker.querySelector('[data-bank-input]');
        var codigo = picker.querySelector('[data-bank-code]');
        var chip = picker.querySelector('[data-bank-chip]');
        var lista = picker.querySelector('[data-bank-list]');
        if (!input || !lista) {
            return null;
        }

        var endpoint = picker.getAttribute('data-endpoint') || '/api/bancos';
        var itens = [];
        var ativo = -1;
        var timer = null;
        var controle = null;
        var ultimoTermo = null;
        var selecionado = input.value.trim();
        var aberto = false;

        function definirCodigo(valor) {
            if (codigo) {
                codigo.value = valor || '';
            }
            if (chip) {
                chip.textContent = valor || '';
                chip.hidden = !valor;
            }
            picker.classList.toggle('has-code', !!valor);
        }

        function abrir() {
            if (aberto) {
                return;
            }
            aberto = true;
            lista.hidden = false;
            picker.classList.add('is-open');
            input.setAttribute('aria-expanded', 'true');
        }

        function fechar() {
            aberto = false;
            ativo = -1;
            lista.hidden = true;
            picker.classList.remove('is-open');
            input.setAttribute('aria-expanded', 'false');
            input.removeAttribute('aria-activedescendant');
        }

        function marcarAtivo(indice) {
            var opcoes = lista.querySelectorAll('[role="option"]');
            if (!opcoes.length) {
                return;
            }
            ativo = (indice + opcoes.length) % opcoes.length;
            for (var i = 0; i < opcoes.length; i++) {
                var selecionada = i === ativo;
                opcoes[i].classList.toggle('is-active', selecionada);
                opcoes[i].setAttribute('aria-selected', selecionada ? 'true' : 'false');
                if (selecionada) {
                    input.setAttribute('aria-activedescendant', opcoes[i].id);
                    if (opcoes[i].scrollIntoView) {
                        opcoes[i].scrollIntoView({ block: 'nearest' });
                    }
                }
            }
        }

        function mensagem(texto, classe) {
            lista.innerHTML = '<li class="bank-empty ' + (classe || '') + '">' + escapar(texto) + '</li>';
            abrir();
        }

        function renderizar(dados) {
            itens = dados || [];
            ativo = -1;
            if (!itens.length) {
                mensagem('Nenhum banco encontrado. Você pode digitar o nome livremente.');
                return;
            }
            var termo = input.value.trim();
            var html = '';
            for (var i = 0; i < itens.length; i++) {
                var banco = itens[i];
                var nome = banco.fullName || banco.name || '';
                var curto = banco.label || banco.name || nome;
                var id = 'bank-opt-' + i;
                var logo = banco.logo
                    ? '<img src="' + escapar(banco.logo) + '" alt="" loading="lazy" onerror="this.remove()">'
                    : '';
                html += '<li role="option" id="' + id + '" class="bank-option" data-indice="' + i + '" aria-selected="false">'
                    + '<span class="bank-logo' + (banco.logo ? ' has-logo' : '') + '">' + logo
                    + '<b>' + escapar(banco.code || '—') + '</b></span>'
                    + '<span class="bank-text"><strong>' + destacar(curto, termo) + '</strong>'
                    + (nome && normalizar(nome) !== normalizar(curto)
                        ? '<small>' + destacar(nome, termo) + '</small>'
                        : '')
                    + '</span>'
                    + '<span class="bank-code">' + escapar(banco.code || '') + '</span>'
                    + '</li>';
            }
            lista.innerHTML = html;
            abrir();
        }

        function buscar(termo) {
            if (controle) {
                controle.abort();
            }
            controle = typeof AbortController !== 'undefined' ? new AbortController() : null;
            mensagem('Buscando bancos…', 'is-loading');

            fetch(endpoint + '?q=' + encodeURIComponent(termo), {
                headers: { 'Accept': 'application/json' },
                credentials: 'same-origin',
                signal: controle ? controle.signal : undefined
            })
                .then(function (resposta) {
                    if (!resposta.ok) {
                        throw new Error('HTTP ' + resposta.status);
                    }
                    return resposta.json();
                })
                .then(function (json) {
                    if (json && json.aviso) {
                        mensagem(json.aviso, 'is-warning');
                        return;
                    }
                    renderizar((json && json.items) || []);
                })
                .catch(function (erro) {
                    if (erro && erro.name === 'AbortError') {
                        return;
                    }
                    mensagem('Não foi possível carregar a lista. Digite o nome do banco.', 'is-warning');
                });
        }

        function agendar(termo) {
            window.clearTimeout(timer);
            timer = window.setTimeout(function () {
                buscar(termo);
            }, DEBOUNCE);
        }

        function escolher(indice) {
            var banco = itens[indice];
            if (!banco) {
                return;
            }
            var nome = banco.label || banco.fullName || banco.name || '';
            input.value = nome;
            selecionado = nome;
            definirCodigo(banco.code || '');
            fechar();
            input.focus();
            input.dispatchEvent(new Event('change', { bubbles: true }));
        }

        input.addEventListener('input', function () {
            if (input.value.trim() !== selecionado) {
                definirCodigo('');
            }
            ultimoTermo = input.value.trim();
            agendar(ultimoTermo);
        });

        input.addEventListener('focus', function () {
            if (itens.length && lista.innerHTML) {
                abrir();
                return;
            }
            if (ultimoTermo === null || input.value.trim() !== ultimoTermo) {
                ultimoTermo = input.value.trim();
            }
            agendar(ultimoTermo);
        });

        input.addEventListener('keydown', function (evento) {
            var tecla = evento.key;
            if (tecla === 'ArrowDown') {
                evento.preventDefault();
                if (!aberto) {
                    agendar(input.value.trim());
                    return;
                }
                marcarAtivo(ativo + 1);
            } else if (tecla === 'ArrowUp') {
                evento.preventDefault();
                marcarAtivo(ativo - 1);
            } else if (tecla === 'Enter') {
                if (aberto && ativo >= 0) {
                    evento.preventDefault();
                    escolher(ativo);
                }
            } else if (tecla === 'Escape') {
                if (aberto) {
                    evento.preventDefault();
                    fechar();
                }
            } else if (tecla === 'Tab') {
                fechar();
            }
        });

        lista.addEventListener('mousedown', function (evento) {
            // mousedown evita que o blur do input feche a lista antes do clique
            evento.preventDefault();
        });

        lista.addEventListener('click', function (evento) {
            var opcao = evento.target.closest ? evento.target.closest('[data-indice]') : null;
            if (!opcao) {
                return;
            }
            escolher(parseInt(opcao.getAttribute('data-indice'), 10));
        });

        input.addEventListener('blur', function () {
            window.setTimeout(fechar, 140);
        });

        document.addEventListener('click', function (evento) {
            if (!picker.contains(evento.target)) {
                fechar();
            }
        });

        return { fechar: fechar };
    }

    function iniciar() {
        var pickers = document.querySelectorAll('[data-bank-picker]');
        for (var i = 0; i < pickers.length; i++) {
            criar(pickers[i]);
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', iniciar);
    } else {
        iniciar();
    }
})();
