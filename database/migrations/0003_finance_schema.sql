-- ============================================================
-- APPFINANCE — Domínio financeiro
-- MySQL 8.0+ / MariaDB 10.6+
-- Sem dados de produção. Migration idempotente.
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `accounts` (
    `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`         INT UNSIGNED NOT NULL,
    `name`            VARCHAR(120) NOT NULL,
    `bank_name`       VARCHAR(120) NULL,
    `account_type`    ENUM('checking','savings','investment','cash','other') NOT NULL DEFAULT 'checking',
    `agency`          VARCHAR(40) NULL,
    `account_number`  VARCHAR(80) NULL,
    `initial_balance` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `current_balance` DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `initial_date`    DATE NOT NULL,
    `status`          ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `notes`           TEXT NULL,
    `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_accounts_user` (`user_id`),
    INDEX `idx_accounts_status` (`status`),
    CONSTRAINT `fk_accounts_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `categories` (
    `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`    INT UNSIGNED NULL,
    `name`       VARCHAR(120) NOT NULL,
    `type`       ENUM('income','expense') NOT NULL,
    `icon`       VARCHAR(40) NOT NULL DEFAULT 'tag',
    `color`      VARCHAR(20) NOT NULL DEFAULT '#2563eb',
    `parent_id`  INT UNSIGNED NULL,
    `status`     ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_categories_user_type` (`user_id`,`type`,`status`),
    INDEX `idx_categories_parent` (`parent_id`),
    CONSTRAINT `fk_categories_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_categories_parent` FOREIGN KEY (`parent_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `cost_centers` (
    `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`     INT UNSIGNED NULL,
    `name`        VARCHAR(120) NOT NULL,
    `code`        VARCHAR(40) NULL,
    `description` VARCHAR(255) NULL,
    `status`      ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_cost_centers_user` (`user_id`,`status`),
    CONSTRAINT `fk_cost_centers_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `recurring_transactions` (
    `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`      INT UNSIGNED NOT NULL,
    `account_id`   INT UNSIGNED NOT NULL,
    `category_id`  INT UNSIGNED NULL,
    `cost_center_id` INT UNSIGNED NULL,
    `type`         ENUM('income','expense') NOT NULL,
    `description`  VARCHAR(180) NOT NULL,
    `amount`       DECIMAL(15,2) NOT NULL,
    `frequency`    ENUM('daily','weekly','biweekly','monthly','bimonthly','quarterly','semiannual','annual') NOT NULL,
    `start_date`   DATE NOT NULL,
    `end_date`     DATE NULL,
    `next_date`    DATE NOT NULL,
    `status`       ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `payment_method` VARCHAR(40) NULL,
    `notes`        TEXT NULL,
    `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_recurring_user_next` (`user_id`,`next_date`,`status`),
    CONSTRAINT `fk_recurring_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_recurring_account` FOREIGN KEY (`account_id`) REFERENCES `accounts`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_recurring_category` FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_recurring_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `transactions` (
    `id`              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`         INT UNSIGNED NOT NULL,
    `account_id`      INT UNSIGNED NOT NULL,
    `category_id`     INT UNSIGNED NULL,
    `cost_center_id`  INT UNSIGNED NULL,
    `type`            ENUM('income','expense','transfer') NOT NULL,
    `description`     VARCHAR(180) NOT NULL,
    `amount`          DECIMAL(15,2) NOT NULL,
    `transaction_date` DATE NOT NULL,
    `due_date`        DATE NULL,
    `payment_date`    DATE NULL,
    `status`          ENUM('pending','paid','overdue','cancelled','expected','received','late') NOT NULL DEFAULT 'pending',
    `payment_method`  VARCHAR(40) NULL,
    `notes`           TEXT NULL,
    `recurrence_id`   INT UNSIGNED NULL,
    `recurrence_key`  VARCHAR(80) NULL,
    `transfer_id`     CHAR(36) NULL,
    `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_transactions_user_date` (`user_id`,`transaction_date`),
    INDEX `idx_transactions_user_due` (`user_id`,`due_date`,`status`),
    INDEX `idx_transactions_account` (`account_id`,`status`),
    INDEX `idx_transactions_category` (`category_id`,`type`),
    INDEX `idx_transactions_cost_center` (`cost_center_id`),
    INDEX `idx_transactions_recurrence` (`recurrence_id`,`transaction_date`),
    UNIQUE KEY `uq_transaction_recurrence_date` (`recurrence_id`,`transaction_date`),
    INDEX `idx_transactions_transfer` (`transfer_id`),
    CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_transactions_account` FOREIGN KEY (`account_id`) REFERENCES `accounts`(`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_transactions_category` FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_transactions_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_transactions_recurrence` FOREIGN KEY (`recurrence_id`) REFERENCES `recurring_transactions`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `investments` (
    `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`          INT UNSIGNED NOT NULL,
    `account_id`       INT UNSIGNED NOT NULL,
    `institution`      VARCHAR(120) NOT NULL,
    `investment_type`  VARCHAR(80) NOT NULL,
    `name`             VARCHAR(150) NOT NULL,
    `amount_invested`  DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `application_date` DATE NOT NULL,
    `interest_rate`    DECIMAL(12,6) NULL,
    `rate_type`        VARCHAR(40) NULL,
    `benchmark`        VARCHAR(80) NULL,
    `liquidity`        VARCHAR(80) NULL,
    `maturity_date`    DATE NULL,
    `status`           ENUM('active','inactive','matured') NOT NULL DEFAULT 'active',
    `notes`            TEXT NULL,
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_investments_user` (`user_id`,`status`),
    INDEX `idx_investments_account` (`account_id`),
    CONSTRAINT `fk_investments_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_investments_account` FOREIGN KEY (`account_id`) REFERENCES `accounts`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `investment_movements` (
    `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `investment_id`  INT UNSIGNED NOT NULL,
    `type`           ENUM('application','redemption','income','adjustment') NOT NULL,
    `amount`         DECIMAL(15,2) NOT NULL,
    `movement_date`  DATE NOT NULL,
    `rate`           DECIMAL(12,6) NULL,
    `notes`          VARCHAR(255) NULL,
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_investment_movements` (`investment_id`,`movement_date`),
    CONSTRAINT `fk_investment_movements_investment` FOREIGN KEY (`investment_id`) REFERENCES `investments`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `investment_returns` (
    `id`               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `investment_id`    INT UNSIGNED NOT NULL,
    `reference_month`  TINYINT UNSIGNED NOT NULL,
    `reference_year`   SMALLINT UNSIGNED NOT NULL,
    `initial_value`    DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `return_amount`    DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `return_percentage` DECIMAL(12,6) NOT NULL DEFAULT 0.000000,
    `final_value`      DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_investment_return_period` (`investment_id`,`reference_month`,`reference_year`),
    INDEX `idx_investment_returns_period` (`reference_year`,`reference_month`),
    CONSTRAINT `fk_investment_returns_investment` FOREIGN KEY (`investment_id`) REFERENCES `investments`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `account_movements` (
    `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `account_id`     INT UNSIGNED NOT NULL,
    `transaction_id` BIGINT UNSIGNED NULL,
    `transfer_id`    CHAR(36) NULL,
    `movement_type`  ENUM('transaction','transfer','investment','adjustment') NOT NULL,
    `amount`         DECIMAL(15,2) NOT NULL COMMENT 'Valor assinado: entrada positiva, saída negativa',
    `balance_after`  DECIMAL(15,2) NULL,
    `movement_date`  DATE NOT NULL,
    `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_account_movements_account_date` (`account_id`,`movement_date`),
    INDEX `idx_account_movements_transaction` (`transaction_id`),
    INDEX `idx_account_movements_transfer` (`transfer_id`),
    CONSTRAINT `fk_account_movements_account` FOREIGN KEY (`account_id`) REFERENCES `accounts`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_account_movements_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
