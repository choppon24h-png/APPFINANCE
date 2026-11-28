-- ============================================================
-- SOMASE — Controle Financeiro
-- INSTALACAO COMPLETA DO BANCO (MySQL 5.7+ / MySQL 8 / MariaDB 10.3+)
-- Gerado em 2026-11-27 a partir do banco de desenvolvimento ja com as
-- migrations 0004 (cadastro, OAuth, painel) e 0005 (catalogo de bancos).
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

/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `account_movements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_movements` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(10) unsigned NOT NULL,
  `transaction_id` bigint(20) unsigned DEFAULT NULL,
  `transfer_id` char(36) DEFAULT NULL,
  `movement_type` enum('transaction','transfer','investment','adjustment') NOT NULL,
  `amount` decimal(15,2) NOT NULL COMMENT 'Valor assinado: entrada positiva, saída negativa',
  `balance_after` decimal(15,2) DEFAULT NULL,
  `movement_date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_account_movements_account_date` (`account_id`,`movement_date`),
  KEY `idx_account_movements_transaction` (`transaction_id`),
  KEY `idx_account_movements_transfer` (`transfer_id`),
  CONSTRAINT `fk_account_movements_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_account_movements_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `accounts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `name` varchar(120) NOT NULL,
  `bank_name` varchar(120) DEFAULT NULL,
  `bank_code` char(3) DEFAULT NULL,
  `account_type` enum('checking','savings','investment','cash','other') NOT NULL DEFAULT 'checking',
  `investment_type_id` int(10) unsigned DEFAULT NULL,
  `investment_rate` decimal(12,6) DEFAULT NULL,
  `investment_rate_period` varchar(10) NOT NULL DEFAULT 'annual',
  `agency` varchar(40) DEFAULT NULL,
  `account_number` varchar(80) DEFAULT NULL,
  `initial_balance` decimal(15,2) NOT NULL DEFAULT 0.00,
  `current_balance` decimal(15,2) NOT NULL DEFAULT 0.00,
  `initial_date` date NOT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_accounts_user` (`user_id`),
  KEY `idx_accounts_status` (`status`),
  KEY `idx_accounts_bank` (`bank_code`),
  CONSTRAINT `fk_accounts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tenant_id` int(10) unsigned DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity` varchar(100) DEFAULT NULL,
  `entity_id` int(10) unsigned DEFAULT NULL,
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details`)),
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_tenant` (`tenant_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_action` (`action`)
) ENGINE=InnoDB AUTO_INCREMENT=75 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `auth_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_attempts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ip` varchar(45) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `action` enum('login','register','oauth') NOT NULL,
  `success` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_attempts_lookup` (`action`,`ip`,`email`,`created_at`),
  KEY `idx_attempts_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `banks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `banks` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `compe` char(3) DEFAULT NULL COMMENT 'Codigo COMPE (3 digitos, ex.: 001)',
  `ispb` char(8) DEFAULT NULL COMMENT 'Identificador padrao bancario',
  `name` varchar(120) NOT NULL COMMENT 'Nome da instituicao (BCB)',
  `full_name` varchar(160) DEFAULT NULL COMMENT 'Nome completo/fantasia',
  `aliases` varchar(200) DEFAULT NULL COMMENT 'Marcas/nomes populares (nubank, itau, c6...)',
  `logo_url` varchar(255) DEFAULT NULL COMMENT 'Logotipo (opcional, CDN publica)',
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_banks_compe` (`compe`),
  UNIQUE KEY `uq_banks_ispb` (`ispb`),
  KEY `idx_banks_name` (`name`),
  KEY `idx_banks_full` (`full_name`),
  KEY `idx_banks_aliases` (`aliases`)
) ENGINE=InnoDB AUTO_INCREMENT=1397 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Bancos brasileiros com codigo COMPE para autocomplete';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(120) NOT NULL,
  `type` enum('income','expense') NOT NULL,
  `icon` varchar(40) NOT NULL DEFAULT 'tag',
  `color` varchar(20) NOT NULL DEFAULT '#2563eb',
  `parent_id` int(10) unsigned DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_categories_user_type` (`user_id`,`type`,`status`),
  KEY `idx_categories_parent` (`parent_id`),
  CONSTRAINT `fk_categories_parent` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_categories_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cnpj_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cnpj_cache` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cnpj` char(14) NOT NULL COMMENT 'Somente digitos, 14 chars',
  `provider` varchar(50) NOT NULL COMMENT 'brasilapi | receitaws | cnpja',
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'Resposta normalizada do provedor' CHECK (json_valid(`payload`)),
  `raw_response` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Payload bruto original (debug/auditoria)' CHECK (json_valid(`raw_response`)),
  `http_status` smallint(6) NOT NULL DEFAULT 200,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cnpj` (`cnpj`),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Cache de respostas de consulta de CNPJ com TTL configuravel';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cnpj_rate_limit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cnpj_rate_limit` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ip` varchar(45) NOT NULL,
  `window_start` datetime NOT NULL COMMENT 'Inicio da janela de 1 minuto',
  `hit_count` smallint(6) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ip_window` (`ip`,`window_start`),
  KEY `idx_ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Rate-limit por IP para o endpoint /api/cnpj — janela deslizante de 1 minuto';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cost_centers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cost_centers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(120) NOT NULL,
  `kind` varchar(20) NOT NULL DEFAULT 'general',
  `address` varchar(255) DEFAULT NULL,
  `zip_code` varchar(9) DEFAULT NULL,
  `street` varchar(160) DEFAULT NULL,
  `address_number` varchar(20) DEFAULT NULL,
  `complement` varchar(80) DEFAULT NULL,
  `neighborhood` varchar(80) DEFAULT NULL,
  `city` varchar(80) DEFAULT NULL,
  `state` char(2) DEFAULT NULL,
  `identifiers` varchar(500) DEFAULT NULL,
  `code` varchar(40) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_cost_centers_user` (`user_id`,`status`),
  KEY `idx_cost_centers_kind` (`user_id`,`kind`),
  CONSTRAINT `fk_cost_centers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `investment_movements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `investment_movements` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `investment_id` int(10) unsigned NOT NULL,
  `type` enum('application','redemption','income','adjustment') NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `movement_date` date NOT NULL,
  `rate` decimal(12,6) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_investment_movements` (`investment_id`,`movement_date`),
  CONSTRAINT `fk_investment_movements_investment` FOREIGN KEY (`investment_id`) REFERENCES `investments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `investment_returns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `investment_returns` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `investment_id` int(10) unsigned NOT NULL,
  `reference_month` tinyint(3) unsigned NOT NULL,
  `reference_year` smallint(5) unsigned NOT NULL,
  `initial_value` decimal(15,2) NOT NULL DEFAULT 0.00,
  `return_amount` decimal(15,2) NOT NULL DEFAULT 0.00,
  `return_percentage` decimal(12,6) NOT NULL DEFAULT 0.000000,
  `final_value` decimal(15,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_investment_return_period` (`investment_id`,`reference_month`,`reference_year`),
  KEY `idx_investment_returns_period` (`reference_year`,`reference_month`),
  CONSTRAINT `fk_investment_returns_investment` FOREIGN KEY (`investment_id`) REFERENCES `investments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `investment_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `investment_types` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(80) NOT NULL,
  `slug` varchar(40) NOT NULL,
  `benchmark` varchar(20) NOT NULL DEFAULT 'none',
  `default_rate` decimal(12,6) DEFAULT NULL,
  `default_rate_period` enum('annual','monthly') NOT NULL DEFAULT 'annual',
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_investment_types_user_slug` (`user_id`,`slug`),
  KEY `idx_investment_types_user` (`user_id`,`status`),
  CONSTRAINT `fk_investment_types_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `investments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `investments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `account_id` int(10) unsigned NOT NULL,
  `institution` varchar(120) NOT NULL,
  `investment_type` varchar(80) NOT NULL,
  `investment_type_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `amount_invested` decimal(15,2) NOT NULL DEFAULT 0.00,
  `application_date` date NOT NULL,
  `interest_rate` decimal(12,6) DEFAULT NULL,
  `rate_type` varchar(40) DEFAULT NULL,
  `benchmark_rate` decimal(12,6) DEFAULT NULL,
  `rate_period` varchar(10) NOT NULL DEFAULT 'annual',
  `benchmark` varchar(80) DEFAULT NULL,
  `liquidity` varchar(80) DEFAULT NULL,
  `maturity_date` date DEFAULT NULL,
  `status` enum('active','inactive','matured') NOT NULL DEFAULT 'active',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_investments_user` (`user_id`,`status`),
  KEY `idx_investments_account` (`account_id`),
  KEY `idx_investments_type` (`user_id`,`investment_type_id`),
  CONSTRAINT `fk_investments_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `fk_investments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `payment_methods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_methods` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned DEFAULT NULL,
  `name` varchar(80) NOT NULL,
  `slug` varchar(40) NOT NULL,
  `kind` varchar(20) NOT NULL DEFAULT 'other',
  `icon` varchar(20) DEFAULT NULL,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_payment_methods_user_slug` (`user_id`,`slug`),
  KEY `idx_payment_methods_user` (`user_id`,`status`,`sort_order`),
  CONSTRAINT `fk_payment_methods_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `permissions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `slug` varchar(100) NOT NULL COMMENT 'Ex: manage_users, view_dashboard',
  `name` varchar(150) NOT NULL,
  `group_name` varchar(50) DEFAULT NULL COMMENT 'Agrupamento livre para telas de administracao',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `recurring_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `recurring_transactions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `account_id` int(10) unsigned NOT NULL,
  `category_id` int(10) unsigned DEFAULT NULL,
  `cost_center_id` int(10) unsigned DEFAULT NULL,
  `type` enum('income','expense') NOT NULL,
  `description` varchar(180) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `frequency` enum('daily','weekly','biweekly','monthly','bimonthly','quarterly','semiannual','annual') NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `next_date` date NOT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `payment_method` varchar(40) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_recurring_user_next` (`user_id`,`next_date`,`status`),
  KEY `fk_recurring_account` (`account_id`),
  KEY `fk_recurring_category` (`category_id`),
  KEY `fk_recurring_cost_center` (`cost_center_id`),
  CONSTRAINT `fk_recurring_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `fk_recurring_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recurring_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_recurring_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permissions` (
  `role_id` int(10) unsigned NOT NULL,
  `permission_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`permission_id`),
  KEY `fk_rp_permission` (`permission_id`),
  CONSTRAINT `fk_rp_permission` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `slug` varchar(50) NOT NULL COMMENT 'Ex: superadmin, admin, user',
  `name` varchar(100) NOT NULL,
  `is_system` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Impede exclusao pela aplicacao',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tenants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenants` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `settings_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Configuracoes livres por tenant (ex: marca, limites)' CHECK (json_valid(`settings_json`)),
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `account_id` int(10) unsigned NOT NULL,
  `category_id` int(10) unsigned DEFAULT NULL,
  `cost_center_id` int(10) unsigned DEFAULT NULL,
  `type` enum('income','expense','transfer') NOT NULL,
  `description` varchar(180) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `transaction_date` date NOT NULL,
  `due_date` date DEFAULT NULL,
  `payment_date` date DEFAULT NULL,
  `status` enum('pending','paid','overdue','cancelled','expected','received','late') NOT NULL DEFAULT 'pending',
  `payment_method` varchar(40) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `document_code` varchar(64) DEFAULT NULL,
  `import_ref` varchar(100) DEFAULT NULL,
  `attachment_path` varchar(255) DEFAULT NULL,
  `recurrence_id` int(10) unsigned DEFAULT NULL,
  `recurrence_key` varchar(80) DEFAULT NULL,
  `transfer_id` char(36) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_transaction_recurrence_date` (`recurrence_id`,`transaction_date`),
  KEY `idx_transactions_user_date` (`user_id`,`transaction_date`),
  KEY `idx_transactions_user_due` (`user_id`,`due_date`,`status`),
  KEY `idx_transactions_account` (`account_id`,`status`),
  KEY `idx_transactions_category` (`category_id`,`type`),
  KEY `idx_transactions_cost_center` (`cost_center_id`),
  KEY `idx_transactions_recurrence` (`recurrence_id`,`transaction_date`),
  KEY `idx_transactions_transfer` (`transfer_id`),
  KEY `idx_transactions_document` (`user_id`,`document_code`),
  KEY `idx_transactions_import` (`user_id`,`account_id`,`import_ref`),
  CONSTRAINT `fk_transactions_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `fk_transactions_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transactions_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transactions_recurrence` FOREIGN KEY (`recurrence_id`) REFERENCES `recurring_transactions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=204 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_identities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_identities` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `provider` enum('google','microsoft') NOT NULL,
  `provider_user_id` varchar(191) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_identity_provider` (`provider`,`provider_user_id`),
  KEY `idx_identity_user` (`user_id`),
  KEY `idx_identity_email` (`email`),
  CONSTRAINT `fk_identity_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `user_tenants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_tenants` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `tenant_id` int(10) unsigned NOT NULL,
  `role_id` int(10) unsigned NOT NULL COMMENT 'Role do usuario dentro deste tenant',
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_tenant` (`user_id`,`tenant_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_tenant_id` (`tenant_id`),
  KEY `fk_ut_role` (`role_id`),
  CONSTRAINT `fk_ut_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`),
  CONSTRAINT `fk_ut_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ut_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role_id` int(10) unsigned NOT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `birth_date` date DEFAULT NULL,
  `auth_provider` enum('local','google','microsoft') NOT NULL DEFAULT 'local',
  `avatar_url` varchar(255) DEFAULT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `terms_accepted_at` datetime DEFAULT NULL,
  `registration_ip` varchar(45) DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `idx_email` (`email`),
  KEY `fk_users_role` (`role_id`),
  KEY `idx_users_provider` (`auth_provider`),
  KEY `idx_users_created` (`created_at`),
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` (`id`, `slug`, `name`, `is_system`, `created_at`) VALUES (1,'superadmin','Super Administrador',1,'2026-11-27 16:31:16');
INSERT INTO `roles` (`id`, `slug`, `name`, `is_system`, `created_at`) VALUES (2,'admin','Administrador',0,'2026-11-27 16:31:16');
INSERT INTO `roles` (`id`, `slug`, `name`, `is_system`, `created_at`) VALUES (3,'user','Usuario',0,'2026-11-27 16:31:16');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `permissions` WRITE;
/*!40000 ALTER TABLE `permissions` DISABLE KEYS */;
INSERT INTO `permissions` (`id`, `slug`, `name`, `group_name`, `created_at`) VALUES (1,'consultar_cnpj','Consultar CNPJ','Integrações','2026-11-27 16:31:16');
INSERT INTO `permissions` (`id`, `slug`, `name`, `group_name`, `created_at`) VALUES (2,'view_dashboard','Ver dashboard','geral','2026-11-27 16:31:16');
INSERT INTO `permissions` (`id`, `slug`, `name`, `group_name`, `created_at`) VALUES (3,'manage_users','Gerenciar usuarios','administracao','2026-11-27 16:31:16');
INSERT INTO `permissions` (`id`, `slug`, `name`, `group_name`, `created_at`) VALUES (4,'manage_roles','Gerenciar roles','administracao','2026-11-27 16:31:16');
INSERT INTO `permissions` (`id`, `slug`, `name`, `group_name`, `created_at`) VALUES (5,'access_admin_panel','Acessar painel administrativo','administracao','2026-11-27 19:35:57');
/*!40000 ALTER TABLE `permissions` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `role_permissions` WRITE;
/*!40000 ALTER TABLE `role_permissions` DISABLE KEYS */;
INSERT INTO `role_permissions` (`role_id`, `permission_id`) VALUES (2,2);
INSERT INTO `role_permissions` (`role_id`, `permission_id`) VALUES (2,3);
INSERT INTO `role_permissions` (`role_id`, `permission_id`) VALUES (2,4);
INSERT INTO `role_permissions` (`role_id`, `permission_id`) VALUES (2,5);
INSERT INTO `role_permissions` (`role_id`, `permission_id`) VALUES (3,2);
/*!40000 ALTER TABLE `role_permissions` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (1,NULL,'Alimentação','expense','utensils','#ef4444',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (2,NULL,'Supermercado','expense','shopping-cart','#f97316',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (3,NULL,'Moradia','expense','home','#eab308',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (4,NULL,'Transporte','expense','car','#d97706',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (5,NULL,'Saúde','expense','heart','#ec4899',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (6,NULL,'Educação','expense','book','#8b5cf6',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (7,NULL,'Assinaturas','expense','repeat','#06b6d4',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (8,NULL,'Lazer','expense','smile','#14b8a6',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (9,NULL,'Impostos','expense','receipt','#64748b',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (10,NULL,'Outros','expense','tag','#64748b',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (11,NULL,'Salário','income','briefcase','#16a34a',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (12,NULL,'Vendas','income','shopping-bag','#22c55e',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (13,NULL,'Serviços','income','briefcase','#84cc16',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (14,NULL,'Comissões','income','percent','#10b981',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (15,NULL,'Rendimentos','income','trending-up','#0ea5e9',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (16,NULL,'Reembolso','income','rotate-ccw','#6366f1',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`, `parent_id`, `status`, `created_at`, `updated_at`) VALUES (17,NULL,'Outros','income','tag','#64748b',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `cost_centers` WRITE;
/*!40000 ALTER TABLE `cost_centers` DISABLE KEYS */;
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `kind`, `address`, `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`, `identifiers`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (1,NULL,'Pessoal','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PES','Despesas e receitas pessoais','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `kind`, `address`, `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`, `identifiers`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (2,NULL,'Casa','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'CAS','Moradia e manutenção','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `kind`, `address`, `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`, `identifiers`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (3,NULL,'Empresa','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EMP','Operação do negócio','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `kind`, `address`, `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`, `identifiers`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (4,NULL,'Carro','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'CAR','Veículo e transporte','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `kind`, `address`, `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`, `identifiers`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (5,NULL,'Operacional','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'OPE','Custos operacionais gerais','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `kind`, `address`, `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`, `identifiers`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (6,2,'Apartamento Centro','property','Rua das Flores 100',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'99887766, 123456789',NULL,NULL,'active','2026-11-28 00:45:02','2026-11-28 00:45:02');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `kind`, `address`, `zip_code`, `street`, `address_number`, `complement`, `neighborhood`, `city`, `state`, `identifiers`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (8,1,'Imovel Teste CEP','property','Praça Sete de Setembro, 1000 - Sala 5 — Centro, Belo Horizonte/MG','30130-010','Praça Sete de Setembro','1000','Sala 5','Centro','Belo Horizonte','MG','11223344',NULL,NULL,'active','2026-11-28 11:26:53','2026-11-28 11:26:53');
/*!40000 ALTER TABLE `cost_centers` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `banks` WRITE;
/*!40000 ALTER TABLE `banks` DISABLE KEYS */;
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (1,'000','28719664','Câmbio B3','Câmara de Câmbio B3',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (2,'001','00000000','BCO DO BRASIL S.A.','Banco do Brasil S.A.','Banco do Brasil | BB','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00000000.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (3,'003','04902979','BCO DA AMAZONIA S.A.','BANCO DA AMAZONIA S.A.','Banco da Amazônia | BASA','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04902979.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (4,'004','07237373','BCO DO NORDESTE DO BRASIL S.A.','Banco do Nordeste do Brasil S.A.','Banco do Nordeste | BNB','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/07237373.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (5,'007','33657248','BNDES','BANCO NACIONAL DE DESENVOLVIMENTO ECONOMICO E SOCIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (6,'009','00394460','STN','Secretaria do Tesouro Nacional - STN',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (7,'010','81723108','CREDICOAMO','CREDICOAMO CREDITO RURAL COOPERATIVA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (8,'011','61809182','UBS (BRASIL) CORRETORA DE VALORES S.A.','UBS (BRASIL) CORRETORA DE VALORES S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/61809182.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (9,'012','04866275','BANCO INBURSA','Banco Inbursa S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (10,'014','09274232','STATE STREET BR S.A. BCO COMERCIAL','STATE STREET BRASIL S.A. - BANCO COMERCIAL',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/09274232.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (11,'015','02819125','UBS BB CCTVM S.A.','UBS BB CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/02819125.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (12,'016','04715685','CCM DESP TRÂNS SC E RS','COOPERATIVA DE CRÉDITO MÚTUO DOS DESPACHANTES DE TRÂNSITO DE SANTA CATARINA E RIO GRANDE DO SUL - SICOOB CREDITRAN',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04891850.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (13,'017','42272526','BNY MELLON BCO S.A.','BNY Mellon Banco S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/42272526.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (14,'018','57839805','BCO TRICURY S.A.','Banco Tricury S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (15,'021','28127603','BCO BANESTES S.A.','BANESTES S.A. BANCO DO ESTADO DO ESPIRITO SANTO','Banestes','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/28127603.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (16,'023','53720128','CONTA SIMPLES SCD S.A.','CONTA SIMPLES SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (17,'024','10866788','BCO BANDEPE S.A.','Banco Bandepe S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (18,'025','03323840','BCO ALFA S.A.','Banco Alfa S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (19,'033','90400888','BCO SANTANDER (BRASIL) S.A.','BANCO SANTANDER (BRASIL) S.A.','Santander','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/90400888.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (20,'036','06271464','BCO BBI S.A.','Banco Bradesco BBI S.A.','Bradesco BBI','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/06271464.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (21,'037','04913711','BCO DO EST. DO PA S.A.','Banco do Estado do Pará S.A.','Banpará','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04913711.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (22,'040','03609817','BCO CARGILL S.A.','Banco Cargill S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/03609817.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (23,'041','92702067','BCO DO ESTADO DO RS S.A.','Banco do Estado do Rio Grande do Sul S.A.','Banrisul','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/92702067.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (24,'047','13009717','BCO DO EST. DE SE S.A.','Banco do Estado de Sergipe S.A.','Banese','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13009717.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (25,'060','04913129','CONFIDENCE CC S.A.','CONFIDENCE SOCIEDADE CORRETORA DE CAMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (26,'063','04184779','BANCO BRADESCARD','Banco Bradescard S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04184779.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (27,'064','04332281','GOLDMAN SACHS DO BRASIL BM S.A','GOLDMAN SACHS DO BRASIL BANCO MULTIPLO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/04332281.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (28,'065','48795256','BCO ANDBANK S.A.','Banco AndBank (Brasil) S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (29,'066','02801938','BCO MORGAN STANLEY S.A.','BANCO MORGAN STANLEY S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/02801938.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (30,'069','61033106','BCO CREFISA S.A.','Banco Crefisa S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61033106.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (31,'070','00000208','BRB - BCO DE BRASILIA S.A.','BRB - BANCO DE BRASILIA S.A.','BRB | Banco de Brasília','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00000208.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (32,'074','03017677','BCO. J.SAFRA S.A.','Banco J. Safra S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/03017677.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (33,'075','03532415','BANCO ABN AMRO CLEARING S.A.','BANCO ABN AMRO CLEARING S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (34,'076','07656500','BCO KDB BRASIL S.A.','Banco KDB do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (35,'077','00416968','BANCO INTER','Banco Inter S.A.','Inter | Banco Inter | Intermedium','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00416968.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (36,'078','34111187','HAITONG BI DO BRASIL S.A.','Haitong Banco de Investimento do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (37,'079','09516419','PICPAY BANK - BANCO MÚLTIPLO S.A','PICPAY BANK - BANCO MÚLTIPLO S.A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/09516419.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (38,'080','73622748','BT CC LTDA.','BT CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (39,'081','10264663','BANCOSEGURO S.A.','BancoSeguro S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (40,'082','07679404','BANCO TOPÁZIO S.A.','BANCO TOPÁZIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (41,'083','10690848','BCO DA CHINA BRASIL S.A.','Banco da China Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (42,'084','02398976','SISPRIME DO BRASIL - COOP','SISPRIME DO BRASIL - COOPERATIVA DE CRÉDITO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02398976.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (43,'085','05463212','COOPCENTRAL AILOS','Cooperativa Central de Crédito - Ailos','Ailos | Cecred','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/05463212.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (44,'089','62109566','CREDISAN CC','CREDISAN COOPERATIVA DE CRÉDITO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (45,'093','07945233','POLOCRED SCMEPP LTDA.','PÓLOCRED   SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (46,'094','11758741','BANCO FINAXIS','Banco Finaxis S.A.','Finaxis',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (47,'095','11703662','BANCO TRAVELEX S.A.','BANCO TRAVELEX S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (48,'096','00997185','BCO B3 S.A.','Banco B3 S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (49,'097','04632856','CREDISIS - CENTRAL DE COOPERATIVAS DE CRÉDITO','CREDISIS - CENTRAL DE COOPERATIVAS DE CRÉDITO','Credisis',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (50,'099','03046391','UNIPRIME COOPCENTRAL LTDA.','UNIPRIME CENTRAL NACIONAL - CENTRAL NACIONAL DE COOPERATIVA DE CREDITO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (51,'100','00806535','PLANNER CV S.A.','Planner Corretora de Valores S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/00806535.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (52,'101','62287735','WARREN RENA DTVM','WARREN RENA DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/62287735.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (53,'102','02332886','XP INVESTIMENTOS CCTVM S/A','XP INVESTIMENTOS CORRETORA DE CÂMBIO,TÍTULOS E VALORES MOBILIÁRIOS S/A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02332886.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (54,'104','00360305','CAIXA ECONOMICA FEDERAL','CAIXA ECONOMICA FEDERAL','Caixa | Caixa Econômica Federal | CEF | Caixa Econômica','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00360305.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (55,'105','07652226','LECCA CFI S.A.','Lecca Crédito, Financiamento e Investimento S/A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/07652226.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (56,'107','15114366','BCO BOCOM BBM S.A.','Banco Bocom BBM S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (57,'111','36113876','OLIVEIRA TRUST DTVM S.A.','OLIVEIRA TRUST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIARIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/36113876.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (58,'113','61723847','NEON CTVM S.A.','NEON CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61723847.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (59,'119','13720915','BCO WESTERN UNION','Banco Western Union do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (60,'120','33603457','BCO RODOBENS S.A.','BANCO RODOBENS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/33603457.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (61,'121','10664513','BCO AGIBANK S.A.','Banco Agibank S.A.','Agibank | Agi','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10664513.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (62,'122','33147315','BCO BRADESCO BERJ S.A.','Banco Bradesco BERJ S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33147315.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (63,'124','15357060','BCO WOORI BANK DO BRASIL S.A.','Banco Woori Bank do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (64,'125','45246410','BANCO GENIAL','BANCO GENIAL S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/45246410.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (65,'126','13220493','BR PARTNERS BI','BR Partners Banco de Investimento S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (66,'127','09512542','CODEPE CVC S.A.','Codepe Corretora de Valores e Câmbio S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (67,'128','19307785','BRAZA BANK S.A. BCO DE CÂMBIO','BRAZA BANK S.A. BANCO DE CÂMBIO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (68,'129','18520834','UBS BB BI S.A.','UBS BB BANCO DE INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/18520834.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (69,'130','09313766','CARUANA SCFI','CARUANA S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (70,'131','61747085','TULLETT PREBON BRASIL CVC LTDA','TULLETT PREBON BRASIL CORRETORA DE VALORES E CÂMBIO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (71,'132','17453575','ICBC DO BRASIL BM S.A.','ICBC do Brasil Banco Múltiplo S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (72,'133','10398952','CRESOL CONFEDERAÇÃO','CONFEDERAÇÃO NACIONAL DAS COOPERATIVAS CENTRAIS DE CRÉDITO E ECONOMIA FAMILIAR E SOLIDÁRIA - CRESOL CONFEDERAÇÃO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10398952.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (73,'134','33862244','BGC LIQUIDEZ DTVM LTDA','BGC LIQUIDEZ DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (74,'136','00315557','UNICRED DO BRASIL','COOPERATIVA CENTRAL DE CRÉDITO UNICRED DO BRASIL - UNICRED DO BRASIL','Unicred','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00315557.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (75,'138','10853017','GET MONEY CC LTDA.','GET MONEY SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (76,'139','55230916','INTESA SANPAOLO BRASIL S.A. BM','Intesa Sanpaolo Brasil S.A. - Banco Múltiplo',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (77,'140','62169875','NU INVESTIMENTOS S.A. - CTVM','NU INVESTIMENTOS S.A. - CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62169875.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (78,'141','09526594','MASTER BI S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO MASTER DE INVESTIMENTO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (79,'142','16944141','BROKER BRASIL CC LTDA.','Broker Brasil Corretora de Câmbio Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (80,'143','02992317','INTEX BANK BCO DE CÂMBIO S.A.','INTEX BANK BANCO DE CÂMBIO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/02992317.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (81,'144','13059145','EBURY BCO DE CÂMBIO S.A.','EBURY BANCO DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (82,'145','50579044','LEVYCAM CCV LTDA','LEVYCAM - CORRETORA DE CAMBIO E VALORES LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (83,'146','24074692','GUITTA CC LTDA','GUITTA CORRETORA DE CAMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (84,'149','15581638','FACTA S.A. CFI','Facta Financeira S.A. - Crédito Financiamento e Investimento',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (85,'157','09105360','ICAP DO BRASIL CTVM LTDA.','ICAP do Brasil Corretora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (86,'159','05442029','CASA CREDITO S.A. SCM','Casa do Crédito S.A. Sociedade de Crédito ao Microempreendedor',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (87,'173','13486793','APEX GROUP DTVM','APEX GROUP DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (88,'174','43180355','PEFISA S.A. - C.F.I.','PEFISA S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/43180355.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (89,'180','02685483','CM CAPITAL MARKETS CCTVM LTDA','CM CAPITAL MARKETS CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (90,'183','09210106','SOCRED SA - SCMEPP','SOCRED S.A. - SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (91,'188','33775974','ATIVA S.A. INVESTIMENTOS CCTVM','ATIVA INVESTIMENTOS S.A. CORRETORA DE TÍTULOS, CÂMBIO E VALORES',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (92,'190','03973814','SERVICOOP','SERVICOOP - COOPERATIVA DE CRÉDITO DOS SERVIDORES PÚBLICOS ESTADUAIS E MUNICIPAIS DO RIO GRANDE DO SUL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (93,'191','04257795','NOVA FUTURA CTVM LTDA.','Nova Futura Corretora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (94,'194','20155248','UNIDA DTVM LTDA','UNIDA DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (95,'195','07799277','VALOR S/A SCFI','VALOR S/A SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (96,'196','32648370','FAIR SOCIEDADE CC','FAIR SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (97,'197','16501555','STONE IP S.A.','STONE INSTITUIÇÃO DE PAGAMENTO S.A.','Stone | Stone Pagamentos','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/16501555.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (98,'208','30306294','BANCO BTG PACTUAL S.A.','Banco BTG Pactual S.A.','BTG | BTG Pactual','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/30306294.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (101,'212','92894922','BANCO ORIGINAL','Banco Original S.A.','Original | Banco Original',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (102,'213','54403563','BCO ARBI S.A.','Banco Arbi S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/54403563.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (103,'217','91884981','BANCO JOHN DEERE S.A.','Banco John Deere S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (104,'218','71027866','BCO BS2 S.A.','Banco BS2 S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/71027866.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (105,'222','75647891','BCO CRÉDIT AGRICOLE BR S.A.','BANCO CRÉDIT AGRICOLE BRASIL S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (106,'224','58616418','BCO FIBRA S.A.','Banco Fibra S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/58616418.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (107,'233','62421979','BANCO BMG SOLUÇÕES FINANCEIRAS S.A.','BANCO BMG SOLUÇÕES FINANCEIRAS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62421979.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (108,'237','60746948','BCO BRADESCO S.A.','Banco Bradesco S.A.','Bradesco | Next | Next Bank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60746948.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (109,'241','31597552','BCO CLASSICO S.A.','BANCO CLASSICO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (110,'243','33923798','BANCO MASTER - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO MASTER S/A - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (111,'246','28195667','BCO ABC BRASIL S.A.','Banco ABC Brasil S.A.','ABC Brasil','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/28195667.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (112,'249','61182408','BANCO INVESTCRED UNIBANCO S.A.','Banco Investcred Unibanco S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (113,'250','50585090','BANCO BMG CONSIGNADO S.A.','BANCO BMG CONSIGNADO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/50585090.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (114,'254','14388334','PARANA BCO S.A.','PARANÁ BANCO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/14388334.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (115,'259','08609934','MONEYCORP BCO DE CÂMBIO S.A.','MONEYCORP BANCO DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (116,'260','18236120','NU PAGAMENTOS - IP','NU PAGAMENTOS S.A. - INSTITUIÇÃO DE PAGAMENTO','Nubank | Nu | Nu Pagamentos | NuBank | Nubank PJ','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18236120.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (117,'265','33644196','BCO FATOR S.A.','Banco Fator S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/33644196.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (118,'266','33132044','BCO CEDULA S.A.','BANCO CEDULA S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (119,'268','14511781','BARI CIA HIPOTECÁRIA','BARI COMPANHIA HIPOTECÁRIA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/14511781.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (120,'269','53518684','BCO HSBC S.A.','BANCO HSBC S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (121,'271','27842177','BPY CCTVM S.A.','BPY CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (122,'272','00250699','AGK CC S.A.','AGK CORRETORA DE CAMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (123,'273','08253539','COOP SULCREDI AMPLEA','COOPERATIVA DE CREDITO SULCREDI AMPLEA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (124,'274','11581339','BMP SCMEPP LTDA','BMP SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E A EMPRESA DE PEQUENO PORTE LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/11581339.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (125,'276','11970623','BCO SENFF S.A.','BANCO SENFF S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (126,'280','23862762','WILL FINANCEIRA S.A.CFI - EM LIQUIDAÇÃO EXTRAJUDICIAL','WILL FINANCEIRA S.A. CRÉDITO, FINANCIAMENTO E INVESTIMENTO - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (127,'281','76461557','CCR COOPAVEL','Cooperativa de Crédito Rural Coopavel',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (128,'283','89960090','RB INVESTIMENTOS DTVM LTDA.','RB INVESTIMENTOS DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LIMITADA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (129,'288','62237649','CAROL DTVM LTDA.','CAROL DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (130,'289','94968518','EFX CC LTDA.','EFX CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (131,'290','08561701','PAGSEGURO INTERNET IP S.A.','PAGSEGURO INTERNET INSTITUIÇÃO DE PAGAMENTO S.A.','PagBank | PagSeguro','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/08561701.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (132,'292','28650236','GALAPAGOS DTVM S.A.','GALAPAGOS CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/28650236.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (133,'293','71590442','LASTRO RDV DTVM LTDA','Lastro RDV Distribuidora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (134,'296','04062902','OZ CÂMBIO','OZ SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (135,'298','17772370','VIPS CC S.A.','VIPS CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (136,'299','04814563','BCO AFINZ S.A. - BM','BANCO AFINZ S.A. - BANCO MÚLTIPLO','Afinz',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (137,'300','33042151','BCO LA NACION ARGENTINA','Banco de la Nacion Argentina',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33042151.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (138,'301','13370835','DOCK IP S.A.','DOCK INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13370835.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (139,'305','40353377','FOURTRADE COR. DE CAMBIO LTDA','FOURTRADE CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (140,'307','03751794','TERRA INVESTIMENTOS DTVM','Terra Investimentos Distribuidora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (141,'310','22610500','VORTX DTVM LTDA.','VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/22610500.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (142,'312','07693858','HSCM SCMEPP LTDA.','HSCM - SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (143,'318','61186680','BCO BMG S.A.','Banco BMG S.A.','BMG','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61186680.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (144,'319','11495073','OM DTVM LTDA','OM DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (145,'320','07450604','BOC BRASIL','BANK OF CHINA (BRASIL) BANCO MÚLTIPLO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (146,'321','18188384','CREFAZ SCMEPP SA','CREFAZ SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E A EMPRESA DE PEQUENO PORTE S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (147,'322','01073966','CCR DE ABELARDO LUZ','Cooperativa de Crédito Rural de Abelardo Luz - Sulcredi/Crediluz',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (148,'323','10573521','MERCADO PAGO IP LTDA.','MERCADO PAGO INSTITUIÇÃO DE PAGAMENTO LTDA.','Mercado Pago | Mercado Livre','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10573521.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (149,'324','21332862','CARTOS SCD S.A.','CARTOS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (150,'326','03311443','MEUTUDO SCFI','MEUTUDO S.A - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/03311443.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (151,'329','32402502','QI SCD S.A.','QI Sociedade de Crédito Direto S.A.','QI | Qi Tech','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/32402502.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (152,'330','00556603','BANCO BARI S.A.','BANCO BARI DE INVESTIMENTOS E FINANCIAMENTOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/00556603.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (153,'331','13673855','OSLO CAPITAL DTVM SA','OSLO CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (154,'332','13140088','ACESSO SOLUÇÕES DE PAGAMENTO S.A. - INSTITUIÇÃO DE PAGAMENTO','ACESSO SOLUÇÕES DE PAGAMENTO S.A. - INSTITUIÇÃO DE PAGAMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13140088.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (155,'334','15124464','BANCO BESA S.A.','BANCO BESA S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (156,'335','27098060','BANCO DIGIO','Banco Digio S.A.','Digio','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/27098060.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (157,'336','31872495','BCO C6 S.A.','Banco C6 S.A.','C6 | C6 Bank | C6 Pay','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/31872495.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (158,'341','60701190','ITAÚ UNIBANCO S.A.','ITAÚ UNIBANCO S.A.','Itaú Unibanco | Itaú | Itau','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60701190.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (159,'342','32997490','CREDITAS SCD','Creditas Sociedade de Crédito Direto S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (160,'348','33264668','BCO XP S.A.','Banco XP S.A.','XP | XP Investimentos','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33264668.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (161,'349','27214112','AL5 S.A. SCFI','AL5 S.A. SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (162,'350','01330387','COOPERATIVA DE CRÉDITO POPULAR DO BRASIL','COOPERATIVA DE CRÉDITO POPULAR DO BRASIL - CREHNOR',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (163,'352','29162769','SANTANDER CTVM S.A.','SANTANDER CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/29162769.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (164,'355','34335592','ÓTIMO SCD S.A.','ÓTIMO SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (165,'358','09464032','MIDWAY S.A. - SCFI','MIDWAY S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/09464032.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (166,'359','05351887','ZEMA CFI S/A','ZEMA CRÉDITO, FINANCIAMENTO E INVESTIMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (167,'360','02276653','TRINUS CAPITAL DTVM','TRINUS CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (168,'362','01027058','CIELO IP S.A.','CIELO S.A. - INSTITUIÇÃO DE PAGAMENTO','Cielo','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/01027058.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (169,'363','62285390','QI CTVM S.A.','QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62285390.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (170,'364','09089356','EFÍ S.A. - IP','EFÍ S.A. - INSTITUIÇÃO DE PAGAMENTO','Efí | Gerencianet','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/09089356.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (171,'365','68757681','BINANCE BRASIL','BINANCE BRASIL CORRETORA DE CÂMBIO E VALORES MOBILIÁRIOS S.A.','Binance',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (172,'366','61533584','BCO SOCIETE GENERALE BRASIL','BANCO SOCIETE GENERALE BRASIL S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (173,'368','08357240','BCO CSF S.A.','Banco CSF S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/08357240.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (174,'370','61088183','BCO MIZUHO S.A.','Banco Mizuho do Brasil S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/61088183.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (175,'373','35977097','UP.P SEP S.A.','UP.P SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (176,'374','27351731','REALIZE SCFI S.A.','REALIZE SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/27351731.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (177,'376','33172537','BCO J.P. MORGAN S.A.','BANCO J.P. MORGAN S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/33172537.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (178,'377','17826860','BMS SCD S.A.','BMS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (179,'378','01852137','BCO BRASILEIRO DE CRÉDITO S.A.','BANCO BRASILEIRO DE CRÉDITO SOCIEDADE ANÔNIMA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (180,'379','01658426','COOP COOPERFORTE LTDA.','COOPERFORTE COOPERATIVA DE CRÉDITO E INVESTIMENTOS LTDA','Cooperforte',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (181,'380','22896431','PICPAY','PICPAY INSTITUIçãO DE PAGAMENTO S.A.','PicPay | Pic Pay','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/22896431.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (182,'381','60814191','BCO MERCEDES-BENZ S.A.','BANCO MERCEDES-BENZ DO BRASIL S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/60814191.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (183,'382','04307598','FIDUCIA SCMEPP LTDA','FIDÚCIA SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LIMITADA.','Fidúcia',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (184,'383','21018182','EBANX IP LTDA.','EBANX INSTITUICAO DE PAGAMENTOS LTDA.','EBANX','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/21018182.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (185,'384','11165756','GLOBAL SCM LTDA','GLOBAL FINANÇAS SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (186,'385','03844699','CECM DOS TRAB.PORT. DA G.VITOR','COOPERATIVA DE ECONOMIA E CREDITO MUTUO DOS TRABALHADORES PORTUARIOS DA GRANDE VITORIA - CREDESTIVA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (187,'386','30680829','NU FINANCEIRA S.A. CFI','NU FINANCEIRA S.A. - Sociedade de Crédito, Financiamento e Investimento',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/30680829.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (188,'389','17184037','BCO MERCANTIL DO BRASIL S.A.','Banco Mercantil do Brasil S.A.','Mercantil','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/17184037.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (189,'390','59274605','BCO GM S.A.','BANCO GM S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (190,'391','08240446','CCR DE IBIAM','COOPERATIVA DE CREDITO RURAL DE IBIAM - SULCREDI/IBIAM',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (191,'393','59109165','BCO VOLKSWAGEN S.A','Banco Volkswagen S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/59109165.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (192,'394','07207996','BCO BRADESCO FINANC. S.A.','Banco Bradesco Financiamentos S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/07207996.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (193,'395','08673569','F D GOLD DTVM LTDA','F.D\'GOLD - DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (194,'396','13884775','MAGALUPAY','MAGALUPAY INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13884775.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (195,'397','34088029','LISTO SCD S.A.','LISTO SOCIEDADE DE CREDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/34088029.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (196,'398','31749596','IDEAL CTVM S.A.','IDEAL CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (197,'399','01701201','Kirton Bank','Kirton Bank S.A. - Banco Múltiplo',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (198,'400','05491616','COOP CREDITAG - EM LIQUIDAÇÃO EXTRAJUDICIAL','COOPERATIVA DE CRÉDITO, POUPANÇA E SERVIÇOS FINANCEIROS - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (199,'401','15111975','IUGU IP S.A.','IUGU INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/15111975.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (200,'402','36947229','COBUCCIO S.A. SCFI','COBUCCIO S/A - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (201,'403','37880206','CORA SCFI','CORA SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.','Cora','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37880206.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (202,'404','37241230','SUMUP SCFI S.A','SUMUP SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.','SumUp','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37241230.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (203,'406','37715993','ACCREDITO SCD S.A.','ACCREDITO - SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37715993.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (204,'407','00329598','SEFER INVESTIMENTOS DTVM LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL','SEFER INVESTIMENTOS DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00329598.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (205,'408','36586946','BONUSPAGO SCD S.A.','BONUSPAGO SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (206,'410','05684234','PLANNER SOCIEDADE DE CRÉDITO DIRETO','PLANNER SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (207,'411','05192316','VIA CERTA FINANCIADORA S.A. - CFI','Via Certa Financiadora S.A. - Crédito, Financiamento e Investimentos',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (208,'412','15173776','SOCIAL BANK S/A','SOCIAL BANK BANCO MÚLTIPLO S/A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/15173776.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (209,'413','01858774','BCO BV S.A.','BANCO BV S.A.','BV | Banco BV | Votorantim','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/01858774.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (210,'414','37526080','LEND SCD S.A.','LEND SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (211,'415','17157777','BCO NACIONAL','BANCO NACIONAL S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (212,'416','19324634','LAMARA SCD S.A.','LAMARA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (213,'418','37414009','ZIPDIN SCD S.A.','ZIPDIN SOLUÇÕES DIGITAIS SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (214,'419','38129006','NUMBRS SCD S.A.','NUMBRS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (215,'421','39343350','CC LAR CREDI','LAR COOPERATIVA DE CRÉDITO - LAR CREDI',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (216,'422','58160789','BCO SAFRA S.A.','Banco Safra S.A.','Safra','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/58160789.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (217,'423','00460065','COLUNA S.A. DTVM','COLUNA S/A DISTRIBUIDORA DE TITULOS E VALORES MOBILIÁRIOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (218,'425','03881423','SOCINAL S.A. CFI','SOCINAL S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO','Socinal',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (219,'426','11285104','NEON FINANCEIRA - SCFI S.A.','NEON FINANCEIRA - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/11285104.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (220,'427','27302181','CRED.UFES','COOPERATIVA DE CRÉDITO DOS SERVIDORES DA UNIVERSIDADE FEDERAL DO ESPIRITO SANTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (221,'428','39664698','CREDSYSTEM SCD S.A.','CREDSYSTEM SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/39664698.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (222,'430','00204963','CCR SEARA','COOPERATIVA DE CREDITO RURAL SEARA - CREDISEARA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (223,'433','44077014','BR-CAPITAL DTVM S.A.','BR-CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (224,'435','38224857','DELFINANCE SCD S.A.','DELFINANCE SOCIEDADE DE CREDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (225,'438','67030395','TRUSTEE DTVM LTDA. - EM LIQUIDAÇÃO EXTRAJUDICIAL','TRUSTEE DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (226,'439','16695922','ID CTVM','ID CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (227,'440','82096447','COOP CREDI&GENTE','CREDI&GENTE - COOPERATIVA DE CRÉDITO E INVESTIMENTOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (228,'443','39416705','OCTA SCD S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','OCTA SOCIEDADE DE CRÉDITO DIRETO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (229,'444','40654622','TRINUS SCD S.A.','TRINUS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (230,'445','35551187','PLANTAE CFI','PLANTAE S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (231,'447','12392983','MIRAE ASSET (BRASIL) CCTVM LTDA.','MIRAE ASSET (BRASIL) CORRETORA DE CÂMBIO, TÍTULOS  E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (232,'448','39669186','HEMERA DTVM LTDA.','HEMERA DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (233,'449','37555231','DM','DM SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (234,'450','13203354','FITS IP','FITS INSTITUIÇÃO DE PAGAMENTO S.A.','Fits','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13203354.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (235,'451','40475846','J17 - SCD S/A','J17 - SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (236,'452','39676772','CREDIFIT SCD S.A.','CREDIFIT SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (237,'454','41592532','MÉRITO DTVM LTDA.','MÉRITO DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (238,'456','60498557','BCO MUFG BRASIL S.A.','Banco MUFG Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (239,'457','39587424','UY3 SCD S/A','UY3 SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (240,'458','07253654','HEDGE INVESTMENTS DTVM LTDA.','HEDGE INVESTMENTS DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (241,'460','42047025','UNAVANTI SCD S/A','UNAVANTI SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (242,'461','19540550','ASAAS IP S.A.','ASAAS GESTÃO FINANCEIRA INSTITUIÇÃO DE PAGAMENTO S.A.','Asaas','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/19540550.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (243,'462','39908427','STARK SCD S.A.','STARK SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (244,'463','40434681','AZUMI DTVM','AZUMI DISTRIBUIDORA DE TíTULOS E VALORES MOBILIáRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (245,'464','60518222','BCO SUMITOMO MITSUI BRASIL S.A.','Banco Sumitomo Mitsui Brasileiro S.A.','Sumitomo Mitsui | SMBC',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (246,'465','40083667','CAPITAL CONSIG SCD S.A.','CAPITAL CONSIG SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (247,'467','33886862','MASTER S/A CCTVM - EM LIQUIDAÇÃO EXTRAJUDICIAL','MASTER S/A CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (248,'468','04862600','PORTOSEG S.A. CFI','PORTOSEG S.A. - CREDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (249,'469','07138049','PICPAY INVEST','PICPAY INVEST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/07138049.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (250,'470','18394228','CDC SCD S.A.','CDC SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (251,'473','33466988','BCO CAIXA GERAL BRASIL S.A.','Banco Caixa Geral - Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (252,'475','10371492','BCO YAMAHA MOTOR S.A.','Banco Yamaha Motor do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (253,'476','45860531','IDEA MAKER IP LTDA','IDEA MAKER INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (254,'477','33042953','CITIBANK N.A.','Citibank N.A.','Citibank | Citi','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33042953.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (255,'478','11760553','GAZINCRED S.A. SCFI','GAZINCRED S.A. SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (256,'479','60394079','BCO ITAUBANK S.A.','Banco ItauBank S.A.','ItaúBank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60394079.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (257,'481','43599047','SUPERLÓGICA SCD S.A.','SUPERLÓGICA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (258,'482','42259084','ARTTA SCD','ARTTA SOCIEDADE DE CRÉDITO DIRETO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (259,'484','36864992','APEX DTVM','APEX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (260,'487','62331228','DEUTSCHE BANK S.A.BCO ALEMAO','DEUTSCHE BANK S.A. - BANCO ALEMAO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/62331228.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (261,'488','46518205','JPMORGAN CHASE BANK','JPMorgan Chase Bank, National Association',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/46518205.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (262,'495','44189447','BCO LA PROVINCIA B AIRES BCE','Banco de La Provincia de Buenos Aires',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (263,'496','45283173','BBVA BRASIL BI S.A.','BBVA BRASIL BANCO DE INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (264,'505','32062580','BCO UBS BRASIL','BANCO UBS (BRASIL) S.A.','UBS','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/32062580.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (265,'506','42066258','RJI','RJI CORRETORA DE TITULOS E VALORES MOBILIARIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (266,'507','37229413','SCFI EFÍ S.A.','SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO EFÍ S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37229413.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (267,'508','61384004','AVENUE SECURITIES BI S.A.','AVENUE SECURITIES BANCO DE INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (268,'509','13935893','CELCOIN IP S.A.','CELCOIN INSTITUICAO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13935893.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (269,'510','39738065','FFCRED SCD S.A.','FFCRED SOCIEDADE DE CRÉDITO DIRETO S.A..',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (270,'511','44683140','MAGNUM SCD','MAGNUM SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (271,'512','36266751','FINVEST DTVM','FINVEST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (272,'513','44728700','ATF SCD S.A.','ATF SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (273,'514','73302408','EXIM SCC','EXIM SOCIEDADE CORRETORA DE CÂMBIO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (274,'516','36583700','PLACARPAY S.A - SCFI','PLACARPAY S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (275,'517','03816413','PAGUEVELOZ IP LTDA.','PAGUEVELOZ INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/03816413.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (276,'518','37679449','MERCADO CRÉDITO SCFI S.A.','MERCADO CRÉDITO SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37679449.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (277,'519','40768766','LIONS TRUST DTVM','LIONS TRUST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (278,'520','44705774','SOMAPAY SCD S.A.','SOMAPAY SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (279,'521','44019481','PEAK SEP S.A.','PEAK SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (280,'522','47593544','RED SCD S.A.','RED SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (281,'523','44292580','HR DIGITAL SCD','HR DIGITAL - SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (282,'524','45854066','WNT CAPITAL DTVM','WNT CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (283,'526','46026562','MONETARIE SCD','MONETARIE SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (284,'527','44478623','ATICCA SCD S.A.','ATICCA - SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (285,'528','34829992','CBSF DTVM -EM LIQUIDAÇÃO EXTRAJUDICIAL','CBSF DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.- EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (286,'529','17079937','PINBANK IP','PINBANK BRASIL INSTITUIÇÃO DE PAGAMENTO S.A.','PinBank',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (287,'530','47873449','SER FINANCE SCD S.A.','SER FINANCE SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (288,'531','34337707','BMP SCD S.A.','BMP SOCIEDADE DE CRÉDITO DIRETO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (289,'532','45745537','FUTURO SCD','FUTURO SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (290,'533','22575466','SRM BANK','SRM BANK INSTITUIÇÃO DE PAGAMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (291,'534','00714671','EWALLY IP S.A.','EWALLY INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/00714671.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (292,'535','39519944','OPEA SCD','OPEA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (293,'536','20855875','NEON PAGAMENTOS S.A. IP','NEON PAGAMENTOS S.A. - INSTITUIÇÃO DE PAGAMENTO','Neon | Neon Pagamentos','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/20855875.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (294,'537','45756448','SELECT CREDIT SCMEPP LTDA.','SELECT CREDIT SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (295,'538','20251847','SUDACRED SCD S.A.','SUDACRED SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (296,'539','00122327','SANTINVEST S.A. - CFI','SANTINVEST S.A. - CREDITO, FINANCIAMENTO E INVESTIMENTOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (297,'540','04849745','HBI SCD','HBI SOCIEDADE DE CRÉDITO DIRETO S/A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (298,'541','00954288','FDO GARANTIDOR CRÉDITOS','FUNDO GARANTIDOR DE CREDITOS - FGC',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00954288.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (299,'542','18189547','CLOUDWALK IP LTDA','CLOUDWALK INSTITUIÇÃO DE PAGAMENTO E SERVICOS LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18189547.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (300,'543','92825397','COOPCRECE','COOPERATIVA DE ECONOMIA E CRÉDITO MÚTUO DOS ELETRICITÁRIOS E DOS TRABALHADORES DAS EMPRESAS DO SETOR DE ENERGIA - COOPCRECE',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (301,'544','38593706','MULTICRED SCD S.A.','MULTICRED SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (302,'546','30980539','OKTO IP','OKTO INSTITUIÇÃO DE PAGAMENTO S.A.','Okto',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (303,'547','45331622','BNK DIGITAL SCD S.A.','BNK DIGITAL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (304,'548','06249129','RPW S.A. SCFI','RPW S/A SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (305,'550','32074986','BEETELLER IP LTDA.','BEETELLER INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (306,'551','48967968','VERT DTVM LTDA.','VERT DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (307,'552','32192325','UZZIPAY IP S.A.','UZZIPAY INSTITUIÇÃO DE PAGAMENTO S.A.','UzziPay',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (308,'553','48707451','PERCAPITAL SCD S.A.','PERCAPITAL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (309,'554','28811341','BCO STONEX S.A.','BANCO STONEX S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (310,'555','02682287','PAN FINAN','PAN FINANCEIRA S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTOS',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02682287.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (311,'556','40333582','SAYGO CC S.A.','SAYGO SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (312,'557','30944783','PAGPRIME IP','PAGPRIME INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (313,'559','49288113','KANASTRA CFI','KANASTRA FINANCEIRA S.A, CREDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (314,'560','21995256','MAG IP LTDA.','MAG INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (315,'561','20757199','PAY4FUN IP S.A.','PAY4FUN INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (316,'562','18684408','AZIMUT BRASIL DTVM LTDA','AZIMUT BRASIL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (317,'563','40276692','PROTEGE CASH','PROTEGE CASH INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (318,'564','63019146','ANKOR CFI S.A.','ANKOR CAPITAL - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (319,'565','74014747','ÁGORA CTVM S.A.','ÁGORA CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/74014747.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (320,'566','23114447','FLAGSHIP IP LTDA','FLAGSHIP INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (321,'567','33040601','MERCANTIL FINANCEIRA','MERCANTIL FINANCEIRA S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33040601.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (322,'569','12473687','CONTA PRONTA IP','CONTA PRONTA INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (323,'571','50489148','MONTE BRAVO CTVM S.A.','MONTE BRAVO CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (324,'572','51414521','ALL IN CRED SCD S.A.','ALL IN CRED SOCIEDADE DE CREDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (325,'573','18282093','OXY CH','OXY COMPANHIA HIPOTECÁRIA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (326,'574','48756121','A55 SCD S.A.','A55 SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (327,'575','48584954','DGBK CREDIT S.A. - SOCIEDADE DE CRÉDITO DIRETO.','DGBK CREDIT S.A. - SOCIEDADE DE CRÉDITO DIRETO.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (328,'576','11351086','MERCADO BITCOIN IP LTDA','MERCADO BITCOIN INSTITUICAO DE PAGAMENTO LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/11351086.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (329,'577','10663610','AF DESENVOLVE SP S.A.','DESENVOLVE SP - AGÊNCIA DE FOMENTO DO ESTADO DE SÃO PAULO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (330,'579','49555647','QUADRA SCD','QUADRA SOCIEDADE DE CRÉDITO DIRETO S.A.','Quadra',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (331,'585','50946592','SETHI SCD SA','SETHI SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (332,'586','35810871','Z1 IP LTDA.','Z1 INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (333,'587','37678915','FIDD DTVM LTDA.','FIDD DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (334,'588','20308187','AVANCARD PROVER IP LTDA','AVANCARD PROVER INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/20308187.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (335,'589','51212088','G5 SCD SA','G5 SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (336,'590','40473435','REPASSES FINANCEIROS E SOLUCOES TECNOLOGICAS IP S.A.','REPASSES FINANCEIROS E SOLUCOES TECNOLOGICAS INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (337,'591','02671743','BANVOX DTVM - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANVOX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (338,'592','45548763','MAPS IP LTDA.','INSTITUIÇÃO DE PAGAMENTOS MAPS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (339,'593','27084098','TRANSFEERA IP S.A.','TRANSFEERA INSTITUIÇÃO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (340,'594','48703388','ASA SCFI S.A.','ASA SOCIEDADE DE CRÉDITO FINANCIAMENTO E INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/48703388.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (341,'595','19468242','IFOOD PAGO IP','IFOOD PAGO INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/19468242.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (342,'596','39696395','CACTVS IP S.A.','CACTVS INSTITUICAO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (343,'597','34747388','ISSUER IP LTDA.','ISSUER INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (344,'598','50626276','KONECT SCD S/A','KONECT SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (345,'599','36321990','AGORACRED S/A SCFI','AGORACRED S/A SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (346,'600','59118133','BCO LUSO BRASILEIRO S.A.','Banco Luso Brasileiro S.A.','Luso Brasileiro',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (347,'604','31895683','BCO INDUSTRIAL DO BRASIL S.A.','Banco Industrial do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (348,'610','78626983','BCO VR S.A.','Banco VR S.A.','VR',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (349,'611','61820817','BCO PAULISTA S.A.','Banco Paulista S.A.','Paulista','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/61820817.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (350,'612','31880826','BCO GUANABARA S.A.','Banco Guanabara S.A.','Guanabara','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/31880826.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (351,'613','60850229','OMNI BANCO S.A.','Omni Banco S.A.','Omni','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/60850229.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (352,'614','52440987','SANTS SCD S.A.','SANTS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (353,'615','37470405','SMART SOLUTIONS GROUP IP LTDA','SMART SOLUTIONS GROUP INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (354,'619','49931906','TRIO IP LTDA.','TRIO INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (355,'620','51342763','REVOLUT SCD S.A.','REVOLUT SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/51342763.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (356,'623','59285411','BANCO PAN','Banco Pan S.A.','Pan | Banco Pan','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/59285411.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (357,'626','61348538','BCO C6 CONSIG','BANCO C6 CONSIGNADO S.A.','C6 Consignado','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61348538.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (358,'630','58497702','BANCO LETSBANK S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO LETSBANK S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (359,'632','52586293','Z-ON SCD S.A.','Z-ON SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (360,'633','68900810','BCO RENDIMENTO S.A.','Banco Rendimento S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/68900810.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (361,'634','17351180','BCO TRIANGULO S.A.','BANCO TRIANGULO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (362,'636','40112555','GIRO - SCD S/A','GIRO - SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (363,'637','60889128','BCO SOFISA S.A.','BANCO SOFISA S.A.','Sofisa | Sofisa Direto','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60889128.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (364,'643','62144175','BCO PINE S.A.','Banco Pine S.A.','Pine','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62144175.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (365,'644','54647259','321 SCD S.A.','321 SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (366,'646','91669747','DM SCFI','DM SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (367,'651','25104230','PAGARE IP S.A.','PAGARE INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (368,'653','61024352','BM PLENO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO PLENO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (369,'654','92874270','BCO DIGIMAIS S.A.','BANCO DIGIMAIS S.A.','Digimais',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (370,'655','59588111','BCO VOTORANTIM S.A.','Banco Votorantim S.A.','Votorantim','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/59588111.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (371,'659','35210410','ONEKEY PAYMENTS IP S.A.','ONEKEY PAYMENTS INSTITUICAO DE PAGAMENTO SA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (372,'660','34471744','PAGME IP LTDA','PAGME INSTITUIÇÃO DE PAGAMENTO LTDA.','PagMe',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (373,'661','55428859','FREEX SCC S.A.','FREEX SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (374,'662','32708748','WE PAY OUT IP LTDA.','WE PAY OUT INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (375,'663','44782130','ACTUAL DTVM S.A.','ACTUAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (376,'665','20018183','STARK BANK S.A. - IP','STARK BANK S.A. - INSTITUICAO DE PAGAMENTO','Stark Bank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/20018183.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (377,'668','48632754','CELCOIN SCD','CELCOIN SOCIEDADE DE CRÉDITO DIRETO S.A.','Celcoin','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/48632754.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (378,'669','47133056','TRANSFERO IP LTDA.','TRANSFERO INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (379,'670','11491029','BSN','BSN PAGAMENTOS INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (380,'671','26264220','ZERO IP','ZERO INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (381,'672','53505601','STONE CFI S.A.','STONE SOCIEDADE DE CREDITO, FINANCIAMENTO E INVESTIMENTO S.A.','Stone','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/53505601.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (382,'673','08482873','CCR DO AGRESTE ALAGOANO - EM LIQUIDAÇÃO EXTRAJUDICIAL','COOPERATIVA DE CRÉDITO RURAL DO AGRESTE ALAGOANO - COOPERAGRE - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (383,'674','27970567','HINOVA PAY IP S.A.','HINOVA PAY INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (384,'675','30723871','CASAS BAHIA PAY IP LTDA.','CASAS BAHIA PAY INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/30723871.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (385,'676','35479592','DUFRIO CFI S.A.','DUFRIO FINANCEIRA, CRÉDITO, FINANCIAMENTO E INVESTIMENTOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (386,'677','33630661','GOWD IP LTDA.','GOWD INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (387,'678','45716916','FIDEM SCD S/A','FIDEM SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (388,'679','36690516','PAY IP S.A.','PAY INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (389,'680','55823094','DELTA GLOBAL SCD S.A.','DELTA GLOBAL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (390,'681','50871921','MT IP S.A.','MT INSTITUICAO DE PAGAMENTO SA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (391,'682','46505612','MONERY IP S.A.','MONERY INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (392,'683','30507541','BRASIL CASH IP S.A.','BRASIL CASH INSTITUICAO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (393,'684','56392166','HARMOS S.A. - SCFI','HARMOS S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (394,'685','26615279','TYCOON TECHNOLOGY IIP S.A','TYCOON TECHNOLOGY INSTITUICAO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (395,'686','12481100','BIZ IP LTDA.','BIZ INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (396,'687','35340796','INCO SEP S.A.','INCO SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (397,'688','43978697','KIKAI SCD S.A.','KIKAI SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (398,'690','16814330','BK IP S.A.','BK INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (399,'692','56198117','ZYDI','ZYDI SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (400,'693','32820711','EFEX IP','EFEX INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (401,'694','54811417','WOOVI IP LTDA.','WOOVI INSTITUICAO DE PAGAMENTO LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/54811417.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (402,'695','35523352','BEES IP LTDA.','BEES INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (403,'696','50032584','LOAN BRASIL SCD S.A.','LOAN BRASIL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (404,'697','45056494','JM CORRETORA DE CÂMBIO','JM CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (405,'698','58367961','BIT SCD S.A.','BIT SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (406,'699','59396084','BFC SCD S.A.','BFC SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (407,'700','53822116','MW IP LTDA. - EM LIQUIDAÇÃO EXTRAJUDICIAL','MW INSTITUICAO DE PAGAMENTO LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (408,'701','51118615','INTEGRAÇÃO DE CRÉDITO E COBRANÇA SCD','INTEGRAÇÃO DE CRÉDITO E COBRANÇA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (409,'703','10440482','GETNET IP','GETNET ADQUIRÊNCIA E SERVIÇOS PARA MEIOS DE PAGAMENTO S.A. INSTITUIÇÃO DE PAGAMENTO','GetNet','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10440482.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (410,'704','44663846','FESTOR IP LTDA.','FESTOR INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (411,'707','62232889','BCO DAYCOVAL S.A','Banco Daycoval S.A.','Daycoval',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (412,'708','33588252','BCO INDUSCRED DE INVESTIM. S/A','BANCO INDUSCRED DE INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (413,'712','78632767','OURIBANK S.A.','OURIBANK S.A. BANCO MÚLTIPLO','Ouribank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/78632767.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (414,'714','00411939','FINAMAX S.A. CFI','FINAMAX S.A. - CREDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (415,'719','33884941','BANCO MASTER MÚLTIPLO - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO MASTER MÚLTIPLO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','Master',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (416,'741','00517645','BCO RIBEIRAO PRETO S.A.','BANCO RIBEIRAO PRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00517645.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (417,'743','00795423','BANCO SEMEAR','Banco Semear S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00795423.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (418,'745','33479023','BCO CITIBANK S.A.','Banco Citibank S.A.','Citibank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33479023.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (419,'747','01023570','BCO RABOBANK INTL BRASIL S.A.','Banco Rabobank International Brasil S.A.','Rabobank',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (420,'748','01181521','BANCO COOPERATIVO SICREDI','BANCO COOPERATIVO SICREDI S.A.','Sicredi','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/01181521.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (421,'751','29030467','Scotiabank Brasil','Scotiabank Brasil S.A. Banco Múltiplo','Scotiabank',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (422,'752','01522368','BCO BNP PARIBAS BRASIL S A','Banco BNP Paribas Brasil S.A.','BNP Paribas',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (423,'753','74828799','NOVO BCO CONTINENTAL S.A. - BM','Novo Banco Continental S.A. - Banco Múltiplo',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (424,'754','76543115','BANCO SISTEMA','Banco Sistema S.A.','Banco Sistema',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (425,'755','62073200','BOFA MERRILL LYNCH BM S.A.','Bank of America Merrill Lynch Banco Múltiplo S.A.','Bank of America | BOFA',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (426,'756','02038232','BANCO SICOOB S.A.','BANCO COOPERATIVO SICOOB S.A. - BANCO SICOOB','Sicoob','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02038232.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (427,'757','02318507','BCO KEB HANA DO BRASIL S.A.','BANCO KEB HANA DO BRASIL S.A.','KEB Hana',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (428,'759','42963742','BANSUR JM SCD S.A.','BANSUR JM SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (429,'760','34139916','EMCASH SERV FINANC SEP S.A.','EMCASH SERVIÇOS FINANCEIROS SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (430,'761','53842122','URBANO S.A. SCFI','URBANO S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (431,'763','56106523','VUE IP S.A.','VUE INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (432,'764','04306351','INDEPENDÊNCIA CC','INDEPENDÊNCIA COOPERATIVA DE CRÉDITO E INVESTIMENTO - INDEPENDÊNCIA COOPERATIVA DE CRÉDITO','Independência',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:52:22');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (433,'765','37753531','PAGSMILE IP LTDA.','PAGSMILE INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (434,'766','52833288','LB PAY IP LTDA','LB PAY INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (435,'767','62264924','QORE','QORE DISTRIBUIDORA DE TITULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (436,'768','20443996','BECKER FINANCEIRA SA - CFI','BECKER FINANCEIRA S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (437,'769','24313102','99PAY IP S.A.','99PAY INSTITUICAO DE PAGAMENTO S.A.','99Pay | 99','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/24313102.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (438,'770','38320462','V3 IP S.A.','V3 INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (439,'771','57824223','WX IP LTDA.','WX INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (440,'773','53908413','KIWIFY IP','KIWIFY INSTITUICAO DE PAGAMENTO LTDA','Kiwify','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/53908413.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (441,'774','33959738','MOVA SEP S.A.','MOVA SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (442,'775','47381104','CONTAAZUL IP LTDA.','CONTAAZUL INSTITUICAO DE PAGAMENTO LTDA.','ContaAzul','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/47381104.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (443,'776','44650156','ONCRED - SCD S.A.','ONCRED - SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (444,'778','58674454','PB SCD','PB SOCIEDADE DE CREDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (445,'780','12102128','SAFETYPAY BRASIL IP LTDA','SAFETYPAY BRASIL INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (446,'781','58006471','BASE DTVM','BASE DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (447,'783','31680151','SWAP IP S.A.','SWAP INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/31680151.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (448,'784','17768068','PINPAG IP S.A.','PINPAG INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (449,'785','53058329','LA FINTECA IP LTDA','LA FINTECA INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (450,'786','52076716','AWX BRASIL IP LTDA.','AWX BRASIL  INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (451,'787','10789035','ATTRUS IP S/A','ATTRUS INSTITUIÇÃO DE PAGAMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (452,'788','35713491','PROTOTYPE IP S.A.','PROTOTYPE INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (453,'789','57654096','APUSDIGITAL IP LTDA.','APUSDIGITAL INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (454,'790','54024532','MAX IP','MAX INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (455,'791','62448932','MULTIPLIKE FINANCEIRA S.A. SCFI','MULTIPLIKE FINANCEIRA S.A. SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (456,'792','44921281','NIXFIN SCD','NIXFIN SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (457,'793','61021673','MAGALUPAY SCFI S.A.','MAGALUPAY - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.','MagaluPay | Magalu','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61021673.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (458,'794','44323831','ATUAL CC LTDA','ATUAL SOCIEDADE CORRETORA DE CÂMBIO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (459,'795','52067630','BANCO TRATON BRASIL S.A.','BANCO TRATON BRASIL S.A.','Traton',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (460,'796','48786608','ASAAS CFI S.A','ASAAS SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (461,'798','01648418','NSTECH IP S.A.','NSTECH IP INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (462,'803','25021356','DLOCAL BRASIL IP S.A.','DLOCAL BRASIL INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (463,'804','32343119','MÊNTORE IP S.A.','MÊNTORE INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (464,'805','38486817','BCO DES. DE MG S.A.','BANCO DE DESENVOLVIMENTO DE MINAS GERAIS S.A.-BDMG','Desenvolve MG',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (465,'807','63822040','GUARDIAN SCD S.A.','GUARDIAN SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
INSERT INTO `banks` (`id`, `compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`, `active`, `created_at`, `updated_at`) VALUES (466,'808','40867163','RENDIMENTO SCD','RENDIMENTO SOCIEDADE DE CRÉDITO DIRETO S.A.','Rendimento',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
/*!40000 ALTER TABLE `banks` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

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
