# APPFINANCE

Sistema financeiro pessoal e empresarial simples, responsivo e mobile-first, construído em PHP 8.x, MySQL/MariaDB, HTML5, CSS3 e JavaScript, com foco em hospedagem compartilhada Apache/HostGator. A aplicação mantém o framework MVC próprio herdado do projeto-base e evolui sua estrutura sem dependências que exijam Node.js ou processos permanentes no servidor.

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
