# APPFINANCE

Sistema financeiro pessoal e empresarial simples, responsivo e mobile-first, construído em PHP 8.x, MySQL/MariaDB, HTML5, CSS3 e JavaScript, com foco em hospedagem compartilhada Apache/HostGator. A aplicação mantém o framework MVC próprio herdado do projeto-base e evolui sua estrutura sem dependências que exijam Node.js ou processos permanentes no servidor.

> **Banco de dados — regra obrigatória:** o projeto mantém duas versões do SQL. Toda alteração em `database/migrations/*.sql` ou `database/seeds/*.sql` (MySQL, usado em produção) deve ser replicada em `database/postgresql/` **no mesmo commit**, rodando `python3 tools/build_postgres_sql.py && python3 tools/build_postgres_sql.py --validar && python3 tools/check_sql_parity.py`. O verificador falha quando a pasta PostgreSQL fica atrasada. Detalhes em [database/postgresql/README.md](database/postgresql/README.md).

> **Estado da configuração de produção:** o projeto não está conectado ao banco de produção. As credenciais reais da HostGator deverão ser informadas somente após a validação da estrutura, das migrations e dos testes locais.

## Diagnóstico técnico inicial

A auditoria foi realizada antes da implementação da evolução solicitada. O projeto atual é um esqueleto MVC em PHP puro, com autoload PSR-4 manual, roteador próprio, PDO para MySQL/MariaDB, autenticação por sessão, RBAC orientado a banco, suporte opcional a multi-tenant, CSRF, auditoria e um endpoint específico de consulta de CNPJ.

| Área auditada | Situação encontrada | Impacto para a evolução |
|---|---|---|
| Linguagem | PHP 8.1 ou superior, com HTML, CSS e JavaScript | Compatível com PHP 8.x da HostGator |
| Framework | Nenhum framework de terceiros; MVC e Router próprios | Preservar a base reduz dependências e simplifica o deploy |
| Banco | PDO com MySQL/MariaDB, prepared statements e `utf8mb4` | Adicionar migrations versionadas e índices financeiros |
| Tabelas | `roles`, `permissions`, `role_permissions`, `users`, `tenants`, `user_tenants`, `audit_logs`, `cnpj_cache` e `cnpj_rate_limit` | Não havia tabelas de contas, lançamentos, recorrências ou investimentos |
| Autenticação | Login/logout por sessão, `password_hash`/`password_verify`, role e permissões | Reaproveitar e reforçar isolamento por `user_id` |
| Rotas | Login, seleção de empresa, dashboard, usuários e CNPJ | Criar rotas autenticadas para dashboard, lançamentos, contas, investimentos, cadastros e relatórios |
| Dashboard | Placeholder com contagem de usuários | Substituir por indicadores financeiros agregados |
| Interface | Bootstrap via CDN, sidebar fixa e CSS mínimo | Adotar layout mobile-first, navegação adaptativa e lançamento rápido |
| APIs | `GET /api/cnpj/{cnpj}` com fallback, cache, rate-limit e auditoria | Preservar o endpoint e adicionar APIs financeiras em PHP |
| Instalação | `_instalar.php` executava somente a migration principal e o seed administrativo | Atualizar o instalador para executar todas as migrations/seed versionados |
| Deploy | `.htaccess`, document root em `public/` e armazenamento de sessão em `storage/` | Manter o modelo compatível com Apache compartilhado |

### Funcionalidades preservadas

A evolução preserva o autoload manual, a conexão PDO, o roteador com grupos e middlewares, a autenticação existente, o RBAC, o suporte opcional a tenants, o registro de auditoria, a consulta de CNPJ e os scripts de diagnóstico e instalação. O CRUD de usuários continua disponível para perfis com a permissão `manage_users`.

### Problemas encontrados

O projeto inicial não possuía domínio financeiro implementado: não havia contas, categorias, centros de custo, lançamentos, recorrências, investimentos, rendimentos, transferências, relatórios ou regras de atualização de saldo. O dashboard era apenas uma tela demonstrativa, a navegação apresentava somente duas áreas e o CSS não contemplava os requisitos mobile-first, PWA, gráficos, filtros e cards responsivos.

Também foi identificado que o instalador não executava automaticamente a migration de CNPJ, que não existia uma camada de serviço financeiro, que não havia paginação ou consultas agregadas do domínio, e que o isolamento de dados financeiros por usuário ainda precisava ser aplicado em todas as queries novas. A conexão com produção permanece intencionalmente pendente.

## Arquitetura implementada

A arquitetura evoluída mantém o MVC simples e acrescenta uma camada de domínio compatível com hospedagem compartilhada. A implementação atual inclui:

```text
public/
  index.php                 Front controller
  assets/css/app.css        Design system mobile-first
  assets/js/app.js          Interações globais, gráficos e navegação
  assets/js/cnpj-lookup.js  Módulo CNPJ preservado
  manifest.json             Metadados PWA
  sw.js                     Service worker sem backend permanente
app/
  Controllers/              Entrada HTTP, validação e resposta
  Core/                     Router, PDO, Auth, View, CSRF e auditoria
  Models/                   Entidades e consultas orientadas a PDO
  Services/                 Regras de saldo, recorrência e investimentos
  Views/                    Layouts, dashboard e telas de domínio
config/                     Configurações sem credenciais
routes/                     Rotas HTML e API
 database/
  migrations/               SQL versionado e idempotente
  seeds/                    Dados demonstrativos não reais
storage/                    Logs, sessões e uploads fora do público
```

As entidades financeiras implementadas contêm `user_id`, utilizam prepared statements, validam identificadores recebidos e aplicam o escopo do usuário nas consultas. O saldo disponível é calculado com base em saldo inicial e movimentações efetivadas: despesas pendentes não reduzem o saldo, receitas previstas não aumentam o saldo e transferências entre contas não entram como receita ou despesa.

## Escopo funcional da evolução

A aplicação tem uma tela única de **Novo Lançamento** para receitas e despesas, com recorrência opcional e campos avançados recolhíveis. Também conta com contas financeiras, categorias, centros de custo, lançamentos com status e filtros, recorrências sem duplicidade, investimentos, aplicações, resgates, rendimentos manuais, rankings baseados exclusivamente nos dados cadastrados pelo usuário, fluxo de caixa, relatórios e exportação CSV. A ação **Imprimir / PDF** usa o diálogo de impressão do navegador, compatível com hospedagem compartilhada e sem biblioteca externa obrigatória.

O dashboard apresenta saldo total, receitas, despesas, resultado do mês, total investido, rendimentos, evolução mensal em canvas, composição de despesas, maiores receitas, próximos vencimentos, alerta de pendências e comparação de rentabilidade absoluta e percentual. Nenhuma afirmação sobre bancos externos será feita sem fonte ou integração externa autorizada.

## Banco de dados e migrations

A migration base existente continua sendo a origem das tabelas de autenticação, RBAC, multi-tenant e auditoria. As migrations financeiras estão em `0003_finance_schema.sql`, com chaves estrangeiras e índices para `user_id`, `account_id`, `category_id`, `cost_center_id`, `transaction_date`, `due_date` e `status`. O seed financeiro `0002_finance_seed.sql` é idempotente e contém somente categorias e centros de custo demonstrativos.

As credenciais da produção não são armazenadas no GitHub. Para instalação, copie `.env.example` para `.env`, preencha apenas o ambiente escolhido e execute o instalador protegido ou os arquivos SQL pelo phpMyAdmin. O arquivo `.env` está ignorado pelo Git.

## Segurança

O sistema utiliza `password_hash`, `password_verify`, prepared statements com emulação desativada, escape de saída HTML, token CSRF em formulários de escrita, cookies de sessão `HttpOnly`/`SameSite`, headers básicos de segurança, auditoria e autorização por usuário. Toda query financeira deverá filtrar pelo usuário autenticado e toda operação de escrita relevante deverá registrar auditoria.

## Acesso: login, cadastro e painel administrativo

O login aceita e-mail/senha e, opcionalmente, Google e Microsoft. O bloqueio por tentativas usa `LOGIN_MAX_ATTEMPTS`/`LOGIN_LOCK_MINUTES`, a sessão é regenerada no login e contas inativas são recusadas com aviso. Não há envio de e-mails: a recuperação de senha orienta falar com o administrador, e a senha temporária gerada no painel é exibida uma única vez.

O cadastro valida nome completo, e-mail único, data de nascimento real (idade mínima em `REGISTRATION_MIN_AGE`), senha forte, confirmação e aceite dos termos, com honeypot e limite de `REGISTRATION_MAX_PER_HOUR` cadastros por IP. Os textos de `/termos` e `/privacidade` são modelos marcados como rascunho e precisam de revisão jurídica antes da publicação.

O painel em `/admin` exige superadministrador ou a permissão `access_admin_panel` e oferece visão geral, busca e filtros de usuários, exportação CSV, edição de nome/perfil/status, ativação/desativação, redefinição de senha e auditoria. A rota antiga `/usuarios` redireciona para `/admin/usuarios`.

Os botões Google e Microsoft ficam sempre visíveis. Enquanto as credenciais não forem preenchidas, eles aparecem com o selo **"em ativação"** e o clique volta ao login explicando o que falta. Para ativar, siga [`docs/OAUTH_SETUP.md`](./docs/OAUTH_SETUP.md) e preencha `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` e `MICROSOFT_CLIENT_ID`/`MICROSOFT_CLIENT_SECRET`/`MICROSOFT_TENANT` no `.env`.

Se o código for atualizado antes do banco, o sistema mostra a página "Banco de dados precisa ser atualizado" (503) em vez de erro 500. Abra `/_atualizar.php` (logado como administrador ou com o `APP_SECRET`) para aplicar a migration pendente, ver o estado do ambiente e os últimos erros do log.

## Logs e diagnóstico de erros

Todo erro da aplicação é registrado em `storage/logs/`, em arquivos diários:

| Arquivo | Conteúdo |
| --- | --- |
| `app-AAAA-MM-DD.log` | tudo (DEBUG, INFO, WARNING, ERROR), com contexto de cada requisição |
| `erros-AAAA-MM-DD.log` | somente ERROR/CRITICAL, já com a pilha resumida |
| `php_errors.log` | erros nativos do PHP (`error_log` do php.ini) |

Cada linha traz data/hora, nível e um **código de requisição de 8 caracteres** (`request_id`), além de método, rota, IP e usuário. O mesmo código aparece na tela de erro 500 ("Código do erro: A15D5388"), então dá para achar a falha exata no log sem adivinhar. Senhas, tokens CSRF e cookies são mascarados (`***`) antes de gravar.

O tratamento é centralizado em `app/Core/ErrorHandler.php`: ele captura exceções, warnings e erros fatais e escolhe a página correta — **503 "Banco de dados precisa ser atualizado"** quando falta a migration 0004, **503 "Banco de dados indisponível"** quando a conexão falha e **500 com código de referência** nos demais casos. O front controller (`public/index.php`) também roda dentro de `try/catch`, então nada escapa sem log.

Para ler os logs no servidor (sem SSH), abra `/_logs.php` logado como administrador ou informe o `APP_SECRET`:

- lista os arquivos, com tamanho e data;
- mostra as últimas 100/300/1.000/5.000 linhas, com filtro por texto (código do erro, e-mail, rota) e por nível (erros/avisos);
- permite baixar o arquivo bruto e apagar logs com mais de 30 dias;
- avisa quando `storage/logs` está sem permissão de escrita.

### "Cadastrei e não apareceu": suporte técnico do usuário

Quando um cadastro não aparece na tela, o caminho mais rápido é `/_suporte.php` (link **Suporte técnico** no rodapé do menu). A página é liberada para qualquer usuário logado e mostra:

- identificação da sessão (id, nome, e-mail, perfil) e o `request_id` atual;
- migrations pendentes (`Schema::pending()`) e o que exatamente falta;
- quantas contas, lançamentos, centros de custo e investimentos existem **para aquele usuário**;
- o botão **Testar gravação no banco**, que roda quatro passos dentro de uma transação com `rollback` (nada fica gravado): leitura de contas, insert com as colunas antigas, insert com as colunas da migration 0007 e leitura de `payment_methods`/`investment_types`. O resultado mostra `ok` ou a mensagem SQL completa (ex.: `SQLSTATE[42S22] ... Unknown column 'investment_rate'`);
- os últimos 15 erros/avisos do log, já sem o ruído de testes automatizados;
- um bloco **Diagnóstico para copiar**, para colar no atendimento.

Cada teste gera um **código de 8 caracteres** exibido na tela e gravado no log (`suporte.teste_gravacao.ok` ou `suporte.teste_gravacao.falhou`). Os cadastros também ganharam código próprio: `conta.cadastro`, `lancamento.cadastro`, `centro_custo.cadastro`, `categoria.cadastro`, `investimento.cadastro`, `forma_pagamento.cadastro` e `tipo_investimento.cadastro`, sempre com as etapas `.inicio`, `.ok` (com o id criado e a contagem do usuário) e `.falhou` (com a exceção, o SQLSTATE e o payload mascarado). Basta procurar o código em `/_logs.php`.

Se o teste falhar no passo "Gravação completa (com campos de investimento)" com `Unknown column`, a migration 0007 não foi aplicada: abra `/_atualizar.php` ou importe `database/sql/somase_mysql_unico.sql`. Se todos os passos passarem mas a tela continuar vazia, o problema está na listagem — compare o total mostrado em `conta.listagem` no log com o que a tela exibe.

**Sessão de um banco anterior (erro 1452).** Quando o banco é reimportado e os IDs dos usuários mudam, o navegador pode continuar com um cookie de sessão que aponta para um `user_id` inexistente. O MySQL recusa a gravação com `Integrity constraint violation: 1452 ... fk_accounts_user`, a tela mostra zero contas e o cadastro falha. O sistema agora confere o `user_id` da sessão em `users` a cada página autenticada (`Auth::ensureValidSession()`), encerra a sessão órfã e leva ao login com o aviso “Sua sessão era de um banco anterior...”. O evento fica no log como `auth.sessao_orfa`. A tela `/_suporte.php` mostra a linha **Usuário no banco** e, nesse caso, o link **Sair e entrar novamente**. Para conferir os usuários existentes e as linhas órfãs, rode `database/sql/diagnostico_usuarios.sql` (somente leitura) no phpMyAdmin.

Se `storage/logs` não for gravável, o Logger tenta criá-la com 0755 e, em último caso, grava no diretório temporário do PHP — a aplicação nunca quebra por causa do log.

## Desenvolvimento local

1. Copie `.env.example` para `.env` e configure um banco MySQL/MariaDB local.
2. Execute `database/migrations/*.sql` e `database/seeds/*.sql` em ordem, ou use `public/_instalar.php` protegido.
3. Aponte o document root do Apache para `public/` ou utilize o `.htaccess` da raiz em um ambiente compatível.
4. Para PHP embutido em desenvolvimento, execute `php -S 127.0.0.1:8000 -t public tools/router.php`.
5. Execute `php tests/SmokeTest.php` com o banco local preparado.
6. Acesse `/login` e altere imediatamente a senha do usuário administrativo inicial quando o seed for utilizado.

## HostGator/cPanel

Consulte [`DEPLOY_HOSTGATOR.md`](./DEPLOY_HOSTGATOR.md) para upload, configuração do document root, criação do banco, permissões de `storage/`, versão do PHP, HTTPS e limpeza dos scripts de instalação/diagnóstico após o uso. O sistema foi desenhado para funcionar sem Docker, Redis, workers ou servidor Node permanente.

### CONFIGURAÇÃO DO BANCO DE PRODUÇÃO PENDENTE

A configuração real do banco da HostGator ainda não foi conectada. Quando as migrations, a interface e os testes estiverem validados, o sistema estará pronto para receber as credenciais de produção.

## Qualidade e testes

A validação executada inclui lint de todos os PHP, checagem de sintaxe JavaScript e JSON, reinstalação do banco local do zero e repetida, smoke test de saldo, receita, despesa pendente, transferência, recorrência, aplicação, rendimento, resgate e agregações do dashboard, teste HTTP das rotas autenticadas, exportação CSV, assets PWA, inspeção visual do login/dashboard/lançamento e rejeição de POST sem CSRF. Também foi verificado que uma transferência entre contas não é contabilizada como receita ou despesa.

## Repositório original

O repositório `ASOARESBH/phppadrao` foi usado apenas como origem da base. O desenvolvimento ocorre de forma independente neste repositório `APPFINANCE`; o projeto original não deve ser alterado.

### Arquivos SQL prontos para importar (`database/sql/`)
| Arquivo | Quando usar | O que faz |
| --- | --- | --- |
| **`somase_mysql_unico.sql`** | **qualquer banco (recomendado)** | **arquivo único: cria as tabelas que faltarem, aplica as migrations 0004 a 0007, carrega perfis, permissões, 464 bancos, 17 categorias e 5 centros padrão, cria `payment_methods`/`investment_types` e o `admin@example.com`. Não tem `DROP`, `TRUNCATE` nem `DELETE`: pode ser importado em banco vazio ou em produção com dados, quantas vezes quiser.** |
| `somase_instalacao_completa.sql` | banco novo ou vazio | cria as 20 tabelas (já com a `0004`), carrega perfis, permissões, categorias e centros de custo padrão e cria `admin@example.com` / `Admin@123`. **Apaga as tabelas existentes.** |
| `somase_atualizar_banco.sql` | banco que já tem dados (produção) | não apaga nada: consulta o `information_schema` e cria apenas o que falta nas migrations 0004 a 0007. Idempotente, roda em MySQL 5.7+/8 e MariaDB 10.3+ sem procedures. |
| `somase_completo_com_demo.sql` | homologação e testes | dump completo do banco de desenvolvimento (4 usuários de teste, 2 contas, 101 lançamentos, investimentos e logs). **Não usar em produção.** |

Todos terminam com consultas `SELECT` de verificação, então o phpMyAdmin mostra na tela o resultado da importação. Os arquivos são gerados por `tools/build_sql.py` a partir do banco local.

**Na dúvida, use `somase_mysql_unico.sql`.** Ele substitui os dois primeiros: em banco vazio instala tudo; em banco com dados apenas completa o que falta, sem tocar nos registros existentes. Testado em banco vazio, em banco com dados e em banco sem a migration 0007 — nas três situações terminou com 23 tabelas, 9 formas de pagamento e 14 tipos de investimento.

## Leitura de documentos, imóveis e lançamento em lote (27/11/2026)

Esta rodada adiciona três frentes que conversam entre si:

### 1. Ler boleto, conta ou cupom em `/lancamentos/novo`
- O card **Ler boleto, conta ou cupom** aceita PDF, foto (inclusive câmera do celular) ou o código digitado.
- O OCR roda **no navegador**: `pdf.js 3.11.174` (texto do PDF e render da 1ª página), `@zxing/library 0.23.0` (QR Code e ITF do boleto) e `tesseract.js 5.1.1` (texto da imagem). As três bibliotecas só são baixadas quando o usuário escolhe um arquivo (jsDelivr com versão fixa).
- O texto/código é interpretado no servidor por `POST /lancamentos/ler-documento` (JSON), que devolve a sugestão de lançamento: valor, vencimento, beneficiário, CNPJ, categoria, imóvel, código e avisos.
- Regras implementadas em `app/Services/Documents/`:
  - **Boleto bancário**: linha de 47 dígitos (mód. 10 por campo + mód. 11 geral) ou código de barras de 44; valor e fator de vencimento saem do código. Fator reiniciado em 1000 no dia 22/02/2025 (FEBRABAN) — a data escolhida é a mais próxima de hoje.
  - **Arrecadação/convênio** (água, luz, gás, telefone, IPTU): linha de 48 dígitos começando com 8 (DVs por bloco) ou 44 sem DVs; valor nas posições 5–15 e segmento (1 a 7) identificado.
  - **NFC-e/NF-e**: chave de 44 dígitos (modelo 55/65), CNPJ do emitente e nº da nota; valor total vem do texto do cupom.
  - **Imóvel**: o número de instalação/medidor cadastrado em `cost_centers.identifiers` é procurado no texto; se o usuário tem um único imóvel, ele já vem selecionado.
  - **Duplicidade**: se o `document_code` já existe para o usuário, a resposta traz `duplicate: true` e o formulário avisa.
- Fallback opcional **OCR.space**: `POST /lancamentos/ler-documento/ocr` (multipart, até 1 MB). A chave fica no `.env` (`OCR_SPACE_API_KEY`), nunca no JavaScript.

### 2. Anexos privados
- Upload no próprio formulário (`enctype="multipart/form-data"`), validado por `finfo` (PDF/JPG/PNG/WEBP/HEIC/TIFF) e limitado por `ATTACHMENT_MAX_MB` (padrão 10 MB).
- Gravado fora de `public/`, em `storage/uploads/u{id}/AAAA/MM/{24 hex}.{ext}`.
- Entrega somente por `GET /lancamentos/{id}/anexo` (dono do lançamento), com `X-Content-Type-Options: nosniff` e `Content-Security-Policy: sandbox`; `?baixar=1` força download. Excluir o lançamento apaga o arquivo.
- O service worker ignora essa rota (nada de cache de documento privado).

### 3. Lançamento em lote em `/lancamentos/importar`
- Aceita **OFX** (SGML/XML, Windows-1252, FITID) e **CSV** (separador `;`, `,` ou tab; BOM; colunas data/descrição/valor ou débito/crédito; linhas de saldo ignoradas).
- Prévia (`POST /lancamentos/importar/extrato`) marca `imported` (FITID/hash já usado), `similar` (mesma conta, data e valor) e sugere categoria/centro de custo pelas descrições já usadas pelo usuário.
- Grade de revisão responsiva (360 px ok) com incluir/desincluir, edição de data, descrição, valor, tipo, categoria e imóvel.
- `POST /lancamentos/importar/confirmar` grava até 300 linhas, com erro por linha, `import_ref` único e auditoria (`import_preview`, `import`).

### 4. Imóveis e centros de custo (`/centros-custo`)
- `cost_centers.kind` (`property`, `vehicle`, `company`, `project`, `general`), `address` e `identifiers` (instalação/medidor/matrícula, separados por vírgula).
- Pílulas de tipo no formulário, campos de endereço/identificadores só para imóvel, cartões de imóvel com total do mês e atalho para `/lancamentos?cost_center_id=…&date_from=…&date_to=…`.
- Filtros `?tipo=property` na lista e `center_kind=property` em `/lancamentos`; a lista mostra o imóvel e o 📎 do anexo.

## CEP, dashboard, formas de pagamento e investimentos (28/11/2026)

### 1. CEP nos centros de custo (`/centros-custo`)
- O endereço passou a ser estruturado: `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`. O campo antigo `address` continua preenchido por `CostCenter::composeAddress()`, então relatórios e lançamentos antigos não quebram.
- Busca automática ao digitar os 8 dígitos (ou ao sair do campo) por `GET /api/cep?cep=01310-100`, com máscara, debounce e preenchimento de rua/bairro/cidade/UF.
- **Fallback em cascata**: ViaCEP → BrasilAPI → OpenCEP. A resposta informa a fonte (`{"fonte":"ViaCEP","cache":true}`) e a tela mostra "Endereço preenchido · ViaCEP". Se um provedor cair, o próximo responde; se todos falharem, o formulário segue editável (a busca nunca bloqueia o cadastro).
- Cache de 7 dias em `storage/cache/cep/` (um JSON por CEP), reduzindo latência e evitando rate-limit.

### 2. `/lancamentos` — débitos do mês e mini dashboard
- Ao abrir sem filtros, a lista mostra **somente despesas do mês corrente** (tipo `expense`, de 1º ao último dia) e exibe o chip "Mostrando apenas débitos de novembro de 2026" com o link **Ver todos** (`?filtro=1` desliga o padrão).
- Mini dashboard com cinco cartões a partir de `Transaction::summary()`: **Despesas no mês** (pagas), **Receitas no mês** (recebidas), **Receitas pendentes** (previstas + atrasadas), **Despesas pendentes** (pendentes + atrasadas) e **Receitas × Despesas** (resultado do mês).
- Os filtros de data, tipo, conta, categoria, centro de custo e busca continuam disponíveis; qualquer envio do formulário desliga o padrão.

### 3. Lançamentos em MAIÚSCULA e forma "DÉBITO EM CONTA"
- `FinanceService` normaliza descrição e observação com `mb_strtoupper` (acentos preservados) antes de gravar; o formulário também aplica maiúsculas enquanto se digita.
- O catálogo `payment_methods` (global ou por usuário) substituiu a lista fixa: 9 formas padrão, incluindo **DÉBITO EM CONTA**. Os slugs legados (`pix`, `boleto`, `credit`, `debit`, `cash`, `transfer`, `other`) continuam aceitos para não quebrar lançamentos antigos.
- Novo submenu **Categorias → Formas de pagamento** (`/formas-pagamento`): criar, editar, ativar/desativar e excluir (bloqueado quando já existe lançamento usando a forma).

### 4. Investimentos com receita estimada
- Contas do tipo `investment` aceitam **tipo de investimento** e **taxa contratada** opcionais (`accounts.investment_type_id`, `investment_rate`, `investment_rate_period`).
- Catálogo `investment_types` com 14 tipos padrão (CDB, LCI, LCA, Tesouro Selic/IPCA+/Prefixado, CDI, Poupança, Fundo DI, Ações, ETF, Previdência, Cripto, Outros), editável em **Investimentos → Tipos de investimento** (`/investimentos/tipos`).
- `investments` ganhou `investment_type_id`, `benchmark_rate` (% do CDI/Selic/IPCA) e `rate_period` (`monthly`/`yearly`).
- `InvestmentProjection` calcula a receita estimada: CDI/Selic 10,65% a.a. e IPCA 4,50% a.a. como referências no model, prefixado e taxa mensal. Exemplo: CDB de 110% do CDI sobre R$ 10.000 → **R$ 92,74/mês**.
- A tela de investimentos mostra "Receita estimada do mês", a coluna "Estimado/mês" e o botão **Lançar estimado**, que abre o rendimento já preenchido (`/investimentos/{id}/rendimento?estimado=1`). O usuário confirma o valor real do mês; a estimativa é apenas sugestão.

### Migration e ordem de deploy
- A migration desta rodada é **`database/migrations/0007_cep_payments_investments.sql`** (a anterior foi a `0006_documents_properties.sql`; o pedido citava `0005`, mas a **0005 já é a de bancos**, então foi renumerada).
- Ela é idempotente (consulta `information_schema` + `PREPARE/EXECUTE`), pode ser importada duas vezes no phpMyAdmin sem erro e não altera dados existentes (centros antigos viram `kind = 'general'`).
- **Ordem obrigatória**: 1) importar a migration no MySQL de produção; 2) enviar os arquivos; 3) conferir permissão de escrita em `storage/uploads`.
- Versão PostgreSQL regenerada por `python3 tools/build_postgres_sql.py --validar` (o gerador agora entende o padrão `information_schema` + `PREPARE` e produz `ADD COLUMN IF NOT EXISTS` / `CREATE INDEX IF NOT EXISTS`).

### Novas variáveis de ambiente
```
ATTACHMENT_MAX_MB=10
OCR_SPACE_API_KEY=
OCR_SPACE_ENGINE=2
```

### Testes desta rodada
```
php tests/DocumentsTest.php      # 62 verificações, sem banco
bash tools/validar_tudo.sh       # PHP, JS, paridade SQL e smoke test
```

## Solução de problemas: 503 "Banco de dados inconsistente"

Se aparecer `Table '...payment_methods' doesn't exist` (ou qualquer tabela/coluna da 0006/0007), o código novo chegou ao servidor antes da migration. **Os dados existentes não são afetados**: falta apenas a estrutura nova.

1. Abra `/_atualizar.php` logado como administrador (ou informe o `APP_SECRET`). A tela lista as migrations 0004 a 0007 com o status de cada uma e o que exatamente falta.
2. Clique em **Aplicar migrations pendentes**. O atualizador executa somente o que está faltando, na ordem correta, sem apagar nada.
3. Confira a seção **Seus dados**: ela mostra a contagem de usuários, contas, lançamentos, centros de custo, investimentos e catálogos. Se `transactions` e `accounts` estiverem zerados, o banco foi recriado — nesse caso, restaure o backup mais recente pelo cPanel (Arquivos → Backup) e depois aplique a migration.

Enquanto a migration não é aplicada, o sistema continua abrindo: o layout mostra o aviso **"Banco desatualizado"** no topo e os catálogos usam a lista antiga de formas de pagamento em vez de derrubar a página.

**Nunca use `database/sql/somase_instalacao_completa.sql` para atualizar um banco com dados** — esse arquivo apaga todas as tabelas antes de criar. Para atualizar, use a migration da rodada ou `somase_atualizar_banco.sql`.
