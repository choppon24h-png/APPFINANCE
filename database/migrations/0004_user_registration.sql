-- ============================================================
-- SOMASE — Cadastro de usuarios, OAuth e painel administrativo
-- Migration 0004 (idempotente na medida do possivel: o instalador
-- ignora erros de "coluna/indice ja existe")
--
-- Contempla exatamente o que foi especificado:
--  * users: birth_date, auth_provider, avatar_url, email_verified_at,
--           terms_accepted_at, registration_ip
--  * user_identities: vinculo OAuth (google/microsoft)
--  * auth_attempts: rate-limit de login/cadastro/oauth
--  * permissao access_admin_panel no perfil admin
--
-- Nenhuma senha e criada aqui. O superadmin (admin@somase.com) e
-- definido pelo proprietario direto no banco.
-- ============================================================

-- ---------- users: novos campos ----------
ALTER TABLE `users`
    ADD COLUMN `birth_date`        DATE NULL AFTER `status`,
    ADD COLUMN `auth_provider`     ENUM('local','google','microsoft') NOT NULL DEFAULT 'local' AFTER `birth_date`,
    ADD COLUMN `avatar_url`        VARCHAR(255) NULL AFTER `auth_provider`,
    ADD COLUMN `email_verified_at` DATETIME NULL AFTER `avatar_url`,
    ADD COLUMN `terms_accepted_at` DATETIME NULL AFTER `email_verified_at`,
    ADD COLUMN `registration_ip`   VARCHAR(45) NULL AFTER `terms_accepted_at`;

ALTER TABLE `users` ADD INDEX `idx_users_provider` (`auth_provider`);
ALTER TABLE `users` ADD INDEX `idx_users_created` (`created_at`);

-- ---------- vinculo OAuth ----------
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
INSERT IGNORE INTO `permissions` (`slug`, `name`, `group_name`) VALUES
('access_admin_panel', 'Acessar painel administrativo', 'administracao');

INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r, `permissions` p
WHERE r.slug = 'admin' AND p.slug = 'access_admin_panel';
