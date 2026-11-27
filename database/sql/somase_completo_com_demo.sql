-- ============================================================
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

LOCK TABLES `account_movements` WRITE;
/*!40000 ALTER TABLE `account_movements` DISABLE KEYS */;
/*!40000 ALTER TABLE `account_movements` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
INSERT INTO `accounts` VALUES
(1,1,'Conta Corrente','Banco do Brasil','checking','1234','56789-0',4200.00,55241.20,'2026-04-01','active','SOMASE demo','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,1,'Reserva de emergencia','Nubank','savings',NULL,'0001',12000.00,12000.00,'2026-04-01','active','SOMASE demo','2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `audit_logs` WRITE;
/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
INSERT INTO `audit_logs` VALUES
(1,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:45:07'),
(2,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:45:29'),
(3,NULL,NULL,'register','user',3,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:45:29'),
(4,NULL,2,'export_users','user',NULL,'{\"filtros\":{\"q\":\"\",\"status\":\"\",\"role\":\"\",\"provider\":\"\",\"de\":\"\",\"ate\":\"\",\"sort\":\"created\",\"dir\":\"desc\",\"page\":1}}','127.0.0.1','curl/8.5.0','2026-11-27 19:45:50'),
(5,NULL,3,'login','user',3,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:45:50'),
(6,NULL,2,'admin_reset_password','user',2,'[]','127.0.0.1','curl/8.5.0','2026-11-27 19:45:50'),
(7,NULL,2,'admin_toggle_user','user',3,'{\"status\":\"inactive\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:46:16'),
(8,NULL,2,'admin_toggle_user','user',3,'{\"status\":\"active\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:46:16'),
(9,NULL,2,'admin_reset_password','user',3,'[]','127.0.0.1','curl/8.5.0','2026-11-27 19:46:16'),
(10,NULL,4,'login','user',4,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:47:19'),
(11,NULL,4,'login','user',4,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:48:01'),
(12,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:48:04'),
(13,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:48:18'),
(14,NULL,4,'login','user',4,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:51:40'),
(15,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:51:42'),
(16,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:51:57'),
(17,NULL,4,'login','user',4,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:53:45'),
(18,NULL,4,'complete_profile','user',4,'[]','127.0.0.1','curl/8.5.0','2026-11-27 19:53:45'),
(19,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:53:45'),
(20,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 19:53:45'),
(21,NULL,2,'export_users','user',NULL,'{\"filtros\":{\"q\":\"\",\"status\":\"\",\"role\":\"\",\"provider\":\"\",\"de\":\"\",\"ate\":\"\",\"sort\":\"created\",\"dir\":\"desc\",\"page\":1}}','127.0.0.1','curl/8.5.0','2026-11-27 19:53:45'),
(22,NULL,4,'login','user',4,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:55:14'),
(23,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:55:17'),
(24,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:55:32'),
(25,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:56:22'),
(26,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:56:28');
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `auth_attempts` WRITE;
/*!40000 ALTER TABLE `auth_attempts` DISABLE KEYS */;
INSERT INTO `auth_attempts` VALUES
(1,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:45:07'),
(2,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:07'),
(3,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:07'),
(4,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:07'),
(5,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:07'),
(6,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:07'),
(7,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:07'),
(8,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:45:29'),
(9,'127.0.0.1','maria.teste@example.com','register',1,'2026-11-27 19:45:29'),
(10,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:29'),
(11,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:30'),
(12,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:30'),
(13,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:30'),
(14,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:30'),
(15,'127.0.0.1','bloqueio@example.com','login',0,'2026-11-27 19:45:30'),
(16,'127.0.0.1','maria.teste@example.com','login',1,'2026-11-27 19:45:50'),
(17,'127.0.0.1','maria.teste@example.com','login',0,'2026-11-27 19:46:16'),
(18,'127.0.0.1','lucas.oauth@example.com','login',1,'2026-11-27 19:47:19'),
(19,'127.0.0.1','admin@somase.com','login',0,'2026-11-27 19:47:22'),
(20,'127.0.0.1','admin@somase.com','login',0,'2026-11-27 19:47:44'),
(21,'127.0.0.1','lucas.oauth@example.com','login',1,'2026-11-27 19:48:01'),
(22,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:48:04'),
(23,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:48:18'),
(24,'127.0.0.1','lucas.oauth@example.com','login',1,'2026-11-27 19:51:40'),
(25,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:51:42'),
(26,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:51:57'),
(27,'127.0.0.1','lucas.oauth@example.com','login',1,'2026-11-27 19:53:45'),
(28,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:53:45'),
(29,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:53:45'),
(30,'127.0.0.1','lucas.oauth@example.com','login',1,'2026-11-27 19:55:14'),
(31,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:55:17'),
(32,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:55:32'),
(33,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:56:22'),
(34,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:56:28');
/*!40000 ALTER TABLE `auth_attempts` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES
(1,NULL,'Alimentação','expense','utensils','#ef4444',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,NULL,'Supermercado','expense','shopping-cart','#f97316',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(3,NULL,'Moradia','expense','home','#eab308',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(4,NULL,'Transporte','expense','car','#d97706',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(5,NULL,'Saúde','expense','heart','#ec4899',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(6,NULL,'Educação','expense','book','#8b5cf6',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(7,NULL,'Assinaturas','expense','repeat','#06b6d4',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(8,NULL,'Lazer','expense','smile','#14b8a6',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(9,NULL,'Impostos','expense','receipt','#64748b',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(10,NULL,'Outros','expense','tag','#64748b',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(11,NULL,'Salário','income','briefcase','#16a34a',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(12,NULL,'Vendas','income','shopping-bag','#22c55e',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(13,NULL,'Serviços','income','briefcase','#84cc16',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(14,NULL,'Comissões','income','percent','#10b981',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(15,NULL,'Rendimentos','income','trending-up','#0ea5e9',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(16,NULL,'Reembolso','income','rotate-ccw','#6366f1',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(17,NULL,'Outros','income','tag','#64748b',NULL,'active','2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `cnpj_cache` WRITE;
/*!40000 ALTER TABLE `cnpj_cache` DISABLE KEYS */;
/*!40000 ALTER TABLE `cnpj_cache` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `cnpj_rate_limit` WRITE;
/*!40000 ALTER TABLE `cnpj_rate_limit` DISABLE KEYS */;
/*!40000 ALTER TABLE `cnpj_rate_limit` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `cost_centers` WRITE;
/*!40000 ALTER TABLE `cost_centers` DISABLE KEYS */;
INSERT INTO `cost_centers` VALUES
(1,NULL,'Pessoal','PES','Despesas e receitas pessoais','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,NULL,'Casa','CAS','Moradia e manutenção','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(3,NULL,'Empresa','EMP','Operação do negócio','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(4,NULL,'Carro','CAR','Veículo e transporte','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(5,NULL,'Operacional','OPE','Custos operacionais gerais','active','2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `cost_centers` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `investment_movements` WRITE;
/*!40000 ALTER TABLE `investment_movements` DISABLE KEYS */;
/*!40000 ALTER TABLE `investment_movements` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `investment_returns` WRITE;
/*!40000 ALTER TABLE `investment_returns` DISABLE KEYS */;
INSERT INTO `investment_returns` VALUES
(1,1,11,2026,15000.00,127.50,0.850000,15127.50,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,2,11,2026,8000.00,68.00,0.850000,8068.00,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(3,1,10,2026,15000.00,133.50,0.890000,15133.50,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(4,2,10,2026,8000.00,71.20,0.890000,8071.20,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(5,1,9,2026,15000.00,139.50,0.930000,15139.50,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(6,2,9,2026,8000.00,74.40,0.930000,8074.40,'2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `investment_returns` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `investments` WRITE;
/*!40000 ALTER TABLE `investments` DISABLE KEYS */;
INSERT INTO `investments` VALUES
(1,1,1,'XP Investimentos','cdb','CDB Liquidez Diaria',15000.00,'2026-06-27',11.500000,'annual','cdi','diaria','2028-05-27','active','SOMASE demo','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,1,1,'Tesouro Direto','tesouro','Tesouro Selic 2029',8000.00,'2026-07-27',10.750000,'annual','selic','d1','2029-05-27','active','SOMASE demo','2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `investments` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `permissions` WRITE;
/*!40000 ALTER TABLE `permissions` DISABLE KEYS */;
INSERT INTO `permissions` VALUES
(1,'consultar_cnpj','Consultar CNPJ','Integrações','2026-11-27 16:31:16'),
(2,'view_dashboard','Ver dashboard','geral','2026-11-27 16:31:16'),
(3,'manage_users','Gerenciar usuarios','administracao','2026-11-27 16:31:16'),
(4,'manage_roles','Gerenciar roles','administracao','2026-11-27 16:31:16'),
(5,'access_admin_panel','Acessar painel administrativo','administracao','2026-11-27 19:35:57');
/*!40000 ALTER TABLE `permissions` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `recurring_transactions` WRITE;
/*!40000 ALTER TABLE `recurring_transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `recurring_transactions` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `role_permissions` WRITE;
/*!40000 ALTER TABLE `role_permissions` DISABLE KEYS */;
INSERT INTO `role_permissions` VALUES
(2,2),
(2,3),
(2,4),
(2,5),
(3,2);
/*!40000 ALTER TABLE `role_permissions` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES
(1,'superadmin','Super Administrador',1,'2026-11-27 16:31:16'),
(2,'admin','Administrador',0,'2026-11-27 16:31:16'),
(3,'user','Usuario',0,'2026-11-27 16:31:16');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `tenants` WRITE;
/*!40000 ALTER TABLE `tenants` DISABLE KEYS */;
/*!40000 ALTER TABLE `tenants` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES
(1,1,1,2,NULL,'expense','Supermercado do mes',720.00,'2026-11-08','2026-11-13','2026-11-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-11-05','2026-11-10',NULL,'pending','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(3,1,1,3,NULL,'expense','Energia eletrica',215.00,'2026-11-15','2026-11-20','2026-11-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(4,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-11-20','2026-11-25','2026-11-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(5,1,1,4,NULL,'expense','Combustivel',380.00,'2026-11-22','2026-11-27','2026-11-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(6,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-11-12','2026-11-17','2026-11-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(7,1,1,11,NULL,'income','Salario mensal',7800.00,'2026-11-05','2026-11-10','2026-11-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(8,1,1,13,NULL,'income','Projeto freelance',1350.00,'2026-11-18','2026-11-23','2026-11-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(9,1,1,2,NULL,'expense','Supermercado do mes',752.00,'2026-10-08','2026-10-13','2026-10-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(10,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-10-05','2026-10-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(11,1,1,3,NULL,'expense','Energia eletrica',227.00,'2026-10-15','2026-10-20','2026-10-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(12,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-10-20','2026-10-25','2026-10-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(13,1,1,4,NULL,'expense','Combustivel',406.00,'2026-10-22','2026-10-27','2026-10-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(14,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-10-12','2026-10-17','2026-10-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(15,1,1,11,NULL,'income','Salario mensal',7920.00,'2026-10-05','2026-10-10','2026-10-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(16,1,1,13,NULL,'income','Projeto freelance',1530.00,'2026-10-18','2026-10-23','2026-10-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(17,1,1,2,NULL,'expense','Supermercado do mes',784.00,'2026-09-08','2026-09-13','2026-09-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(18,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-09-05','2026-09-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(19,1,1,3,NULL,'expense','Energia eletrica',239.00,'2026-09-15','2026-09-20','2026-09-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(20,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-09-20','2026-09-25','2026-09-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(21,1,1,4,NULL,'expense','Combustivel',432.00,'2026-09-22','2026-09-27','2026-09-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(22,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-09-12','2026-09-17','2026-09-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(23,1,1,11,NULL,'income','Salario mensal',8040.00,'2026-09-05','2026-09-10','2026-09-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(24,1,1,13,NULL,'income','Projeto freelance',1710.00,'2026-09-18','2026-09-23','2026-09-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(25,1,1,2,NULL,'expense','Supermercado do mes',816.00,'2026-08-08','2026-08-13','2026-08-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(26,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-08-05','2026-08-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(27,1,1,3,NULL,'expense','Energia eletrica',251.00,'2026-08-15','2026-08-20','2026-08-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(28,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-08-20','2026-08-25','2026-08-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(29,1,1,4,NULL,'expense','Combustivel',458.00,'2026-08-22','2026-08-27','2026-08-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(30,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-08-12','2026-08-17','2026-08-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(31,1,1,11,NULL,'income','Salario mensal',8160.00,'2026-08-05','2026-08-10','2026-08-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(32,1,1,13,NULL,'income','Projeto freelance',1890.00,'2026-08-18','2026-08-23','2026-08-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(33,1,1,2,NULL,'expense','Supermercado do mes',848.00,'2026-07-08','2026-07-13','2026-07-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(34,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-07-05','2026-07-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(35,1,1,3,NULL,'expense','Energia eletrica',263.00,'2026-07-15','2026-07-20','2026-07-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(36,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-07-20','2026-07-25','2026-07-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(37,1,1,4,NULL,'expense','Combustivel',484.00,'2026-07-22','2026-07-27','2026-07-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(38,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-07-12','2026-07-17','2026-07-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(39,1,1,11,NULL,'income','Salario mensal',8280.00,'2026-07-05','2026-07-10','2026-07-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(40,1,1,13,NULL,'income','Projeto freelance',2070.00,'2026-07-18','2026-07-23','2026-07-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(41,1,1,2,NULL,'expense','Supermercado do mes',880.00,'2026-06-08','2026-06-13','2026-06-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(42,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-06-05','2026-06-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(43,1,1,3,NULL,'expense','Energia eletrica',275.00,'2026-06-15','2026-06-20','2026-06-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(44,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-06-20','2026-06-25','2026-06-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(45,1,1,4,NULL,'expense','Combustivel',510.00,'2026-06-22','2026-06-27','2026-06-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(46,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-06-12','2026-06-17','2026-06-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(47,1,1,11,NULL,'income','Salario mensal',8400.00,'2026-06-05','2026-06-10','2026-06-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(48,1,1,13,NULL,'income','Projeto freelance',2250.00,'2026-06-18','2026-06-23','2026-06-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(49,1,1,2,NULL,'expense','Supermercado do mes',912.00,'2026-05-08','2026-05-13','2026-05-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(50,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-05-05','2026-05-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(51,1,1,3,NULL,'expense','Energia eletrica',287.00,'2026-05-15','2026-05-20','2026-05-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(52,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-05-20','2026-05-25','2026-05-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(53,1,1,4,NULL,'expense','Combustivel',536.00,'2026-05-22','2026-05-27','2026-05-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(54,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-05-12','2026-05-17','2026-05-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(55,1,1,11,NULL,'income','Salario mensal',8520.00,'2026-05-05','2026-05-10','2026-05-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(56,1,1,13,NULL,'income','Projeto freelance',2430.00,'2026-05-18','2026-05-23','2026-05-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(57,1,1,2,NULL,'expense','Supermercado do mes',944.00,'2026-04-08','2026-04-13','2026-04-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(58,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-04-05','2026-04-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(59,1,1,3,NULL,'expense','Energia eletrica',299.00,'2026-04-15','2026-04-20','2026-04-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(60,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-04-20','2026-04-25','2026-04-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(61,1,1,4,NULL,'expense','Combustivel',562.00,'2026-04-22','2026-04-27','2026-04-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(62,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-04-12','2026-04-17','2026-04-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(63,1,1,11,NULL,'income','Salario mensal',8640.00,'2026-04-05','2026-04-10','2026-04-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(64,1,1,13,NULL,'income','Projeto freelance',2610.00,'2026-04-18','2026-04-23','2026-04-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(65,1,1,2,NULL,'expense','Supermercado do mes',976.00,'2026-03-08','2026-03-13','2026-03-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(66,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-03-05','2026-03-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(67,1,1,3,NULL,'expense','Energia eletrica',311.00,'2026-03-15','2026-03-20','2026-03-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(68,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-03-20','2026-03-25','2026-03-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(69,1,1,4,NULL,'expense','Combustivel',588.00,'2026-03-22','2026-03-27','2026-03-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(70,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-03-12','2026-03-17','2026-03-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(71,1,1,11,NULL,'income','Salario mensal',8760.00,'2026-03-05','2026-03-10','2026-03-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(72,1,1,13,NULL,'income','Projeto freelance',2790.00,'2026-03-18','2026-03-23','2026-03-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(73,1,1,2,NULL,'expense','Supermercado do mes',1008.00,'2026-02-08','2026-02-13','2026-02-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(74,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-02-05','2026-02-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(75,1,1,3,NULL,'expense','Energia eletrica',323.00,'2026-02-15','2026-02-20','2026-02-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(76,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-02-20','2026-02-25','2026-02-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(77,1,1,4,NULL,'expense','Combustivel',614.00,'2026-02-22','2026-02-27','2026-02-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(78,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-02-12','2026-02-17','2026-02-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(79,1,1,11,NULL,'income','Salario mensal',8880.00,'2026-02-05','2026-02-10','2026-02-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(80,1,1,13,NULL,'income','Projeto freelance',2970.00,'2026-02-18','2026-02-23','2026-02-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(81,1,1,2,NULL,'expense','Supermercado do mes',1040.00,'2026-01-08','2026-01-13','2026-01-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(82,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-01-05','2026-01-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(83,1,1,3,NULL,'expense','Energia eletrica',335.00,'2026-01-15','2026-01-20','2026-01-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(84,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-01-20','2026-01-25','2026-01-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(85,1,1,4,NULL,'expense','Combustivel',640.00,'2026-01-22','2026-01-27','2026-01-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(86,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-01-12','2026-01-17','2026-01-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(87,1,1,11,NULL,'income','Salario mensal',9000.00,'2026-01-05','2026-01-10','2026-01-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(88,1,1,13,NULL,'income','Projeto freelance',3150.00,'2026-01-18','2026-01-23','2026-01-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(89,1,1,2,NULL,'expense','Supermercado do mes',1072.00,'2025-12-08','2025-12-13','2025-12-08','paid','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(90,1,1,3,NULL,'expense','Aluguel',2400.00,'2025-12-05','2025-12-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(91,1,1,3,NULL,'expense','Energia eletrica',347.00,'2025-12-15','2025-12-20','2025-12-15','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(92,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2025-12-20','2025-12-25','2025-12-20','paid','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(93,1,1,4,NULL,'expense','Combustivel',666.00,'2025-12-22','2025-12-27','2025-12-22','paid','debit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(94,1,1,5,NULL,'expense','Plano de saude',640.00,'2025-12-12','2025-12-17','2025-12-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(95,1,1,11,NULL,'income','Salario mensal',9120.00,'2025-12-05','2025-12-10','2025-12-05','received','transfer','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(96,1,1,13,NULL,'income','Projeto freelance',3330.00,'2025-12-18','2025-12-23','2025-12-18','received','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(128,1,1,3,NULL,'expense','Aluguel do proximo mes',2400.00,'2026-11-27','2026-12-03',NULL,'pending','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(129,1,1,10,NULL,'expense','Fatura do cartao',1380.45,'2026-11-27','2026-12-09',NULL,'pending','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(130,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-11-27','2026-12-15',NULL,'pending','boleto','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(131,1,1,13,NULL,'income','Projeto freelance (2a parcela)',1350.00,'2026-11-27','2026-12-18',NULL,'expected','pix','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(132,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-11-27','2026-12-22',NULL,'pending','credit','SOMASE demo',NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16');
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `user_identities` WRITE;
/*!40000 ALTER TABLE `user_identities` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_identities` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `user_tenants` WRITE;
/*!40000 ALTER TABLE `user_tenants` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_tenants` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'Administrador','admin@example.com','$2b$10$vWAdPPDyhPW0u/UeSpdf1eLsXidEiwemycK/I9x7I1DcVjCLSTJii',1,'active',NULL,'local',NULL,NULL,NULL,NULL,'2026-11-27 16:40:05','2026-11-27 16:31:16','2026-11-27 16:40:05'),
(2,'Administrador SOMASE','admin@somase.com','$2y$10$CLh5deExaEM80yzUleFVs.HBUfoLoeXRKr3TU4ACciq6a92wFoj/C',1,'active','1985-03-12','local',NULL,'2026-11-27 19:36:04','2026-11-27 19:47:49',NULL,'2026-11-27 19:56:28','2026-11-27 19:36:04','2026-11-27 19:56:28'),
(3,'Maria Oliveira Souza','maria.teste@example.com','$2y$10$XfOy0Vu5/hp6noKYQRtnJ.A/o21Jl4j8XRsOoYlIgrjgnTZW5Wy4S',3,'active','1992-07-15','local',NULL,NULL,'2026-11-27 19:45:29','127.0.0.1','2026-11-27 19:45:50','2026-11-27 19:45:29','2026-11-27 19:46:16'),
(4,'Lucas Ferreira','lucas.oauth@example.com','$2y$10$UU7wwHE6Lk7YpQuTmk2nLeIv/Srqc.1G/G34.KIzinlCmBYRq7uWS',3,'active','1995-04-02','google',NULL,'2026-11-27 19:46:59','2026-11-27 19:53:45',NULL,'2026-11-27 19:55:14','2026-11-27 19:46:59','2026-11-27 19:55:14');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;

SELECT (SELECT COUNT(*) FROM `users`) AS usuarios,
       (SELECT COUNT(*) FROM `transactions`) AS lancamentos,
       (SELECT COUNT(*) FROM `accounts`) AS contas;
