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

## Arquitetura proposta

A arquitetura evoluída mantém o MVC simples e acrescenta uma camada de domínio compatível com hospedagem compartilhada:

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

As novas entidades financeiras devem sempre conter `user_id`, utilizar prepared statements, validar todos os identificadores recebidos, limitar resultados e aplicar o escopo do usuário na consulta. O saldo disponível será calculado com base em saldo inicial e movimentações efetivadas: despesas pendentes não reduzem o saldo, receitas previstas não aumentam o saldo e transferências entre contas não entram como receita ou despesa.

## Escopo funcional da evolução

A aplicação terá uma tela única de **Novo Lançamento** para receitas e despesas, com recorrência opcional e campos avançados recolhíveis. Também contará com contas financeiras, categorias, centros de custo, lançamentos com status e filtros, recorrências sem duplicidade, investimentos, aplicações, resgates, rendimentos manuais, rankings baseados exclusivamente nos dados cadastrados pelo usuário, fluxo de caixa, relatórios e exportação CSV/PDF quando compatível com a hospedagem.

O dashboard apresentará saldo total, receitas, despesas, resultado do mês, total investido, rendimentos, evolução mensal, composição de despesas, maiores receitas, próximos vencimentos, alertas calculados e comparação de rentabilidade absoluta e percentual. Nenhuma afirmação sobre bancos externos será feita sem fonte ou integração externa autorizada.

## Banco de dados e migrations

A migration base existente continua sendo a origem das tabelas de autenticação, RBAC, multi-tenant e auditoria. As migrations financeiras serão adicionadas em arquivos SQL sequenciais e idempotentes, com chaves estrangeiras e índices para `user_id`, `account_id`, `category_id`, `cost_center_id`, `transaction_date`, `due_date` e `status`.

As credenciais da produção não são armazenadas no GitHub. Para instalação, copie `.env.example` para `.env`, preencha apenas o ambiente escolhido e execute o instalador protegido ou os arquivos SQL pelo phpMyAdmin. O arquivo `.env` está ignorado pelo Git.

## Segurança

O sistema utiliza `password_hash`, `password_verify`, prepared statements com emulação desativada, escape de saída HTML, token CSRF em formulários de escrita, cookies de sessão `HttpOnly`/`SameSite`, headers básicos de segurança, auditoria e autorização por usuário. Toda query financeira deverá filtrar pelo usuário autenticado e toda operação de escrita relevante deverá registrar auditoria.

## Desenvolvimento local

1. Copie `.env.example` para `.env` e configure um banco MySQL/MariaDB local.
2. Execute `database/migrations/0001_core_schema.sql`, as migrations financeiras em ordem e os seeds.
3. Aponte o document root do Apache para `public/` ou utilize o `.htaccess` da raiz em um ambiente compatível.
4. Para PHP embutido em desenvolvimento, execute `php -S localhost:8000 -t public public/index.php`.
5. Acesse `/login` e altere imediatamente a senha do usuário administrativo inicial quando o seed for utilizado.

## HostGator/cPanel

Consulte [`DEPLOY_HOSTGATOR.md`](./DEPLOY_HOSTGATOR.md) para upload, configuração do document root, criação do banco, permissões de `storage/`, versão do PHP, HTTPS e limpeza dos scripts de instalação/diagnóstico após o uso. O sistema foi desenhado para funcionar sem Docker, Redis, workers ou servidor Node permanente.

### CONFIGURAÇÃO DO BANCO DE PRODUÇÃO PENDENTE

A configuração real do banco da HostGator ainda não foi conectada. Quando as migrations, a interface e os testes estiverem validados, o sistema estará pronto para receber as credenciais de produção.

## Qualidade e testes

Os testes devem cobrir autenticação, isolamento por usuário, criação e edição de contas, receitas, despesas, recorrências, pagamentos, investimentos, rendimentos, transferências, cálculos do dashboard, filtros, exportação e visualização em desktop, tablet e celular. Também devem verificar que uma transferência entre contas não é contabilizada como receita ou despesa.

## Repositório original

O repositório `ASOARESBH/phppadrao` foi usado apenas como origem da base. O desenvolvimento ocorre de forma independente neste repositório `APPFINANCE`; o projeto original não deve ser alterado.
