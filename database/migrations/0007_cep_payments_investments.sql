-- ============================================================
-- SOMASE — CEP, formas de pagamento e tipos de investimento
-- Migration 0007
--
-- 100% idempotente: colunas/índices protegidos por information_schema +
-- PREPARE/EXECUTE e seeds com INSERT ... SELECT ... WHERE NOT EXISTS.
-- Pode ser importada duas vezes no phpMyAdmin sem erro.
--
--  * cost_centers: campos de endereço separados (CEP, rua, número,
--    complemento, bairro, cidade, UF). A coluna `address` continua
--    existindo com o endereço completo montado, para não quebrar os
--    cartões e relatórios antigos.
--  * payment_methods: catálogo de formas de pagamento por usuário
--    (user_id NULL = padrão do sistema). Inclui DÉBITO EM CONTA.
--  * investment_types: catálogo de tipos (CDB, LCI, Tesouro Selic,
--    Tesouro IPCA+, CDI, Poupança, Ações...).
--  * investments: tipo do catálogo, taxa de referência (CDI/IPCA/Selic)
--    e periodicidade da taxa contratada (anual/mensal) para estimar
--    a receita de cada mês.
--  * accounts: tipo de investimento e taxa opcionais quando a conta é
--    do tipo "investimento".
--
-- Equivalente PostgreSQL: database/postgresql/0007_cep_payments_investments.pg.sql
-- ============================================================

-- ============================================================
-- 1. Endereço estruturado dos imóveis/centros de custo
-- ============================================================
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'zip_code');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `zip_code` VARCHAR(9) NULL AFTER `address`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'street');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `street` VARCHAR(160) NULL AFTER `zip_code`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'address_number');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `address_number` VARCHAR(20) NULL AFTER `street`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'complement');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `complement` VARCHAR(80) NULL AFTER `address_number`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'neighborhood');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `neighborhood` VARCHAR(80) NULL AFTER `complement`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'city');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `city` VARCHAR(80) NULL AFTER `neighborhood`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'state');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `state` CHAR(2) NULL AFTER `city`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 2. Catálogo de formas de pagamento
-- ============================================================
CREATE TABLE IF NOT EXISTS `payment_methods` (
    `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`    INT UNSIGNED NULL,
    `name`       VARCHAR(80) NOT NULL,
    `slug`       VARCHAR(40) NOT NULL,
    `kind`       VARCHAR(20) NOT NULL DEFAULT 'other',
    `icon`       VARCHAR(20) NULL,
    `sort_order` INT NOT NULL DEFAULT 0,
    `status`     ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_payment_methods_user_slug` (`user_id`, `slug`),
    INDEX `idx_payment_methods_user` (`user_id`, `status`, `sort_order`),
    CONSTRAINT `fk_payment_methods_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Padrões do sistema (user_id NULL). O WHERE NOT EXISTS evita duplicar
-- quando a migration é importada mais de uma vez.
INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'PIX', 'pix', 'bank', 1, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'pix');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'DÉBITO EM CONTA', 'debito_conta', 'bank', 2, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'debito_conta');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'DÉBITO AUTOMÁTICO', 'debito_automatico', 'bank', 3, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'debito_automatico');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'CARTÃO DE DÉBITO', 'cartao_debito', 'card', 4, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'cartao_debito');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'CARTÃO DE CRÉDITO', 'cartao_credito', 'card', 5, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'cartao_credito');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'BOLETO', 'boleto', 'bank', 6, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'boleto');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'DINHEIRO', 'dinheiro', 'cash', 7, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'dinheiro');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'TRANSFERÊNCIA', 'transferencia', 'transfer', 8, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'transferencia');

INSERT INTO `payment_methods` (`user_id`, `name`, `slug`, `kind`, `sort_order`, `status`)
SELECT NULL, 'OUTRO', 'outro', 'other', 9, 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `payment_methods` WHERE `user_id` IS NULL AND `slug` = 'outro');

-- ============================================================
-- 3. Catálogo de tipos de investimento
-- ============================================================
CREATE TABLE IF NOT EXISTS `investment_types` (
    `id`                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id`             INT UNSIGNED NULL,
    `name`                VARCHAR(80) NOT NULL,
    `slug`                VARCHAR(40) NOT NULL,
    `benchmark`           VARCHAR(20) NOT NULL DEFAULT 'none',
    `default_rate`        DECIMAL(12,6) NULL,
    `default_rate_period` ENUM('annual','monthly') NOT NULL DEFAULT 'annual',
    `status`              ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at`          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_investment_types_user_slug` (`user_id`, `slug`),
    INDEX `idx_investment_types_user` (`user_id`, `status`),
    CONSTRAINT `fk_investment_types_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'CDB', 'cdb', 'cdi', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'cdb');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'LCI', 'lci', 'cdi', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'lci');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'LCA', 'lca', 'cdi', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'lca');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Tesouro Selic', 'tesouro_selic', 'selic', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'tesouro_selic');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Tesouro IPCA+', 'tesouro_ipca', 'ipca', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'tesouro_ipca');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Tesouro Prefixado', 'tesouro_prefixado', 'prefixado', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'tesouro_prefixado');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'CDI', 'cdi', 'cdi', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'cdi');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Poupança', 'poupanca', 'none', 0.500000, 'monthly', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'poupanca');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Fundo DI', 'fundo_di', 'cdi', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'fundo_di');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Ações', 'acoes', 'none', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'acoes');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'ETF', 'etf', 'none', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'etf');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Previdência', 'previdencia', 'none', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'previdencia');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Cripto', 'cripto', 'none', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'cripto');

INSERT INTO `investment_types` (`user_id`, `name`, `slug`, `benchmark`, `default_rate`, `default_rate_period`, `status`)
SELECT NULL, 'Outros', 'outros', 'none', NULL, 'annual', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `investment_types` WHERE `user_id` IS NULL AND `slug` = 'outros');

-- ============================================================
-- 4. Projeção de rendimento nos investimentos
-- ============================================================
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'investments' AND COLUMN_NAME = 'investment_type_id');
SET @sql := IF(@has = 0,
    'ALTER TABLE `investments` ADD COLUMN `investment_type_id` INT UNSIGNED NULL AFTER `investment_type`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'investments' AND COLUMN_NAME = 'benchmark_rate');
SET @sql := IF(@has = 0,
    'ALTER TABLE `investments` ADD COLUMN `benchmark_rate` DECIMAL(12,6) NULL AFTER `rate_type`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'investments' AND COLUMN_NAME = 'rate_period');
SET @sql := IF(@has = 0,
    'ALTER TABLE `investments` ADD COLUMN `rate_period` VARCHAR(10) NOT NULL DEFAULT ''annual'' AFTER `benchmark_rate`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'investments' AND INDEX_NAME = 'idx_investments_type');
SET @sql := IF(@has = 0,
    'ALTER TABLE `investments` ADD INDEX `idx_investments_type` (`user_id`, `investment_type_id`)',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 5. Conta do tipo investimento com tipo e taxa opcionais
-- ============================================================
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'accounts' AND COLUMN_NAME = 'investment_type_id');
SET @sql := IF(@has = 0,
    'ALTER TABLE `accounts` ADD COLUMN `investment_type_id` INT UNSIGNED NULL AFTER `account_type`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'accounts' AND COLUMN_NAME = 'investment_rate');
SET @sql := IF(@has = 0,
    'ALTER TABLE `accounts` ADD COLUMN `investment_rate` DECIMAL(12,6) NULL AFTER `investment_type_id`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'accounts' AND COLUMN_NAME = 'investment_rate_period');
SET @sql := IF(@has = 0,
    'ALTER TABLE `accounts` ADD COLUMN `investment_rate_period` VARCHAR(10) NOT NULL DEFAULT ''annual'' AFTER `investment_rate`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- Fim da migration 0007. Nenhum dado existente é alterado: as colunas
-- novas nascem NULL e os catálogos só recebem os padrões quando ainda
-- não existem.
-- ============================================================
