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
