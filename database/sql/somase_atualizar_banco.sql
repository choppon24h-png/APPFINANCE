-- ============================================================
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

-- users.birth_date
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD COLUMN `birth_date` DATE NULL AFTER `status`',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'birth_date');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users.auth_provider
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD COLUMN `auth_provider` ENUM(''local'',''google'',''microsoft'') NOT NULL DEFAULT ''local'' AFTER `birth_date`',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'auth_provider');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users.avatar_url
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD COLUMN `avatar_url` VARCHAR(255) NULL AFTER `auth_provider`',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'avatar_url');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users.email_verified_at
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD COLUMN `email_verified_at` DATETIME NULL AFTER `avatar_url`',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'email_verified_at');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users.terms_accepted_at
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD COLUMN `terms_accepted_at` DATETIME NULL AFTER `email_verified_at`',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'terms_accepted_at');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users.registration_ip
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD COLUMN `registration_ip` VARCHAR(45) NULL AFTER `terms_accepted_at`',
        'DO 0')
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'registration_ip');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- indice users.idx_users_provider
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD INDEX `idx_users_provider` (`auth_provider`)',
        'DO 0')
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND INDEX_NAME = 'idx_users_provider');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- indice users.idx_users_created
SET @sql := (SELECT IF(COUNT(*) = 0,
        'ALTER TABLE `users` ADD INDEX `idx_users_created` (`created_at`)',
        'DO 0')
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND INDEX_NAME = 'idx_users_created');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

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
