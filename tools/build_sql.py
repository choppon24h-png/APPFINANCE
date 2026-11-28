#!/usr/bin/env python3
"""Gera database/sql/*.sql a partir do banco local de desenvolvimento.

Uso: python3 tools/build_sql.py   (requer mysqldump e o banco somase_appfinance)
"""
import subprocess, pathlib, re

DB = "somase_appfinance"
MY = ["mysql", "-h", "127.0.0.1", "-usomase", "-psomase123"]
DUMP = ["mysqldump", "-h", "127.0.0.1", "-usomase", "-psomase123", "--no-tablespaces",
        "--skip-comments", "--skip-set-charset", "--skip-dump-date"]
RAIZ = pathlib.Path(__file__).resolve().parent.parent
OUT = RAIZ / "database" / "sql"
OUT.mkdir(parents=True, exist_ok=True)

def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)

def clean(sql: str) -> str:
    lines = []
    for ln in sql.splitlines():
        if "enable the sandbox mode" in ln:
            continue
        lines.append(ln)
    return "\n".join(lines).strip() + "\n"

estrutura = clean(run(DUMP + ["--no-data", DB]).stdout)
dados = clean(run(DUMP + ["--no-create-info", "--complete-insert", "--skip-extended-insert",
                          DB, "roles", "permissions", "role_permissions",
                          "categories", "cost_centers", "banks"]).stdout)

HEADER_INSTALL = """-- ============================================================
-- SOMASE — Controle Financeiro
-- INSTALACAO COMPLETA DO BANCO (MySQL 5.7+ / MySQL 8 / MariaDB 10.3+)
-- Gerado a partir do banco de desenvolvimento ja com as migrations
-- 0004 (cadastro, OAuth, painel), 0005 (bancos), 0006 (documentos e
-- imoveis) e 0007 (CEP, formas de pagamento e investimentos).
--
-- ####################################################################
-- ##  CUIDADO: ESTE ARQUIVO APAGA TODAS AS TABELAS DO BANCO.         ##
-- ##  Use SOMENTE em banco novo/vazio.                              ##
-- ##  Para atualizar um banco que ja tem dados (producao), importe   ##
-- ##  database/migrations/0007_cep_payments_investments.sql ou       ##
-- ##  somase_atualizar_banco.sql. NUNCA este arquivo.                ##
-- ####################################################################
--
-- O QUE ESTE ARQUIVO FAZ
--   * cria as tabelas do sistema (financeiro + acesso);
--   * carrega os dados essenciais: perfis, permissoes, categorias e
--     centros de custo padrao;
--   * cria o usuario inicial admin@example.com / Admin@123 (superadmin).
--
-- COMO IMPORTAR (phpMyAdmin)
--   1. selecione o banco no menu da esquerda;
--   2. aba "Importar" > "Escolher arquivo" > este arquivo > Executar;
--   3. confira no final as consultas de verificacao (ultimas linhas).
--   Via terminal: mysql -u USUARIO -p BANCO < somase_instalacao_completa.sql
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

"""

FOOTER_INSTALL = """
-- ---------- usuario inicial ----------
-- admin@example.com / Admin@123 (troque a senha no primeiro login)
ALTER TABLE `users` AUTO_INCREMENT = 1;
INSERT INTO `users` (`name`, `email`, `password`, `role_id`, `status`, `auth_provider`,
                     `email_verified_at`, `terms_accepted_at`, `created_at`, `updated_at`)
SELECT 'Administrador', 'admin@example.com',
       '$2b$10$vWAdPPDyhPW0u/UeSpdf1eLsXidEiwemycK/I9x7I1DcVjCLSTJii',
       r.id, 'active', 'local', NOW(), NOW(), NOW(), NOW()
FROM `roles` r
WHERE r.slug = 'superadmin'
  AND NOT EXISTS (SELECT 1 FROM `users` WHERE `email` = 'admin@example.com');

SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;

-- ============================================================
-- VERIFICACAO (deve retornar 20 tabelas e 1 usuario)
-- ============================================================
SELECT COUNT(*) AS tabelas_criadas
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE';

SELECT (SELECT COUNT(*) FROM `roles`)            AS perfis,
       (SELECT COUNT(*) FROM `permissions`)      AS permissoes,
       (SELECT COUNT(*) FROM `role_permissions`) AS vinculos,
       (SELECT COUNT(*) FROM `categories`)       AS categorias,
       (SELECT COUNT(*) FROM `cost_centers`)     AS centros_de_custo,
       (SELECT COUNT(*) FROM `users`)            AS usuarios;

SELECT id, name, email, status FROM `users`;
"""

install = HEADER_INSTALL + estrutura + "\n" + dados + FOOTER_INSTALL
(OUT / "somase_instalacao_completa.sql").write_text(install)

# ---------------------------------------------------------------- atualizacao
COLS = [
    ("birth_date", "DATE NULL AFTER `status`"),
    ("auth_provider", "ENUM('local','google','microsoft') NOT NULL DEFAULT 'local' AFTER `birth_date`"),
    ("avatar_url", "VARCHAR(255) NULL AFTER `auth_provider`"),
    ("email_verified_at", "DATETIME NULL AFTER `avatar_url`"),
    ("terms_accepted_at", "DATETIME NULL AFTER `email_verified_at`"),
    ("registration_ip", "VARCHAR(45) NULL AFTER `terms_accepted_at`"),
]
IDX = [("idx_users_provider", "`auth_provider`"), ("idx_users_created", "`created_at`")]

blocks = []
for col, ddl in COLS:
    ddl_esc = ddl.replace("'", "''")
    blocks.append(f"""-- users.{col}
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD COLUMN `{col}` {ddl_esc}',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = '{col}');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
""")

for name, cols in IDX:
    blocks.append(f"""-- indice users.{name}
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD INDEX `{name}` ({cols})',
        'DO 0')
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND INDEX_NAME = '{name}');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
""")

atualizacao = """-- ============================================================
-- SOMASE — ATUALIZACAO SEGURA DO BANCO (migration 0004)
-- Cadastro de usuarios, login social (Google/Microsoft) e painel admin.
--
-- Use este arquivo quando o banco JA TEM dados (producao).
-- Ele NAO apaga nada: so cria o que estiver faltando.
-- Pode ser executado quantas vezes quiser (idempotente).
--
-- Requer MySQL 5.7+/8 ou MariaDB 10.3+ e usuario com permissao de
-- ALTER/CREATE no banco. Nao usa procedures: cada passo consulta o
-- information_schema e so executa o ALTER quando necessario.
--
-- IMPORTANTE: selecione o banco antes de importar (USE banco; ou
-- clique no banco no phpMyAdmin). O script age sempre no banco atual.
-- ============================================================

SET NAMES utf8mb4;

-- ---------- 0. o banco tem a tabela users? ----------
SET @tem_users := (SELECT COUNT(*) FROM information_schema.TABLES
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users');
SET @msg := IF(@tem_users = 0,
    'ERRO: a tabela users nao existe neste banco. Importe somase_instalacao_completa.sql.',
    'OK: tabela users encontrada.');
SELECT @msg AS verificacao_inicial;

""" + "\n".join(blocks) + """
-- ---------- vinculo OAuth (Google/Microsoft) ----------
CREATE TABLE IF NOT EXISTS `user_identities` (
    `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`          INT UNSIGNED NOT NULL,
    `provider`         ENUM('google','microsoft') NOT NULL,
    `provider_user_id` VARCHAR(191) NOT NULL,
    `email`            VARCHAR(255) NULL,
    `last_login_at`    DATETIME NULL,
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_identity_provider` (`provider`, `provider_user_id`),
    KEY `idx_identity_user` (`user_id`),
    KEY `idx_identity_email` (`email`),
    CONSTRAINT `fk_identity_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- tentativas de autenticacao (rate-limit) ----------
CREATE TABLE IF NOT EXISTS `auth_attempts` (
    `id`         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `ip`         VARCHAR(45) NOT NULL,
    `email`      VARCHAR(255) NULL,
    `action`     ENUM('login','register','oauth') NOT NULL,
    `success`    TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY `idx_attempts_lookup` (`action`, `ip`, `email`, `created_at`),
    KEY `idx_attempts_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- permissao do painel administrativo ----------
INSERT INTO `permissions` (`slug`, `name`, `group_name`)
VALUES ('access_admin_panel', 'Acessar painel administrativo', 'administracao')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `group_name` = VALUES(`group_name`);

INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r, `permissions` p
WHERE r.slug = 'admin' AND p.slug = 'access_admin_panel';

-- ---------- categorias e centros de custo padrao (se o banco estiver vazio) ----------
INSERT INTO `categories` (`user_id`, `name`, `type`, `icon`, `color`, `status`)
SELECT NULL, 'Alimentacao', 'expense', 'utensils', '#ef4444', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `categories` WHERE `user_id` IS NULL);

INSERT INTO `cost_centers` (`user_id`, `name`, `status`)
SELECT NULL, 'Geral', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `cost_centers` WHERE `user_id` IS NULL);

-- ============================================================
-- VERIFICACAO — o esperado e 2 tabelas novas, 6 colunas novas em
-- users e a permissao do painel presente.
-- ============================================================
SELECT
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('user_identities','auth_attempts')) AS tabelas_oauth,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
        AND COLUMN_NAME IN ('birth_date','auth_provider','avatar_url','email_verified_at',
                            'terms_accepted_at','registration_ip')) AS colunas_novas,
    (SELECT COUNT(*) FROM `permissions` WHERE `slug` = 'access_admin_panel') AS permissao_painel;

SELECT 'Atualizacao concluida. Abra /login e entre com sua conta.' AS resultado;
"""
# ---------- 0005: catalogo de bancos (ALTERs idempotentes) ----------
migracao_bancos = (RAIZ / "database" / "migrations" / "0005_banks.sql").read_text(encoding="utf-8")
corpo_bancos = "\n".join(
    linha for linha in migracao_bancos.splitlines()
    if not linha.lstrip().startswith("--") and linha.strip() not in ("", "SET NAMES utf8mb4;")
)
coluna_bank_code = """SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `accounts` ADD COLUMN `bank_code` CHAR(3) NULL AFTER `bank_name`',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'accounts' AND COLUMN_NAME = 'bank_code');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;"""
indice_bank_code = """SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `accounts` ADD INDEX `idx_accounts_bank` (`bank_code`)',
        'DO 0')
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'accounts' AND INDEX_NAME = 'idx_accounts_bank');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;"""
corpo_bancos = corpo_bancos.replace(
    "ALTER TABLE `accounts` ADD COLUMN `bank_code` CHAR(3) NULL AFTER `bank_name`;", coluna_bank_code)
corpo_bancos = corpo_bancos.replace(
    "ALTER TABLE `accounts` ADD INDEX `idx_accounts_bank` (`bank_code`);", indice_bank_code)

atualizacao += """
-- ============================================================
-- 0005 — CATALOGO DE BANCOS BRASILEIROS (codigo COMPE)
-- Alimenta o autocomplete do formulario de conta.
-- Idempotente: pode ser executado novamente sem duplicar registros.
-- ============================================================
""" + corpo_bancos + "\n"

# ---------- 0006 em diante: migrations idempotentes incluídas na íntegra ----------
# Cada arquivo usa information_schema + PREPARE/EXECUTE e seeds com
# "INSERT ... SELECT ... WHERE NOT EXISTS", então pode ser importado em
# um banco que já tem parte da estrutura sem erro e sem duplicar dados.
extras = [p for p in sorted((RAIZ / "database" / "migrations").glob("0*.sql"))
          if p.name >= "0006"]
extras_blocos = []
for caminho in extras:
    corpo = "\n".join(
        linha for linha in caminho.read_text(encoding="utf-8").splitlines()
        if not linha.lstrip().startswith("--") and linha.strip() not in ("", "SET NAMES utf8mb4;")
    )
    bloco = (
        "\n-- ============================================================\n"
        f"-- {caminho.name} — incluída integralmente (idempotente)\n"
        "-- ============================================================\n"
        + corpo + "\n"
    )
    extras_blocos.append(bloco)
    atualizacao += bloco

atualizacao += """
-- ============================================================
-- VERIFICACAO FINAL — esperado: 1 em cada coluna abaixo
-- ============================================================
SELECT
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payment_methods') AS tabela_formas_pagamento,
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'investment_types') AS tabela_tipos_investimento,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers'
        AND COLUMN_NAME = 'zip_code') AS coluna_cep,
    (SELECT COUNT(*) FROM `payment_methods`) AS formas_cadastradas,
    (SELECT COUNT(*) FROM `investment_types`) AS tipos_cadastrados;

SELECT 'Atualizacao concluida. Recarregue o sistema e teste as telas.' AS resultado;
"""

(OUT / "somase_atualizar_banco.sql").write_text(atualizacao)

# ---------------------------------------------------------------- completo com demo
demo = clean(run(DUMP + ["--routines=false", "--triggers=false", DB]).stdout)
header_demo = """-- ============================================================
-- SOMASE — DUMP COMPLETO DO BANCO DE DESENVOLVIMENTO (com dados de exemplo)
-- 20 tabelas + dados: 4 usuarios de teste, 2 contas, 101 lancamentos,
-- categorias, centros de custo, investimentos e logs.
--
-- Serve para montar um ambiente de homologacao identico ao testado.
-- NAO use em producao: contem usuarios e senhas de teste.
-- Senhas conhecidas: admin@example.com/Admin@123, admin@somase.com/Somase@2026,
-- maria.teste@example.com/Senha@123, lucas.oauth@example.com/Somase@2026
--
-- ATENCAO: as tabelas existentes sao APAGADAS.
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

"""
footer_demo = """
SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;

SELECT (SELECT COUNT(*) FROM `users`) AS usuarios,
       (SELECT COUNT(*) FROM `transactions`) AS lancamentos,
       (SELECT COUNT(*) FROM `accounts`) AS contas;
"""
(OUT / "somase_completo_com_demo.sql").write_text(header_demo + demo + footer_demo)

for f in sorted(OUT.glob("*.sql")):
    print(f.name, f.stat().st_size, "bytes")


# ---------------------------------------------------------------- arquivo unico
# Serve para banco novo E para banco que ja tem dados: cria apenas o que falta,
# aplica 0004..0007 e carrega os catalogos, sem DROP/TRUNCATE.
def consultar(sql: str) -> list[list[str]]:
    saida = run(MY + ["-N", "-B", "-e", sql, DB]).stdout
    return [linha.split("\t") for linha in saida.splitlines() if linha.strip()]


def esc(valor: str) -> str:
    return valor.replace("\\", "\\\\").replace("'", "''")


# mysqldump coloca DROP TABLE antes de cada CREATE; no arquivo unico isso
# apagaria os dados, entao as linhas de DROP sao removidas.
estrutura_sem_drop = re.sub(r"^DROP TABLE IF EXISTS .*;\n", "", estrutura, flags=re.M)
estrutura_unica = re.sub(r"^CREATE TABLE `", "CREATE TABLE IF NOT EXISTS `", estrutura_sem_drop, flags=re.M)

# Dados de acesso e bancos: INSERT IGNORE usa as chaves unicas existentes.
dados_acl = clean(run(DUMP + ["--no-create-info", "--complete-insert", "--skip-extended-insert",
                              DB, "roles", "permissions", "role_permissions"]).stdout)
dados_bancos = clean(run(DUMP + ["--no-create-info", "--complete-insert", "--skip-extended-insert",
                                 DB, "banks"]).stdout)
dados_acl = dados_acl.replace("INSERT INTO", "INSERT IGNORE INTO")
dados_bancos = dados_bancos.replace("INSERT INTO", "INSERT IGNORE INTO")

seeds_categorias = []
for nome, tipo, icone, cor, status in consultar(
        "SELECT name, type, IFNULL(icon,''), IFNULL(color,''), status "
        "FROM categories WHERE user_id IS NULL ORDER BY id"):
    seeds_categorias.append(
        "INSERT INTO `categories` (`user_id`, `name`, `type`, `icon`, `color`, `status`)\n"
        f"SELECT NULL, '{esc(nome)}', '{esc(tipo)}', '{esc(icone)}', '{esc(cor)}', '{esc(status)}' FROM DUAL\n"
        f"WHERE NOT EXISTS (SELECT 1 FROM `categories` WHERE `user_id` IS NULL "
        f"AND `name` = '{esc(nome)}' AND `type` = '{esc(tipo)}');"
    )

seeds_centros = []
for nome, tipo, status in consultar(
        "SELECT name, IFNULL(kind,'general'), status FROM cost_centers "
        "WHERE user_id IS NULL ORDER BY id"):
    seeds_centros.append(
        "INSERT INTO `cost_centers` (`user_id`, `name`, `kind`, `status`)\n"
        f"SELECT NULL, '{esc(nome)}', '{esc(tipo)}', '{esc(status)}' FROM DUAL\n"
        f"WHERE NOT EXISTS (SELECT 1 FROM `cost_centers` WHERE `user_id` IS NULL AND `name` = '{esc(nome)}');"
    )

HEADER_UNICO = """-- ============================================================
-- SOMASE — Controle Financeiro
-- ARQUIVO UNICO DO MYSQL (MySQL 5.7+ / MySQL 8 / MariaDB 10.3+)
--
-- Serve para os dois cenarios, sem precisar escolher outro arquivo:
--   * banco novo/vazio  -> cria tudo e carrega os catalogos;
--   * banco com dados   -> cria somente o que falta, preserva tudo.
--
-- ####################################################################
-- ##  ESTE ARQUIVO NAO APAGA NADA.                                   ##
-- ##  Nao existe DROP TABLE, TRUNCATE ou DELETE.                     ##
-- ##  Pode ser importado quantas vezes quiser (idempotente).         ##
-- ####################################################################
--
-- O QUE ELE FAZ, NESTA ORDEM
--   1. cria as tabelas que faltarem (CREATE TABLE IF NOT EXISTS);
--   2. aplica as migrations 0004, 0005, 0006 e 0007 (colunas, indices,
--      payment_methods, investment_types e campos de investimento);
--   3. carrega perfis, permissoes, bancos, categorias e centros padrao,
--      sempre com WHERE NOT EXISTS / INSERT IGNORE (nada duplica);
--   4. cria o usuario inicial admin@example.com / Admin@123 se ainda
--      nao existir (troque a senha depois);
--   5. termina com consultas de verificacao.
--
-- COMO IMPORTAR (phpMyAdmin)
--   1. selecione o banco no menu da esquerda;
--   2. aba "Importar" > "Escolher arquivo" > somase_mysql_unico.sql > Executar;
--   3. confira as consultas de verificacao no final.
--   Via terminal: mysql -u USUARIO -p BANCO < somase_mysql_unico.sql
--
-- Para atualizar pela interface, sem SQL: /_atualizar.php
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

-- ============================================================
-- 1. ESTRUTURA — cria apenas as tabelas que ainda nao existem
-- ============================================================
"""

FOOTER_UNICO = """
-- ============================================================
-- 5. USUARIO INICIAL (somente se ainda nao existir)
-- admin@example.com / Admin@123 — troque a senha no primeiro login
-- ============================================================
INSERT INTO `users` (`name`, `email`, `password`, `role_id`, `status`, `auth_provider`,
                     `email_verified_at`, `terms_accepted_at`, `created_at`, `updated_at`)
SELECT 'Administrador', 'admin@example.com',
       '$2b$10$vWAdPPDyhPW0u/UeSpdf1eLsXidEiwemycK/I9x7I1DcVjCLSTJii',
       r.id, 'active', 'local', NOW(), NOW(), NOW(), NOW()
FROM `roles` r
WHERE r.slug = 'superadmin'
  AND NOT EXISTS (SELECT 1 FROM `users` WHERE `email` = 'admin@example.com');

SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;

-- ============================================================
-- VERIFICACAO FINAL
-- Esperado: todas as colunas em 1 e as contagens preenchidas.
-- ============================================================
SELECT
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE') AS tabelas_no_banco,
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payment_methods') AS tabela_formas_pagamento,
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'investment_types') AS tabela_tipos_investimento,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers'
        AND COLUMN_NAME = 'zip_code') AS coluna_cep,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'accounts'
        AND COLUMN_NAME = 'investment_type_id') AS coluna_investimento_conta;

SELECT (SELECT COUNT(*) FROM `roles`)             AS perfis,
       (SELECT COUNT(*) FROM `permissions`)       AS permissoes,
       (SELECT COUNT(*) FROM `banks`)             AS bancos,
       (SELECT COUNT(*) FROM `categories`)        AS categorias,
       (SELECT COUNT(*) FROM `cost_centers`)      AS centros_de_custo,
       (SELECT COUNT(*) FROM `payment_methods`)   AS formas_de_pagamento,
       (SELECT COUNT(*) FROM `investment_types`)  AS tipos_de_investimento,
       (SELECT COUNT(*) FROM `users`)             AS usuarios;

SELECT id, name, email, status FROM `users` ORDER BY id;

SELECT 'Importacao concluida. Acesse /login e troque a senha do administrador.' AS resultado;
"""

unico = (
    HEADER_UNICO
    + estrutura_unica
    + "\n-- ============================================================\n"
    + "-- 1.1 PERFIS, PERMISSOES E BANCOS (INSERT IGNORE: nao duplica)\n"
    + "-- ============================================================\n"
    + dados_acl + "\n" + dados_bancos + "\n"
    + "\n-- ============================================================\n"
    + "-- 2. MIGRATIONS 0004 a 0007 (idempotentes)\n"
    + "-- ============================================================\n"
    + "\n".join(blocks) + "\n"
    + corpo_bancos + "\n"
    + "".join(extras_blocos)
    + "\n-- ============================================================\n"
    + "-- 3. CATEGORIAS PADRAO (globais, sem duplicar)\n"
    + "-- ============================================================\n"
    + "\n".join(seeds_categorias) + "\n"
    + "\n-- ============================================================\n"
    + "-- 4. CENTROS DE CUSTO PADRAO (globais, sem duplicar)\n"
    + "-- ============================================================\n"
    + "\n".join(seeds_centros) + "\n"
    + FOOTER_UNICO
)

(OUT / "somase_mysql_unico.sql").write_text(unico)
print("somase_mysql_unico.sql", len(unico.encode("utf-8")), "bytes")
