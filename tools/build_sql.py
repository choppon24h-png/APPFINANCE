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
                          "categories", "cost_centers"]).stdout)

HEADER_INSTALL = """-- ============================================================
-- SOMASE — Controle Financeiro
-- INSTALACAO COMPLETA DO BANCO (MySQL 5.7+ / MySQL 8 / MariaDB 10.3+)
-- Gerado em 2026-11-27 a partir do banco de desenvolvimento ja com a
-- migration 0004 (cadastro, OAuth e painel administrativo) aplicada.
--
-- O QUE ESTE ARQUIVO FAZ
--   * cria as 20 tabelas do sistema (financeiro + acesso);
--   * carrega os dados essenciais: perfis, permissoes, categorias e
--     centros de custo padrao;
--   * cria o usuario inicial admin@example.com / Admin@123 (superadmin).
--
-- ATENCAO: as tabelas existentes sao APAGADAS (DROP TABLE IF EXISTS).
-- Use em banco novo/vazio. Para atualizar um banco que ja tem dados,
-- importe somase_atualizar_banco.sql.
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
