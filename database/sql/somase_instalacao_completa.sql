-- ============================================================
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `accounts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `name` varchar(120) NOT NULL,
  `bank_name` varchar(120) DEFAULT NULL,
  `account_type` enum('checking','savings','investment','cash','other') NOT NULL DEFAULT 'checking',
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
  CONSTRAINT `fk_accounts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
  `code` varchar(40) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_cost_centers_user` (`user_id`,`status`),
  CONSTRAINT `fk_cost_centers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
  `name` varchar(150) NOT NULL,
  `amount_invested` decimal(15,2) NOT NULL DEFAULT 0.00,
  `application_date` date NOT NULL,
  `interest_rate` decimal(12,6) DEFAULT NULL,
  `rate_type` varchar(40) DEFAULT NULL,
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
  CONSTRAINT `fk_investments_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `fk_investments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
  CONSTRAINT `fk_transactions_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  CONSTRAINT `fk_transactions_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transactions_cost_center` FOREIGN KEY (`cost_center_id`) REFERENCES `cost_centers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transactions_recurrence` FOREIGN KEY (`recurrence_id`) REFERENCES `recurring_transactions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=135 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (1,NULL,'Pessoal','PES','Despesas e receitas pessoais','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (2,NULL,'Casa','CAS','Moradia e manutenção','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (3,NULL,'Empresa','EMP','Operação do negócio','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (4,NULL,'Carro','CAR','Veículo e transporte','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
INSERT INTO `cost_centers` (`id`, `user_id`, `name`, `code`, `description`, `status`, `created_at`, `updated_at`) VALUES (5,NULL,'Operacional','OPE','Custos operacionais gerais','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `cost_centers` ENABLE KEYS */;
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
