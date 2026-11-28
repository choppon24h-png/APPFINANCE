# Deploy no HostGator (cPanel) — hospedagem compartilhada

Este projeto foi desenhado para rodar em hospedagem compartilhada, sem SSH e
sem precisar rodar `composer install` no servidor. Siga os passos abaixo.

## 1. Envie os arquivos

1. Acesse o **cPanel** > **Gerenciador de Arquivos**.
2. Entre na pasta raiz do domínio (geralmente `public_html`, ou a pasta do
   subdomínio/addon domain que você for usar).
3. Envie o `.zip` deste projeto e clique com o botão direito nele > **Extrair**.
4. Ative "mostrar arquivos ocultos" nas configurações do Gerenciador de
   Arquivos para confirmar que o `.htaccess` da raiz foi extraído (ele começa
   com ponto e fica invisível por padrão).

Ao final, `public_html` deve conter diretamente `app/`, `public/`, `routes/`,
`.htaccess`, `composer.json` etc — **não** uma subpasta extra.

## 2. Crie o banco de dados

1. cPanel > **Bancos de Dados MySQL**.
2. Crie um banco (ex: `seuusuario_appfinance`) e um usuário com senha forte.
3. Adicione o usuário ao banco com **todos os privilégios**.

Anote banco, usuário e senha — no HostGator eles vêm sempre prefixados com o
seu usuário cPanel (ex: `chguser_appfinance`).

## 3. Configure o `.env`

1. No Gerenciador de Arquivos, renomeie `.env.example` para `.env`.
2. Edite e preencha:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://seu-dominio.com.br
APP_SECRET=gere_uma_string_aleatoria_de_32_caracteres

DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=seuusuario_appfinance
DB_USERNAME=seuusuario_dbuser
DB_PASSWORD=sua_senha_forte
```

`APP_SECRET` não é decorativo: ele protege os scripts `_instalar.php` e
`_diagnostico.php` descritos abaixo. Gere algo aleatório, por exemplo com
`https://randomkeygen.com` (categoria "CodeIgniter Encryption Keys").

## 4. Instale as tabelas

Você tem duas opções — escolha uma:

**Opção A — pelo navegador (recomendado, não precisa de phpMyAdmin):**

Acesse `https://seu-dominio.com.br/_instalar.php?key=SEU_APP_SECRET`
(o mesmo valor que você colocou em `APP_SECRET` no `.env`). A página executa, em ordem alfabética, todas as migrations e seeds encontrados em `database/migrations/` e `database/seeds/`, incluindo as tabelas financeiras. **Apague o arquivo `public/_instalar.php` do servidor depois.**

**Opção B — via phpMyAdmin:**

**Opção B — um único arquivo SQL (mais rápido):**

1. cPanel > **phpMyAdmin**, selecione o banco criado.
2. Aba **Importar** > escolha `database/sql/somase_instalacao_completa.sql` > **Executar**.

Esse arquivo cria as 20 tabelas (incluindo a `0004`, de cadastro e login
social), carrega perfis, permissões, categorias e centros de custo padrão, e
termina com consultas de verificação. O usuário inicial é
`admin@example.com` / `Admin@123` — troque a senha no primeiro acesso.
**Ele apaga as tabelas existentes**, então use apenas em banco novo.

**Opção C — banco que já tem dados (produção):**

Importe `database/sql/somase_atualizar_banco.sql`. O script não apaga nada:
consulta o `information_schema` e só cria o que falta (colunas novas em
`users`, tabelas `user_identities` e `auth_attempts`, permissão
`access_admin_panel`). Pode ser executado quantas vezes quiser e funciona em
MySQL 5.7+/8 e MariaDB 10.3+, sem precisar de privilégio para criar
procedimentos.

**Opção D — migrations uma a uma (manual):**

1. `database/migrations/0001_core_schema.sql`
2. `database/migrations/0002_cnpj_lookup.sql`
3. `database/migrations/0003_finance_schema.sql`
4. `database/migrations/0004_user_registration.sql`
5. `database/seeds/0001_admin_seed.sql` e `database/seeds/0002_finance_seed.sql`

## 4.1. Pasta de logs (importante para investigar erros)

O sistema grava tudo em `storage/logs/` (`app-AAAA-MM-DD.log`,
`erros-AAAA-MM-DD.log` e `php_errors.log`). No Gerenciador de Arquivos,
confirme que `storage/logs` existe e está com permissão **755**.

Se a pasta não aceitar escrita, o PHP grava no diretório temporário do
servidor e os arquivos não aparecem no painel — a página `/_logs.php` avisa
quando isso acontece.

Para ler os logs sem SSH, acesse `https://seu-dominio.com.br/_logs.php`
(logado como administrador ou com `APP_SECRET`). A tela mostra os arquivos,
filtra por texto e por nível, baixa o log bruto e apaga arquivos com mais de
30 dias. Cada erro 500 exibe um **código de 8 caracteres**; informe esse
código na busca para achar a linha exata. **Apague `public/_logs.php` depois
de usar.**

### Suporte do usuário (`/_suporte.php`)

Envie também `public/_suporte.php`. É a tela que o usuário final abre pelo
link **Suporte técnico** no rodapé do menu quando um cadastro não aparece.
Ela não exige administrador e mostra: identificação da sessão, migrations
pendentes, contagem dos dados daquele usuário e o botão **Testar gravação no
banco** — que faz `INSERT` de uma conta temporária dentro de uma transação e
desfaz tudo, apontando a coluna ou tabela que falta.

Cada teste e cada cadastro (conta, lançamento, centro de custo, categoria,
investimento, forma de pagamento, tipo de investimento) gera um **código de 8
caracteres** no formato `A1B2C3D4`, exibido na mensagem de erro e gravado no
log nas linhas `*.inicio`, `*.ok` e `*.falhou`. Peça esse código ao usuário e
pesquise em `/_logs.php`.

Se o teste acusar `Unknown column 'investment_rate'` (ou outra coluna da
migration 0007), o banco está desatualizado: rode `/_atualizar.php` ou
importe `database/sql/somase_mysql_unico.sql`. **Você pode manter
`public/_suporte.php` no servidor** — ela não expõe dados de outros usuários
— mas apague-a se preferir não divulgar a página.

## 5. Permissões de pastas

O PHP precisa gravar em `storage/` (sessões, logs, uploads). No Gerenciador
de Arquivos, clique com o botão direito em `storage` > **Permissions** e
defina `755` (recursivamente em `storage/logs`, `storage/sessions` e
`storage/uploads` também, se o "aplicar recursivamente" não fizer isso
automaticamente).

## 6. Versão do PHP e extensões

1. cPanel > **Selecionar Versão do PHP** (ou **MultiPHP Manager**).
2. Defina a versão para **PHP 8.1** ou superior.
3. Confirme que estas extensões estão ativas (normalmente já vêm ligadas):
   `pdo_mysql`, `mbstring`, `json`, `fileinfo`, `openssl`.

Você pode confirmar tudo isso pela própria aplicação — veja o próximo passo.

## 7. Confira com o diagnóstico

Acesse `https://seu-dominio.com.br/_diagnostico.php?key=SEU_APP_SECRET` para
ver versão do PHP, extensões, permissões de pasta e conexão com o banco numa
única tela. **Apague `public/_diagnostico.php` do servidor depois de usar.**

Para conferir o esquema e aplicar a atualização da etapa de acesso
(migration `0004_user_registration.sql`), abra `/_atualizar.php`:

- se você já estiver logado como administrador, a página abre direto;
- caso contrário, informe o `APP_SECRET` do `.env` no formulário.

Ela lista o que falta (tabelas `user_identities`/`auth_attempts`, colunas
`birth_date`, `auth_provider`, `avatar_url`, `email_verified_at`,
`terms_accepted_at`, `registration_ip` e a permissão `access_admin_panel`),
mostra os últimos erros do log e tem o botão **Aplicar atualização do banco**.
O comando é idempotente: pode repetir sem risco. **Apague `public/_atualizar.php`
depois de usar.**

> Sempre que enviar uma versão nova do código, rode essa página uma vez.
> Se o código estiver na frente do banco, o sistema mostra a tela
> "Banco de dados precisa ser atualizado" em vez de erro 500.

## 8. Acesse o sistema

Vá em `https://seu-dominio.com.br/login`.

- **E-mail:** `admin@example.com`
- **Senha:** `Admin@123`

> Troque essa senha assim que entrar (não há tela de "alterar senha" pronta
> no esqueleto — adicione uma, ou atualize a coluna `password` do usuário
> diretamente no banco com `password_hash()`).

## Como o roteamento funciona sem VirtualHost/SSH

1. O `.htaccess` da raiz redireciona tudo para a pasta `public/` — assim o
   *document root* pode continuar sendo `public_html` (comum em planos
   compartilhados, onde você não consegue apontar o domínio direto para uma
   subpasta).
2. O `.htaccess` dentro de `public/` redireciona tudo para `index.php`
   (front controller único).
3. `app/autoload.php` é um autoloader PSR-4 manual — **não depende do
   Composer estar disponível no servidor**. Este projeto não tem nenhuma
   dependência obrigatória em runtime, então nem é preciso enviar uma pasta
   `vendor/`.
4. As sessões PHP são salvas em `storage/sessions` (em vez do diretório
   temporário padrão do servidor), evitando problemas comuns de permissão em
   hospedagem compartilhada.
5. `app/`, `config/`, `database/` e `storage/` têm `.htaccess` próprios
   bloqueando acesso HTTP direto, como camada extra de proteção.

## Depois de instalar

- Apague `public/_instalar.php` e `public/_diagnostico.php`.
- Troque a senha do `admin@example.com`.
- Se não for usar multi-tenant, você pode remover `tenants`/`user_tenants`
  e as rotas de "selecionar empresa" (veja o `README.md`).

## Rodada 27/11/2026 — documentos, imóveis e lote

1. **Banco primeiro**: importe `database/migrations/0006_documents_properties.sql` no phpMyAdmin (banco `inlaud99_appfinance`). Pode rodar duas vezes: a segunda não faz nada.
2. Envie os arquivos alterados (veja a lista no relatório da rodada), incluindo `app/Services/Documents/`, `app/Controllers/DocumentController.php`, `app/Controllers/ImportController.php`, as views novas e `public/assets/js/documents.js` e `import.js`.
3. Crie `storage/uploads` com permissão **775** (fora de `public_html`, como `storage/logs`).
4. Confira no `.env`: `ATTACHMENT_MAX_MB=10`; opcionalmente `OCR_SPACE_API_KEY` e `OCR_SPACE_ENGINE=2`.
5. Teste: abrir `/lancamentos/novo`, colar um código de boleto e conferir valor/vencimento; importar um OFX pequeno; abrir um anexo e confirmar que **sem login** a rota redireciona para `/login`.
## Rodada 28/11/2026 — CEP, dashboard, formas de pagamento e investimentos
1. **Banco primeiro**: importe `database/migrations/0007_cep_payments_investments.sql` no phpMyAdmin (banco `inlaud99_appfinance`). É idempotente: rodar duas vezes não gera erro nem duplica os catálogos (usa `INSERT ... SELECT ... FROM DUAL WHERE NOT EXISTS`). Alternativa: use `database/sql/somase_atualizar_banco.sql`, já com a 0007 incluída.
2. Envie os arquivos alterados: `app/Models/{PaymentMethod,InvestmentType,CostCenter,Account,Investment}.php`, `app/Services/{CepService,InvestmentProjection,InvestmentService,FinanceService,Slug}.php`, `app/Controllers/{CepController,PaymentMethodController,InvestmentTypeController,CatalogController,AccountController,InvestmentController,TransactionController}.php`, as views novas/alteradas (`catalog/payment_methods.php`, `investments/*.php`, `catalog/cost_centers.php`, `transactions/*.php`, `accounts/form.php`, `layout/app_header.php`), `public/assets/js/cep.js`, `public/assets/css/app.css` e `routes/web.php`.
3. Crie `storage/cache/cep` com permissão **775** (fora de `public_html`, igual a `storage/logs`). Sem escrita, a busca de CEP continua funcionando, só não guarda cache.
4. Não há variável de ambiente nova obrigatória. A ordem dos provedores de CEP é fixa (ViaCEP → BrasilAPI → OpenCEP) e não exige chave. As taxas de referência (CDI/Selic 10,65% a.a., IPCA 4,50% a.a.) ficam em `app/Models/InvestmentType.php` (`REFERENCE_RATES`) para ajuste manual quando o Copom mudar.
5. Teste em produção, nesta ordem: `/centros-custo` (digitar `01310-100` e conferir rua/bairro/cidade/UF); `/lancamentos` (deve abrir com o chip "Mostrando apenas débitos de…" e cinco cartões); `/lancamentos/novo` (digitar minúsculas e conferir que grava em MAIÚSCULA, e ver "DÉBITO EM CONTA" na lista); `/formas-pagamento`; `/investimentos/tipos`; `/investimentos` (botão "Lançar estimado").
6. Se o sistema mostrar 503 "Banco de dados precisa ser atualizado", a 0007 ainda não foi importada — importe e recarregue. Nada é perdido: a migration só adiciona colunas/tabelas e semeia catálogos.
## Se a tela mostrar 503 "Banco de dados inconsistente"
1. Isso significa que o código novo está no ar e falta uma migration (ex.: `payment_methods` da 0007). Nenhum dado foi apagado por isso.
2. Abra `/_atualizar.php` logado como administrador e clique em **Aplicar migrations pendentes**. Ele detecta 0004, 0005, 0006 e 0007 e executa só o que falta.
3. Confira a seção **Seus dados**. Se contas e lançamentos estiverem zerados, o banco foi recriado (uso indevido de `somase_instalacao_completa.sql`): restaure o backup do cPanel antes de continuar.
4. Enquanto a migration não for aplicada, o sistema segue no ar com o aviso "Banco desatualizado" no topo e as formas de pagamento antigas.
## Arquivo único do MySQL (recomendado)
`database/sql/somase_mysql_unico.sql` serve para banco novo **e** para banco com dados. Ele não tem `DROP`, `TRUNCATE` nem `DELETE`: cria as tabelas que faltarem, aplica as migrations 0004 a 0007, carrega perfis, permissões, bancos, categorias e centros padrão, e só cria o `admin@example.com` se ele ainda não existir. Pode ser importado quantas vezes quiser.
1. No phpMyAdmin, selecione o banco `inlaud99_appfinance`.
2. Aba **Importar** → escolha `somase_mysql_unico.sql` → **Executar**.
3. Confira o resultado das consultas finais: 23 tabelas, 9 formas de pagamento, 14 tipos de investimento e a contagem dos seus lançamentos.
4. Se o phpMyAdmin recusar por tamanho, use `somase_atualizar_banco.sql` (menor e também idempotente) ou o `/_atualizar.php`.
