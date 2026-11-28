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
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `account_movements` WRITE;
/*!40000 ALTER TABLE `account_movements` DISABLE KEYS */;
INSERT INTO `account_movements` VALUES
(37,18,183,NULL,'transaction',-195.79,-195.79,'2026-11-05','2026-11-28 00:46:53'),
(38,18,184,NULL,'transaction',2500.00,2304.21,'2026-11-10','2026-11-28 00:46:53'),
(39,18,185,NULL,'transaction',-10.50,2293.71,'2026-11-27','2026-11-28 00:48:03'),
(40,18,186,NULL,'transaction',-10.50,2283.21,'2026-11-27','2026-11-28 00:48:37'),
(53,1,203,NULL,'transaction',-123.45,55117.75,'2026-11-28','2026-11-28 11:26:37'),
(54,1,NULL,NULL,'investment',-10000.00,45117.75,'2026-11-28','2026-11-28 11:27:07');
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
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
INSERT INTO `accounts` VALUES
(1,1,'Conta Corrente','Banco do Brasil',NULL,'checking',NULL,NULL,'annual','1234','56789-0',4200.00,45117.75,'2026-04-01','active','SOMASE demo','2026-11-27 16:31:16','2026-11-28 11:27:07'),
(2,1,'Reserva de emergencia','Nubank',NULL,'savings',NULL,NULL,'annual',NULL,'0001',12000.00,12000.00,'2026-04-01','active','SOMASE demo','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(18,2,'Conta Teste Import','Banco do Brasil',NULL,'checking',NULL,NULL,'annual',NULL,NULL,1000.00,2283.21,'2026-11-28','active',NULL,'2026-11-28 00:46:40','2026-11-28 00:48:37'),
(23,1,'Conta Investimento Teste',NULL,NULL,'investment',15,110.000000,'annual',NULL,NULL,0.00,0.00,'2026-11-28','active',NULL,'2026-11-28 11:27:20','2026-11-28 11:27:20');
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
) ENGINE=InnoDB AUTO_INCREMENT=81 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
(26,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 19:56:28'),
(27,NULL,NULL,'register','user',5,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 21:44:47'),
(28,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 21:48:00'),
(29,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 23:14:31'),
(30,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-27 23:50:55'),
(31,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:51:50'),
(32,NULL,1,'create','account',11,'{\"account_type\":\"checking\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:51:52'),
(33,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:51:54'),
(34,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:52:31'),
(35,NULL,1,'create','account',12,'{\"account_type\":\"checking\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:52:34'),
(36,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:53:34'),
(37,NULL,1,'create','account',15,'{\"account_type\":\"checking\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:53:35'),
(38,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-27 23:53:44'),
(39,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:43:27'),
(40,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:45:00'),
(41,NULL,2,'create','cost_center',6,'[]','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:45:02'),
(42,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:45:43'),
(43,NULL,2,'create','cost_center',7,'[]','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:45:44'),
(44,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:46:49'),
(45,NULL,2,'import_preview','transaction',NULL,'{\"account_id\":18,\"arquivo\":\"extrato-teste.csv\",\"linhas\":2}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:46:53'),
(46,NULL,2,'import','transaction',NULL,'{\"account_id\":18,\"importados\":2,\"ignorados\":0,\"erros\":0}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:46:53'),
(47,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:46:54'),
(48,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:48:02'),
(49,NULL,2,'create','transaction',185,'{\"type\":\"expense\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:48:03'),
(50,NULL,2,'import_preview','transaction',NULL,'{\"account_id\":18,\"arquivo\":\"extrato-teste.csv\",\"linhas\":2}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:48:04'),
(51,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:48:36'),
(52,NULL,2,'create','transaction',186,'{\"type\":\"expense\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:48:37'),
(53,NULL,2,'import_preview','transaction',NULL,'{\"account_id\":18,\"arquivo\":\"extrato-teste.csv\",\"linhas\":2}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:48:38'),
(54,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:53:21'),
(55,NULL,2,'import_preview','transaction',NULL,'{\"account_id\":18,\"arquivo\":\"extrato-teste.ofx\",\"linhas\":2}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 00:53:22'),
(56,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-28 00:54:31'),
(57,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-28 11:25:12'),
(58,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-28 11:26:37'),
(59,NULL,1,'create','transaction',203,'{\"type\":\"expense\"}','127.0.0.1','curl/8.5.0','2026-11-28 11:26:37'),
(60,NULL,1,'create','cost_center',8,'{\"kind\":\"property\"}','127.0.0.1','curl/8.5.0','2026-11-28 11:26:53'),
(61,NULL,1,'create','payment_method',10,'[]','127.0.0.1','curl/8.5.0','2026-11-28 11:27:01'),
(62,NULL,1,'create','investment_type',15,'[]','127.0.0.1','curl/8.5.0','2026-11-28 11:27:01'),
(63,NULL,1,'create','investment',11,'[]','127.0.0.1','curl/8.5.0','2026-11-28 11:27:07'),
(64,NULL,1,'create','investment_return',11,'{\"month\":\"11\",\"year\":\"2026\"}','127.0.0.1','curl/8.5.0','2026-11-28 11:27:14'),
(65,NULL,1,'create','account',23,'{\"account_type\":\"investment\"}','127.0.0.1','curl/8.5.0','2026-11-28 11:27:20'),
(66,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:27:48'),
(67,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:27:58'),
(68,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:28:27'),
(69,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:28:46'),
(70,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:29:00'),
(71,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:29:13'),
(72,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:29:22'),
(73,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:29:34'),
(74,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:29:43'),
(75,NULL,1,'login','user',1,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:32:01'),
(76,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 11:32:43'),
(77,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-28 11:33:13'),
(78,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','curl/8.5.0','2026-11-28 15:34:57'),
(79,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 15:38:12'),
(80,NULL,2,'login','user',2,'{\"provider\":\"local\"}','127.0.0.1','Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/156.0.0.0 Safari/537.36','2026-11-28 15:40:00');
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
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
(34,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 19:56:28'),
(35,'127.0.0.1','teste.senha.1795815885@example.com','register',1,'2026-11-27 21:44:47'),
(36,'127.0.0.1','admin@somase.com','login',1,'2026-11-27 21:48:00'),
(37,'127.0.0.1','naoexiste@example.com','login',0,'2026-11-27 23:10:53'),
(38,'127.0.0.1','admin@example.com','login',1,'2026-11-27 23:14:31'),
(39,'127.0.0.1','admin@example.com','login',1,'2026-11-27 23:50:55'),
(40,'127.0.0.1','admin@example.com','login',1,'2026-11-27 23:51:50'),
(41,'127.0.0.1','admin@example.com','login',1,'2026-11-27 23:51:54'),
(42,'127.0.0.1','admin@example.com','login',1,'2026-11-27 23:52:31'),
(43,'127.0.0.1','admin@example.com','login',1,'2026-11-27 23:53:34'),
(44,'127.0.0.1','admin@example.com','login',1,'2026-11-27 23:53:44'),
(45,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:43:27'),
(46,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:45:00'),
(47,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:45:43'),
(48,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:46:49'),
(49,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:46:54'),
(50,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:48:02'),
(51,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:48:36'),
(52,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 00:53:21'),
(53,'127.0.0.1','admin@example.com','login',1,'2026-11-28 00:54:31'),
(54,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:25:12'),
(55,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:26:37'),
(56,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:27:48'),
(57,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:27:58'),
(58,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:28:27'),
(59,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:28:46'),
(60,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:29:00'),
(61,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:29:13'),
(62,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:29:22'),
(63,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:29:34'),
(64,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:29:43'),
(65,'127.0.0.1','admin@example.com','login',1,'2026-11-28 11:32:01'),
(66,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 11:32:43'),
(67,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 11:33:13'),
(68,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 15:34:57'),
(69,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 15:38:12'),
(70,'127.0.0.1','admin@somase.com','login',1,'2026-11-28 15:40:00');
/*!40000 ALTER TABLE `auth_attempts` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `banks` WRITE;
/*!40000 ALTER TABLE `banks` DISABLE KEYS */;
INSERT INTO `banks` VALUES
(1,'000','28719664','Câmbio B3','Câmara de Câmbio B3',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(2,'001','00000000','BCO DO BRASIL S.A.','Banco do Brasil S.A.','Banco do Brasil | BB','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00000000.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(3,'003','04902979','BCO DA AMAZONIA S.A.','BANCO DA AMAZONIA S.A.','Banco da Amazônia | BASA','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04902979.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(4,'004','07237373','BCO DO NORDESTE DO BRASIL S.A.','Banco do Nordeste do Brasil S.A.','Banco do Nordeste | BNB','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/07237373.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(5,'007','33657248','BNDES','BANCO NACIONAL DE DESENVOLVIMENTO ECONOMICO E SOCIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(6,'009','00394460','STN','Secretaria do Tesouro Nacional - STN',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(7,'010','81723108','CREDICOAMO','CREDICOAMO CREDITO RURAL COOPERATIVA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(8,'011','61809182','UBS (BRASIL) CORRETORA DE VALORES S.A.','UBS (BRASIL) CORRETORA DE VALORES S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/61809182.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(9,'012','04866275','BANCO INBURSA','Banco Inbursa S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(10,'014','09274232','STATE STREET BR S.A. BCO COMERCIAL','STATE STREET BRASIL S.A. - BANCO COMERCIAL',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/09274232.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(11,'015','02819125','UBS BB CCTVM S.A.','UBS BB CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/02819125.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(12,'016','04715685','CCM DESP TRÂNS SC E RS','COOPERATIVA DE CRÉDITO MÚTUO DOS DESPACHANTES DE TRÂNSITO DE SANTA CATARINA E RIO GRANDE DO SUL - SICOOB CREDITRAN',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04891850.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(13,'017','42272526','BNY MELLON BCO S.A.','BNY Mellon Banco S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/42272526.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(14,'018','57839805','BCO TRICURY S.A.','Banco Tricury S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(15,'021','28127603','BCO BANESTES S.A.','BANESTES S.A. BANCO DO ESTADO DO ESPIRITO SANTO','Banestes','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/28127603.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(16,'023','53720128','CONTA SIMPLES SCD S.A.','CONTA SIMPLES SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(17,'024','10866788','BCO BANDEPE S.A.','Banco Bandepe S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(18,'025','03323840','BCO ALFA S.A.','Banco Alfa S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(19,'033','90400888','BCO SANTANDER (BRASIL) S.A.','BANCO SANTANDER (BRASIL) S.A.','Santander','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/90400888.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(20,'036','06271464','BCO BBI S.A.','Banco Bradesco BBI S.A.','Bradesco BBI','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/06271464.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(21,'037','04913711','BCO DO EST. DO PA S.A.','Banco do Estado do Pará S.A.','Banpará','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04913711.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(22,'040','03609817','BCO CARGILL S.A.','Banco Cargill S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/03609817.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(23,'041','92702067','BCO DO ESTADO DO RS S.A.','Banco do Estado do Rio Grande do Sul S.A.','Banrisul','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/92702067.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(24,'047','13009717','BCO DO EST. DE SE S.A.','Banco do Estado de Sergipe S.A.','Banese','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13009717.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(25,'060','04913129','CONFIDENCE CC S.A.','CONFIDENCE SOCIEDADE CORRETORA DE CAMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(26,'063','04184779','BANCO BRADESCARD','Banco Bradescard S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/04184779.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(27,'064','04332281','GOLDMAN SACHS DO BRASIL BM S.A','GOLDMAN SACHS DO BRASIL BANCO MULTIPLO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/04332281.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(28,'065','48795256','BCO ANDBANK S.A.','Banco AndBank (Brasil) S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(29,'066','02801938','BCO MORGAN STANLEY S.A.','BANCO MORGAN STANLEY S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/02801938.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(30,'069','61033106','BCO CREFISA S.A.','Banco Crefisa S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61033106.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(31,'070','00000208','BRB - BCO DE BRASILIA S.A.','BRB - BANCO DE BRASILIA S.A.','BRB | Banco de Brasília','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00000208.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(32,'074','03017677','BCO. J.SAFRA S.A.','Banco J. Safra S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/03017677.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(33,'075','03532415','BANCO ABN AMRO CLEARING S.A.','BANCO ABN AMRO CLEARING S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(34,'076','07656500','BCO KDB BRASIL S.A.','Banco KDB do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(35,'077','00416968','BANCO INTER','Banco Inter S.A.','Inter | Banco Inter | Intermedium','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00416968.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(36,'078','34111187','HAITONG BI DO BRASIL S.A.','Haitong Banco de Investimento do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(37,'079','09516419','PICPAY BANK - BANCO MÚLTIPLO S.A','PICPAY BANK - BANCO MÚLTIPLO S.A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/09516419.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(38,'080','73622748','BT CC LTDA.','BT CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(39,'081','10264663','BANCOSEGURO S.A.','BancoSeguro S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(40,'082','07679404','BANCO TOPÁZIO S.A.','BANCO TOPÁZIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(41,'083','10690848','BCO DA CHINA BRASIL S.A.','Banco da China Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(42,'084','02398976','SISPRIME DO BRASIL - COOP','SISPRIME DO BRASIL - COOPERATIVA DE CRÉDITO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02398976.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(43,'085','05463212','COOPCENTRAL AILOS','Cooperativa Central de Crédito - Ailos','Ailos | Cecred','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/05463212.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(44,'089','62109566','CREDISAN CC','CREDISAN COOPERATIVA DE CRÉDITO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(45,'093','07945233','POLOCRED SCMEPP LTDA.','PÓLOCRED   SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(46,'094','11758741','BANCO FINAXIS','Banco Finaxis S.A.','Finaxis',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(47,'095','11703662','BANCO TRAVELEX S.A.','BANCO TRAVELEX S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(48,'096','00997185','BCO B3 S.A.','Banco B3 S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(49,'097','04632856','CREDISIS - CENTRAL DE COOPERATIVAS DE CRÉDITO','CREDISIS - CENTRAL DE COOPERATIVAS DE CRÉDITO','Credisis',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(50,'099','03046391','UNIPRIME COOPCENTRAL LTDA.','UNIPRIME CENTRAL NACIONAL - CENTRAL NACIONAL DE COOPERATIVA DE CREDITO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(51,'100','00806535','PLANNER CV S.A.','Planner Corretora de Valores S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/00806535.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(52,'101','62287735','WARREN RENA DTVM','WARREN RENA DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/62287735.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(53,'102','02332886','XP INVESTIMENTOS CCTVM S/A','XP INVESTIMENTOS CORRETORA DE CÂMBIO,TÍTULOS E VALORES MOBILIÁRIOS S/A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02332886.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(54,'104','00360305','CAIXA ECONOMICA FEDERAL','CAIXA ECONOMICA FEDERAL','Caixa | Caixa Econômica Federal | CEF | Caixa Econômica','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00360305.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(55,'105','07652226','LECCA CFI S.A.','Lecca Crédito, Financiamento e Investimento S/A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/07652226.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(56,'107','15114366','BCO BOCOM BBM S.A.','Banco Bocom BBM S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(57,'111','36113876','OLIVEIRA TRUST DTVM S.A.','OLIVEIRA TRUST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIARIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/36113876.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(58,'113','61723847','NEON CTVM S.A.','NEON CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61723847.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(59,'119','13720915','BCO WESTERN UNION','Banco Western Union do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(60,'120','33603457','BCO RODOBENS S.A.','BANCO RODOBENS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/33603457.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(61,'121','10664513','BCO AGIBANK S.A.','Banco Agibank S.A.','Agibank | Agi','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10664513.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(62,'122','33147315','BCO BRADESCO BERJ S.A.','Banco Bradesco BERJ S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33147315.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(63,'124','15357060','BCO WOORI BANK DO BRASIL S.A.','Banco Woori Bank do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(64,'125','45246410','BANCO GENIAL','BANCO GENIAL S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/45246410.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(65,'126','13220493','BR PARTNERS BI','BR Partners Banco de Investimento S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(66,'127','09512542','CODEPE CVC S.A.','Codepe Corretora de Valores e Câmbio S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(67,'128','19307785','BRAZA BANK S.A. BCO DE CÂMBIO','BRAZA BANK S.A. BANCO DE CÂMBIO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(68,'129','18520834','UBS BB BI S.A.','UBS BB BANCO DE INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/18520834.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(69,'130','09313766','CARUANA SCFI','CARUANA S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(70,'131','61747085','TULLETT PREBON BRASIL CVC LTDA','TULLETT PREBON BRASIL CORRETORA DE VALORES E CÂMBIO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(71,'132','17453575','ICBC DO BRASIL BM S.A.','ICBC do Brasil Banco Múltiplo S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(72,'133','10398952','CRESOL CONFEDERAÇÃO','CONFEDERAÇÃO NACIONAL DAS COOPERATIVAS CENTRAIS DE CRÉDITO E ECONOMIA FAMILIAR E SOLIDÁRIA - CRESOL CONFEDERAÇÃO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10398952.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(73,'134','33862244','BGC LIQUIDEZ DTVM LTDA','BGC LIQUIDEZ DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(74,'136','00315557','UNICRED DO BRASIL','COOPERATIVA CENTRAL DE CRÉDITO UNICRED DO BRASIL - UNICRED DO BRASIL','Unicred','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00315557.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(75,'138','10853017','GET MONEY CC LTDA.','GET MONEY SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(76,'139','55230916','INTESA SANPAOLO BRASIL S.A. BM','Intesa Sanpaolo Brasil S.A. - Banco Múltiplo',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(77,'140','62169875','NU INVESTIMENTOS S.A. - CTVM','NU INVESTIMENTOS S.A. - CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62169875.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(78,'141','09526594','MASTER BI S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO MASTER DE INVESTIMENTO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(79,'142','16944141','BROKER BRASIL CC LTDA.','Broker Brasil Corretora de Câmbio Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(80,'143','02992317','INTEX BANK BCO DE CÂMBIO S.A.','INTEX BANK BANCO DE CÂMBIO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/02992317.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(81,'144','13059145','EBURY BCO DE CÂMBIO S.A.','EBURY BANCO DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(82,'145','50579044','LEVYCAM CCV LTDA','LEVYCAM - CORRETORA DE CAMBIO E VALORES LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(83,'146','24074692','GUITTA CC LTDA','GUITTA CORRETORA DE CAMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(84,'149','15581638','FACTA S.A. CFI','Facta Financeira S.A. - Crédito Financiamento e Investimento',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(85,'157','09105360','ICAP DO BRASIL CTVM LTDA.','ICAP do Brasil Corretora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(86,'159','05442029','CASA CREDITO S.A. SCM','Casa do Crédito S.A. Sociedade de Crédito ao Microempreendedor',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(87,'173','13486793','APEX GROUP DTVM','APEX GROUP DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(88,'174','43180355','PEFISA S.A. - C.F.I.','PEFISA S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/43180355.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(89,'180','02685483','CM CAPITAL MARKETS CCTVM LTDA','CM CAPITAL MARKETS CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(90,'183','09210106','SOCRED SA - SCMEPP','SOCRED S.A. - SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(91,'188','33775974','ATIVA S.A. INVESTIMENTOS CCTVM','ATIVA INVESTIMENTOS S.A. CORRETORA DE TÍTULOS, CÂMBIO E VALORES',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(92,'190','03973814','SERVICOOP','SERVICOOP - COOPERATIVA DE CRÉDITO DOS SERVIDORES PÚBLICOS ESTADUAIS E MUNICIPAIS DO RIO GRANDE DO SUL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(93,'191','04257795','NOVA FUTURA CTVM LTDA.','Nova Futura Corretora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(94,'194','20155248','UNIDA DTVM LTDA','UNIDA DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(95,'195','07799277','VALOR S/A SCFI','VALOR S/A SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(96,'196','32648370','FAIR SOCIEDADE CC','FAIR SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(97,'197','16501555','STONE IP S.A.','STONE INSTITUIÇÃO DE PAGAMENTO S.A.','Stone | Stone Pagamentos','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/16501555.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(98,'208','30306294','BANCO BTG PACTUAL S.A.','Banco BTG Pactual S.A.','BTG | BTG Pactual','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/30306294.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(101,'212','92894922','BANCO ORIGINAL','Banco Original S.A.','Original | Banco Original',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(102,'213','54403563','BCO ARBI S.A.','Banco Arbi S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/54403563.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(103,'217','91884981','BANCO JOHN DEERE S.A.','Banco John Deere S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(104,'218','71027866','BCO BS2 S.A.','Banco BS2 S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/71027866.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(105,'222','75647891','BCO CRÉDIT AGRICOLE BR S.A.','BANCO CRÉDIT AGRICOLE BRASIL S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(106,'224','58616418','BCO FIBRA S.A.','Banco Fibra S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/58616418.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(107,'233','62421979','BANCO BMG SOLUÇÕES FINANCEIRAS S.A.','BANCO BMG SOLUÇÕES FINANCEIRAS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62421979.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(108,'237','60746948','BCO BRADESCO S.A.','Banco Bradesco S.A.','Bradesco | Next | Next Bank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60746948.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(109,'241','31597552','BCO CLASSICO S.A.','BANCO CLASSICO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(110,'243','33923798','BANCO MASTER - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO MASTER S/A - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(111,'246','28195667','BCO ABC BRASIL S.A.','Banco ABC Brasil S.A.','ABC Brasil','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/28195667.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(112,'249','61182408','BANCO INVESTCRED UNIBANCO S.A.','Banco Investcred Unibanco S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(113,'250','50585090','BANCO BMG CONSIGNADO S.A.','BANCO BMG CONSIGNADO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/50585090.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(114,'254','14388334','PARANA BCO S.A.','PARANÁ BANCO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/14388334.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(115,'259','08609934','MONEYCORP BCO DE CÂMBIO S.A.','MONEYCORP BANCO DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(116,'260','18236120','NU PAGAMENTOS - IP','NU PAGAMENTOS S.A. - INSTITUIÇÃO DE PAGAMENTO','Nubank | Nu | Nu Pagamentos | NuBank | Nubank PJ','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18236120.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(117,'265','33644196','BCO FATOR S.A.','Banco Fator S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/33644196.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(118,'266','33132044','BCO CEDULA S.A.','BANCO CEDULA S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(119,'268','14511781','BARI CIA HIPOTECÁRIA','BARI COMPANHIA HIPOTECÁRIA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/14511781.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(120,'269','53518684','BCO HSBC S.A.','BANCO HSBC S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(121,'271','27842177','BPY CCTVM S.A.','BPY CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(122,'272','00250699','AGK CC S.A.','AGK CORRETORA DE CAMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(123,'273','08253539','COOP SULCREDI AMPLEA','COOPERATIVA DE CREDITO SULCREDI AMPLEA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(124,'274','11581339','BMP SCMEPP LTDA','BMP SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E A EMPRESA DE PEQUENO PORTE LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/11581339.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(125,'276','11970623','BCO SENFF S.A.','BANCO SENFF S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(126,'280','23862762','WILL FINANCEIRA S.A.CFI - EM LIQUIDAÇÃO EXTRAJUDICIAL','WILL FINANCEIRA S.A. CRÉDITO, FINANCIAMENTO E INVESTIMENTO - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(127,'281','76461557','CCR COOPAVEL','Cooperativa de Crédito Rural Coopavel',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(128,'283','89960090','RB INVESTIMENTOS DTVM LTDA.','RB INVESTIMENTOS DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LIMITADA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(129,'288','62237649','CAROL DTVM LTDA.','CAROL DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(130,'289','94968518','EFX CC LTDA.','EFX CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(131,'290','08561701','PAGSEGURO INTERNET IP S.A.','PAGSEGURO INTERNET INSTITUIÇÃO DE PAGAMENTO S.A.','PagBank | PagSeguro','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/08561701.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(132,'292','28650236','GALAPAGOS DTVM S.A.','GALAPAGOS CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/28650236.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(133,'293','71590442','LASTRO RDV DTVM LTDA','Lastro RDV Distribuidora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(134,'296','04062902','OZ CÂMBIO','OZ SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(135,'298','17772370','VIPS CC S.A.','VIPS CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(136,'299','04814563','BCO AFINZ S.A. - BM','BANCO AFINZ S.A. - BANCO MÚLTIPLO','Afinz',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(137,'300','33042151','BCO LA NACION ARGENTINA','Banco de la Nacion Argentina',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33042151.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(138,'301','13370835','DOCK IP S.A.','DOCK INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13370835.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(139,'305','40353377','FOURTRADE COR. DE CAMBIO LTDA','FOURTRADE CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(140,'307','03751794','TERRA INVESTIMENTOS DTVM','Terra Investimentos Distribuidora de Títulos e Valores Mobiliários Ltda.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(141,'310','22610500','VORTX DTVM LTDA.','VORTX DISTRIBUIDORA DE TITULOS E VALORES MOBILIARIOS LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/22610500.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(142,'312','07693858','HSCM SCMEPP LTDA.','HSCM - SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(143,'318','61186680','BCO BMG S.A.','Banco BMG S.A.','BMG','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61186680.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(144,'319','11495073','OM DTVM LTDA','OM DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(145,'320','07450604','BOC BRASIL','BANK OF CHINA (BRASIL) BANCO MÚLTIPLO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(146,'321','18188384','CREFAZ SCMEPP SA','CREFAZ SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E A EMPRESA DE PEQUENO PORTE S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(147,'322','01073966','CCR DE ABELARDO LUZ','Cooperativa de Crédito Rural de Abelardo Luz - Sulcredi/Crediluz',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(148,'323','10573521','MERCADO PAGO IP LTDA.','MERCADO PAGO INSTITUIÇÃO DE PAGAMENTO LTDA.','Mercado Pago | Mercado Livre','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10573521.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(149,'324','21332862','CARTOS SCD S.A.','CARTOS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(150,'326','03311443','MEUTUDO SCFI','MEUTUDO S.A - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/03311443.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(151,'329','32402502','QI SCD S.A.','QI Sociedade de Crédito Direto S.A.','QI | Qi Tech','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/32402502.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(152,'330','00556603','BANCO BARI S.A.','BANCO BARI DE INVESTIMENTOS E FINANCIAMENTOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/00556603.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(153,'331','13673855','OSLO CAPITAL DTVM SA','OSLO CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(154,'332','13140088','ACESSO SOLUÇÕES DE PAGAMENTO S.A. - INSTITUIÇÃO DE PAGAMENTO','ACESSO SOLUÇÕES DE PAGAMENTO S.A. - INSTITUIÇÃO DE PAGAMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13140088.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(155,'334','15124464','BANCO BESA S.A.','BANCO BESA S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(156,'335','27098060','BANCO DIGIO','Banco Digio S.A.','Digio','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/27098060.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(157,'336','31872495','BCO C6 S.A.','Banco C6 S.A.','C6 | C6 Bank | C6 Pay','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/31872495.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(158,'341','60701190','ITAÚ UNIBANCO S.A.','ITAÚ UNIBANCO S.A.','Itaú Unibanco | Itaú | Itau','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60701190.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(159,'342','32997490','CREDITAS SCD','Creditas Sociedade de Crédito Direto S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(160,'348','33264668','BCO XP S.A.','Banco XP S.A.','XP | XP Investimentos','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33264668.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(161,'349','27214112','AL5 S.A. SCFI','AL5 S.A. SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(162,'350','01330387','COOPERATIVA DE CRÉDITO POPULAR DO BRASIL','COOPERATIVA DE CRÉDITO POPULAR DO BRASIL - CREHNOR',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(163,'352','29162769','SANTANDER CTVM S.A.','SANTANDER CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/29162769.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(164,'355','34335592','ÓTIMO SCD S.A.','ÓTIMO SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(165,'358','09464032','MIDWAY S.A. - SCFI','MIDWAY S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/09464032.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(166,'359','05351887','ZEMA CFI S/A','ZEMA CRÉDITO, FINANCIAMENTO E INVESTIMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(167,'360','02276653','TRINUS CAPITAL DTVM','TRINUS CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(168,'362','01027058','CIELO IP S.A.','CIELO S.A. - INSTITUIÇÃO DE PAGAMENTO','Cielo','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/01027058.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(169,'363','62285390','QI CTVM S.A.','QI CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62285390.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(170,'364','09089356','EFÍ S.A. - IP','EFÍ S.A. - INSTITUIÇÃO DE PAGAMENTO','Efí | Gerencianet','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/09089356.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(171,'365','68757681','BINANCE BRASIL','BINANCE BRASIL CORRETORA DE CÂMBIO E VALORES MOBILIÁRIOS S.A.','Binance',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(172,'366','61533584','BCO SOCIETE GENERALE BRASIL','BANCO SOCIETE GENERALE BRASIL S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(173,'368','08357240','BCO CSF S.A.','Banco CSF S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/08357240.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(174,'370','61088183','BCO MIZUHO S.A.','Banco Mizuho do Brasil S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/61088183.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(175,'373','35977097','UP.P SEP S.A.','UP.P SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(176,'374','27351731','REALIZE SCFI S.A.','REALIZE SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/27351731.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(177,'376','33172537','BCO J.P. MORGAN S.A.','BANCO J.P. MORGAN S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/33172537.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(178,'377','17826860','BMS SCD S.A.','BMS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(179,'378','01852137','BCO BRASILEIRO DE CRÉDITO S.A.','BANCO BRASILEIRO DE CRÉDITO SOCIEDADE ANÔNIMA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(180,'379','01658426','COOP COOPERFORTE LTDA.','COOPERFORTE COOPERATIVA DE CRÉDITO E INVESTIMENTOS LTDA','Cooperforte',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(181,'380','22896431','PICPAY','PICPAY INSTITUIçãO DE PAGAMENTO S.A.','PicPay | Pic Pay','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/22896431.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(182,'381','60814191','BCO MERCEDES-BENZ S.A.','BANCO MERCEDES-BENZ DO BRASIL S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/60814191.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(183,'382','04307598','FIDUCIA SCMEPP LTDA','FIDÚCIA SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LIMITADA.','Fidúcia',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(184,'383','21018182','EBANX IP LTDA.','EBANX INSTITUICAO DE PAGAMENTOS LTDA.','EBANX','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/21018182.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(185,'384','11165756','GLOBAL SCM LTDA','GLOBAL FINANÇAS SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(186,'385','03844699','CECM DOS TRAB.PORT. DA G.VITOR','COOPERATIVA DE ECONOMIA E CREDITO MUTUO DOS TRABALHADORES PORTUARIOS DA GRANDE VITORIA - CREDESTIVA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(187,'386','30680829','NU FINANCEIRA S.A. CFI','NU FINANCEIRA S.A. - Sociedade de Crédito, Financiamento e Investimento',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/30680829.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(188,'389','17184037','BCO MERCANTIL DO BRASIL S.A.','Banco Mercantil do Brasil S.A.','Mercantil','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/17184037.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(189,'390','59274605','BCO GM S.A.','BANCO GM S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(190,'391','08240446','CCR DE IBIAM','COOPERATIVA DE CREDITO RURAL DE IBIAM - SULCREDI/IBIAM',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(191,'393','59109165','BCO VOLKSWAGEN S.A','Banco Volkswagen S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/59109165.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(192,'394','07207996','BCO BRADESCO FINANC. S.A.','Banco Bradesco Financiamentos S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/07207996.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(193,'395','08673569','F D GOLD DTVM LTDA','F.D\'GOLD - DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(194,'396','13884775','MAGALUPAY','MAGALUPAY INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13884775.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(195,'397','34088029','LISTO SCD S.A.','LISTO SOCIEDADE DE CREDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/34088029.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(196,'398','31749596','IDEAL CTVM S.A.','IDEAL CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(197,'399','01701201','Kirton Bank','Kirton Bank S.A. - Banco Múltiplo',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(198,'400','05491616','COOP CREDITAG - EM LIQUIDAÇÃO EXTRAJUDICIAL','COOPERATIVA DE CRÉDITO, POUPANÇA E SERVIÇOS FINANCEIROS - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(199,'401','15111975','IUGU IP S.A.','IUGU INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/15111975.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(200,'402','36947229','COBUCCIO S.A. SCFI','COBUCCIO S/A - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(201,'403','37880206','CORA SCFI','CORA SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.','Cora','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37880206.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(202,'404','37241230','SUMUP SCFI S.A','SUMUP SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.','SumUp','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37241230.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(203,'406','37715993','ACCREDITO SCD S.A.','ACCREDITO - SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37715993.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(204,'407','00329598','SEFER INVESTIMENTOS DTVM LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL','SEFER INVESTIMENTOS DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00329598.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(205,'408','36586946','BONUSPAGO SCD S.A.','BONUSPAGO SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(206,'410','05684234','PLANNER SOCIEDADE DE CRÉDITO DIRETO','PLANNER SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(207,'411','05192316','VIA CERTA FINANCIADORA S.A. - CFI','Via Certa Financiadora S.A. - Crédito, Financiamento e Investimentos',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(208,'412','15173776','SOCIAL BANK S/A','SOCIAL BANK BANCO MÚLTIPLO S/A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/15173776.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(209,'413','01858774','BCO BV S.A.','BANCO BV S.A.','BV | Banco BV | Votorantim','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/01858774.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(210,'414','37526080','LEND SCD S.A.','LEND SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(211,'415','17157777','BCO NACIONAL','BANCO NACIONAL S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(212,'416','19324634','LAMARA SCD S.A.','LAMARA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(213,'418','37414009','ZIPDIN SCD S.A.','ZIPDIN SOLUÇÕES DIGITAIS SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(214,'419','38129006','NUMBRS SCD S.A.','NUMBRS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(215,'421','39343350','CC LAR CREDI','LAR COOPERATIVA DE CRÉDITO - LAR CREDI',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(216,'422','58160789','BCO SAFRA S.A.','Banco Safra S.A.','Safra','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/58160789.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(217,'423','00460065','COLUNA S.A. DTVM','COLUNA S/A DISTRIBUIDORA DE TITULOS E VALORES MOBILIÁRIOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(218,'425','03881423','SOCINAL S.A. CFI','SOCINAL S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO','Socinal',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(219,'426','11285104','NEON FINANCEIRA - SCFI S.A.','NEON FINANCEIRA - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/11285104.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(220,'427','27302181','CRED.UFES','COOPERATIVA DE CRÉDITO DOS SERVIDORES DA UNIVERSIDADE FEDERAL DO ESPIRITO SANTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(221,'428','39664698','CREDSYSTEM SCD S.A.','CREDSYSTEM SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/39664698.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(222,'430','00204963','CCR SEARA','COOPERATIVA DE CREDITO RURAL SEARA - CREDISEARA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(223,'433','44077014','BR-CAPITAL DTVM S.A.','BR-CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(224,'435','38224857','DELFINANCE SCD S.A.','DELFINANCE SOCIEDADE DE CREDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(225,'438','67030395','TRUSTEE DTVM LTDA. - EM LIQUIDAÇÃO EXTRAJUDICIAL','TRUSTEE DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(226,'439','16695922','ID CTVM','ID CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(227,'440','82096447','COOP CREDI&GENTE','CREDI&GENTE - COOPERATIVA DE CRÉDITO E INVESTIMENTOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(228,'443','39416705','OCTA SCD S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','OCTA SOCIEDADE DE CRÉDITO DIRETO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(229,'444','40654622','TRINUS SCD S.A.','TRINUS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(230,'445','35551187','PLANTAE CFI','PLANTAE S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(231,'447','12392983','MIRAE ASSET (BRASIL) CCTVM LTDA.','MIRAE ASSET (BRASIL) CORRETORA DE CÂMBIO, TÍTULOS  E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(232,'448','39669186','HEMERA DTVM LTDA.','HEMERA DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(233,'449','37555231','DM','DM SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(234,'450','13203354','FITS IP','FITS INSTITUIÇÃO DE PAGAMENTO S.A.','Fits','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13203354.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(235,'451','40475846','J17 - SCD S/A','J17 - SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(236,'452','39676772','CREDIFIT SCD S.A.','CREDIFIT SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(237,'454','41592532','MÉRITO DTVM LTDA.','MÉRITO DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(238,'456','60498557','BCO MUFG BRASIL S.A.','Banco MUFG Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(239,'457','39587424','UY3 SCD S/A','UY3 SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(240,'458','07253654','HEDGE INVESTMENTS DTVM LTDA.','HEDGE INVESTMENTS DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(241,'460','42047025','UNAVANTI SCD S/A','UNAVANTI SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(242,'461','19540550','ASAAS IP S.A.','ASAAS GESTÃO FINANCEIRA INSTITUIÇÃO DE PAGAMENTO S.A.','Asaas','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/19540550.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(243,'462','39908427','STARK SCD S.A.','STARK SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(244,'463','40434681','AZUMI DTVM','AZUMI DISTRIBUIDORA DE TíTULOS E VALORES MOBILIáRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(245,'464','60518222','BCO SUMITOMO MITSUI BRASIL S.A.','Banco Sumitomo Mitsui Brasileiro S.A.','Sumitomo Mitsui | SMBC',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(246,'465','40083667','CAPITAL CONSIG SCD S.A.','CAPITAL CONSIG SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(247,'467','33886862','MASTER S/A CCTVM - EM LIQUIDAÇÃO EXTRAJUDICIAL','MASTER S/A CORRETORA DE CÂMBIO, TÍTULOS E VALORES MOBILIÁRIOS - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(248,'468','04862600','PORTOSEG S.A. CFI','PORTOSEG S.A. - CREDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(249,'469','07138049','PICPAY INVEST','PICPAY INVEST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/07138049.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(250,'470','18394228','CDC SCD S.A.','CDC SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(251,'473','33466988','BCO CAIXA GERAL BRASIL S.A.','Banco Caixa Geral - Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(252,'475','10371492','BCO YAMAHA MOTOR S.A.','Banco Yamaha Motor do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(253,'476','45860531','IDEA MAKER IP LTDA','IDEA MAKER INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(254,'477','33042953','CITIBANK N.A.','Citibank N.A.','Citibank | Citi','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33042953.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(255,'478','11760553','GAZINCRED S.A. SCFI','GAZINCRED S.A. SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(256,'479','60394079','BCO ITAUBANK S.A.','Banco ItauBank S.A.','ItaúBank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60394079.svg',1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(257,'481','43599047','SUPERLÓGICA SCD S.A.','SUPERLÓGICA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(258,'482','42259084','ARTTA SCD','ARTTA SOCIEDADE DE CRÉDITO DIRETO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(259,'484','36864992','APEX DTVM','APEX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(260,'487','62331228','DEUTSCHE BANK S.A.BCO ALEMAO','DEUTSCHE BANK S.A. - BANCO ALEMAO',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/62331228.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(261,'488','46518205','JPMORGAN CHASE BANK','JPMorgan Chase Bank, National Association',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/46518205.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(262,'495','44189447','BCO LA PROVINCIA B AIRES BCE','Banco de La Provincia de Buenos Aires',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(263,'496','45283173','BBVA BRASIL BI S.A.','BBVA BRASIL BANCO DE INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(264,'505','32062580','BCO UBS BRASIL','BANCO UBS (BRASIL) S.A.','UBS','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/32062580.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(265,'506','42066258','RJI','RJI CORRETORA DE TITULOS E VALORES MOBILIARIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(266,'507','37229413','SCFI EFÍ S.A.','SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO EFÍ S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37229413.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(267,'508','61384004','AVENUE SECURITIES BI S.A.','AVENUE SECURITIES BANCO DE INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(268,'509','13935893','CELCOIN IP S.A.','CELCOIN INSTITUICAO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/13935893.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(269,'510','39738065','FFCRED SCD S.A.','FFCRED SOCIEDADE DE CRÉDITO DIRETO S.A..',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(270,'511','44683140','MAGNUM SCD','MAGNUM SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(271,'512','36266751','FINVEST DTVM','FINVEST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(272,'513','44728700','ATF SCD S.A.','ATF SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(273,'514','73302408','EXIM SCC','EXIM SOCIEDADE CORRETORA DE CÂMBIO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(274,'516','36583700','PLACARPAY S.A - SCFI','PLACARPAY S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(275,'517','03816413','PAGUEVELOZ IP LTDA.','PAGUEVELOZ INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/03816413.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(276,'518','37679449','MERCADO CRÉDITO SCFI S.A.','MERCADO CRÉDITO SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/37679449.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(277,'519','40768766','LIONS TRUST DTVM','LIONS TRUST DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(278,'520','44705774','SOMAPAY SCD S.A.','SOMAPAY SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(279,'521','44019481','PEAK SEP S.A.','PEAK SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(280,'522','47593544','RED SCD S.A.','RED SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(281,'523','44292580','HR DIGITAL SCD','HR DIGITAL - SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(282,'524','45854066','WNT CAPITAL DTVM','WNT CAPITAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(283,'526','46026562','MONETARIE SCD','MONETARIE SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(284,'527','44478623','ATICCA SCD S.A.','ATICCA - SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(285,'528','34829992','CBSF DTVM -EM LIQUIDAÇÃO EXTRAJUDICIAL','CBSF DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.- EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(286,'529','17079937','PINBANK IP','PINBANK BRASIL INSTITUIÇÃO DE PAGAMENTO S.A.','PinBank',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(287,'530','47873449','SER FINANCE SCD S.A.','SER FINANCE SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(288,'531','34337707','BMP SCD S.A.','BMP SOCIEDADE DE CRÉDITO DIRETO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(289,'532','45745537','FUTURO SCD','FUTURO SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(290,'533','22575466','SRM BANK','SRM BANK INSTITUIÇÃO DE PAGAMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(291,'534','00714671','EWALLY IP S.A.','EWALLY INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/00714671.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(292,'535','39519944','OPEA SCD','OPEA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(293,'536','20855875','NEON PAGAMENTOS S.A. IP','NEON PAGAMENTOS S.A. - INSTITUIÇÃO DE PAGAMENTO','Neon | Neon Pagamentos','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/20855875.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(294,'537','45756448','SELECT CREDIT SCMEPP LTDA.','SELECT CREDIT SOCIEDADE DE CRÉDITO AO MICROEMPREENDEDOR E À EMPRESA DE PEQUENO PORTE LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(295,'538','20251847','SUDACRED SCD S.A.','SUDACRED SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(296,'539','00122327','SANTINVEST S.A. - CFI','SANTINVEST S.A. - CREDITO, FINANCIAMENTO E INVESTIMENTOS',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(297,'540','04849745','HBI SCD','HBI SOCIEDADE DE CRÉDITO DIRETO S/A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(298,'541','00954288','FDO GARANTIDOR CRÉDITOS','FUNDO GARANTIDOR DE CREDITOS - FGC',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00954288.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(299,'542','18189547','CLOUDWALK IP LTDA','CLOUDWALK INSTITUIÇÃO DE PAGAMENTO E SERVICOS LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/18189547.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(300,'543','92825397','COOPCRECE','COOPERATIVA DE ECONOMIA E CRÉDITO MÚTUO DOS ELETRICITÁRIOS E DOS TRABALHADORES DAS EMPRESAS DO SETOR DE ENERGIA - COOPCRECE',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(301,'544','38593706','MULTICRED SCD S.A.','MULTICRED SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(302,'546','30980539','OKTO IP','OKTO INSTITUIÇÃO DE PAGAMENTO S.A.','Okto',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(303,'547','45331622','BNK DIGITAL SCD S.A.','BNK DIGITAL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(304,'548','06249129','RPW S.A. SCFI','RPW S/A SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(305,'550','32074986','BEETELLER IP LTDA.','BEETELLER INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(306,'551','48967968','VERT DTVM LTDA.','VERT DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(307,'552','32192325','UZZIPAY IP S.A.','UZZIPAY INSTITUIÇÃO DE PAGAMENTO S.A.','UzziPay',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(308,'553','48707451','PERCAPITAL SCD S.A.','PERCAPITAL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(309,'554','28811341','BCO STONEX S.A.','BANCO STONEX S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(310,'555','02682287','PAN FINAN','PAN FINANCEIRA S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTOS',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02682287.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(311,'556','40333582','SAYGO CC S.A.','SAYGO SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(312,'557','30944783','PAGPRIME IP','PAGPRIME INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(313,'559','49288113','KANASTRA CFI','KANASTRA FINANCEIRA S.A, CREDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(314,'560','21995256','MAG IP LTDA.','MAG INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(315,'561','20757199','PAY4FUN IP S.A.','PAY4FUN INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(316,'562','18684408','AZIMUT BRASIL DTVM LTDA','AZIMUT BRASIL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(317,'563','40276692','PROTEGE CASH','PROTEGE CASH INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(318,'564','63019146','ANKOR CFI S.A.','ANKOR CAPITAL - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(319,'565','74014747','ÁGORA CTVM S.A.','ÁGORA CORRETORA DE TITULOS E VALORES MOBILIARIOS S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/74014747.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(320,'566','23114447','FLAGSHIP IP LTDA','FLAGSHIP INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(321,'567','33040601','MERCANTIL FINANCEIRA','MERCANTIL FINANCEIRA S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33040601.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(322,'569','12473687','CONTA PRONTA IP','CONTA PRONTA INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(323,'571','50489148','MONTE BRAVO CTVM S.A.','MONTE BRAVO CORRETORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(324,'572','51414521','ALL IN CRED SCD S.A.','ALL IN CRED SOCIEDADE DE CREDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(325,'573','18282093','OXY CH','OXY COMPANHIA HIPOTECÁRIA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(326,'574','48756121','A55 SCD S.A.','A55 SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(327,'575','48584954','DGBK CREDIT S.A. - SOCIEDADE DE CRÉDITO DIRETO.','DGBK CREDIT S.A. - SOCIEDADE DE CRÉDITO DIRETO.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(328,'576','11351086','MERCADO BITCOIN IP LTDA','MERCADO BITCOIN INSTITUICAO DE PAGAMENTO LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/11351086.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(329,'577','10663610','AF DESENVOLVE SP S.A.','DESENVOLVE SP - AGÊNCIA DE FOMENTO DO ESTADO DE SÃO PAULO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(330,'579','49555647','QUADRA SCD','QUADRA SOCIEDADE DE CRÉDITO DIRETO S.A.','Quadra',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(331,'585','50946592','SETHI SCD SA','SETHI SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(332,'586','35810871','Z1 IP LTDA.','Z1 INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(333,'587','37678915','FIDD DTVM LTDA.','FIDD DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(334,'588','20308187','AVANCARD PROVER IP LTDA','AVANCARD PROVER INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/20308187.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(335,'589','51212088','G5 SCD SA','G5 SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(336,'590','40473435','REPASSES FINANCEIROS E SOLUCOES TECNOLOGICAS IP S.A.','REPASSES FINANCEIROS E SOLUCOES TECNOLOGICAS INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(337,'591','02671743','BANVOX DTVM - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANVOX DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(338,'592','45548763','MAPS IP LTDA.','INSTITUIÇÃO DE PAGAMENTOS MAPS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(339,'593','27084098','TRANSFEERA IP S.A.','TRANSFEERA INSTITUIÇÃO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(340,'594','48703388','ASA SCFI S.A.','ASA SOCIEDADE DE CRÉDITO FINANCIAMENTO E INVESTIMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/48703388.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(341,'595','19468242','IFOOD PAGO IP','IFOOD PAGO INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/19468242.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(342,'596','39696395','CACTVS IP S.A.','CACTVS INSTITUICAO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(343,'597','34747388','ISSUER IP LTDA.','ISSUER INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(344,'598','50626276','KONECT SCD S/A','KONECT SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(345,'599','36321990','AGORACRED S/A SCFI','AGORACRED S/A SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(346,'600','59118133','BCO LUSO BRASILEIRO S.A.','Banco Luso Brasileiro S.A.','Luso Brasileiro',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(347,'604','31895683','BCO INDUSTRIAL DO BRASIL S.A.','Banco Industrial do Brasil S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(348,'610','78626983','BCO VR S.A.','Banco VR S.A.','VR',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(349,'611','61820817','BCO PAULISTA S.A.','Banco Paulista S.A.','Paulista','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/61820817.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(350,'612','31880826','BCO GUANABARA S.A.','Banco Guanabara S.A.','Guanabara','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/31880826.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(351,'613','60850229','OMNI BANCO S.A.','Omni Banco S.A.','Omni','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/60850229.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(352,'614','52440987','SANTS SCD S.A.','SANTS SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(353,'615','37470405','SMART SOLUTIONS GROUP IP LTDA','SMART SOLUTIONS GROUP INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(354,'619','49931906','TRIO IP LTDA.','TRIO INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(355,'620','51342763','REVOLUT SCD S.A.','REVOLUT SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/51342763.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(356,'623','59285411','BANCO PAN','Banco Pan S.A.','Pan | Banco Pan','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/59285411.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(357,'626','61348538','BCO C6 CONSIG','BANCO C6 CONSIGNADO S.A.','C6 Consignado','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61348538.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(358,'630','58497702','BANCO LETSBANK S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO LETSBANK S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(359,'632','52586293','Z-ON SCD S.A.','Z-ON SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(360,'633','68900810','BCO RENDIMENTO S.A.','Banco Rendimento S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/68900810.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(361,'634','17351180','BCO TRIANGULO S.A.','BANCO TRIANGULO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(362,'636','40112555','GIRO - SCD S/A','GIRO - SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(363,'637','60889128','BCO SOFISA S.A.','BANCO SOFISA S.A.','Sofisa | Sofisa Direto','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/60889128.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(364,'643','62144175','BCO PINE S.A.','Banco Pine S.A.','Pine','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/62144175.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(365,'644','54647259','321 SCD S.A.','321 SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(366,'646','91669747','DM SCFI','DM SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(367,'651','25104230','PAGARE IP S.A.','PAGARE INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(368,'653','61024352','BM PLENO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO PLENO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(369,'654','92874270','BCO DIGIMAIS S.A.','BANCO DIGIMAIS S.A.','Digimais',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(370,'655','59588111','BCO VOTORANTIM S.A.','Banco Votorantim S.A.','Votorantim','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/59588111.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(371,'659','35210410','ONEKEY PAYMENTS IP S.A.','ONEKEY PAYMENTS INSTITUICAO DE PAGAMENTO SA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(372,'660','34471744','PAGME IP LTDA','PAGME INSTITUIÇÃO DE PAGAMENTO LTDA.','PagMe',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(373,'661','55428859','FREEX SCC S.A.','FREEX SOCIEDADE CORRETORA DE CÂMBIO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(374,'662','32708748','WE PAY OUT IP LTDA.','WE PAY OUT INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(375,'663','44782130','ACTUAL DTVM S.A.','ACTUAL DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(376,'665','20018183','STARK BANK S.A. - IP','STARK BANK S.A. - INSTITUICAO DE PAGAMENTO','Stark Bank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/20018183.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(377,'668','48632754','CELCOIN SCD','CELCOIN SOCIEDADE DE CRÉDITO DIRETO S.A.','Celcoin','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/48632754.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(378,'669','47133056','TRANSFERO IP LTDA.','TRANSFERO INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(379,'670','11491029','BSN','BSN PAGAMENTOS INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(380,'671','26264220','ZERO IP','ZERO INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(381,'672','53505601','STONE CFI S.A.','STONE SOCIEDADE DE CREDITO, FINANCIAMENTO E INVESTIMENTO S.A.','Stone','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/53505601.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(382,'673','08482873','CCR DO AGRESTE ALAGOANO - EM LIQUIDAÇÃO EXTRAJUDICIAL','COOPERATIVA DE CRÉDITO RURAL DO AGRESTE ALAGOANO - COOPERAGRE - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(383,'674','27970567','HINOVA PAY IP S.A.','HINOVA PAY INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(384,'675','30723871','CASAS BAHIA PAY IP LTDA.','CASAS BAHIA PAY INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/30723871.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(385,'676','35479592','DUFRIO CFI S.A.','DUFRIO FINANCEIRA, CRÉDITO, FINANCIAMENTO E INVESTIMENTOS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(386,'677','33630661','GOWD IP LTDA.','GOWD INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(387,'678','45716916','FIDEM SCD S/A','FIDEM SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(388,'679','36690516','PAY IP S.A.','PAY INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(389,'680','55823094','DELTA GLOBAL SCD S.A.','DELTA GLOBAL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(390,'681','50871921','MT IP S.A.','MT INSTITUICAO DE PAGAMENTO SA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(391,'682','46505612','MONERY IP S.A.','MONERY INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(392,'683','30507541','BRASIL CASH IP S.A.','BRASIL CASH INSTITUICAO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(393,'684','56392166','HARMOS S.A. - SCFI','HARMOS S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(394,'685','26615279','TYCOON TECHNOLOGY IIP S.A','TYCOON TECHNOLOGY INSTITUICAO DE PAGAMENTO S.A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(395,'686','12481100','BIZ IP LTDA.','BIZ INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(396,'687','35340796','INCO SEP S.A.','INCO SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(397,'688','43978697','KIKAI SCD S.A.','KIKAI SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(398,'690','16814330','BK IP S.A.','BK INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(399,'692','56198117','ZYDI','ZYDI SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(400,'693','32820711','EFEX IP','EFEX INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(401,'694','54811417','WOOVI IP LTDA.','WOOVI INSTITUICAO DE PAGAMENTO LTDA',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/54811417.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(402,'695','35523352','BEES IP LTDA.','BEES INSTITUICAO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(403,'696','50032584','LOAN BRASIL SCD S.A.','LOAN BRASIL SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(404,'697','45056494','JM CORRETORA DE CÂMBIO','JM CORRETORA DE CÂMBIO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(405,'698','58367961','BIT SCD S.A.','BIT SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(406,'699','59396084','BFC SCD S.A.','BFC SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(407,'700','53822116','MW IP LTDA. - EM LIQUIDAÇÃO EXTRAJUDICIAL','MW INSTITUICAO DE PAGAMENTO LTDA - EM LIQUIDAÇÃO EXTRAJUDICIAL',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(408,'701','51118615','INTEGRAÇÃO DE CRÉDITO E COBRANÇA SCD','INTEGRAÇÃO DE CRÉDITO E COBRANÇA SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(409,'703','10440482','GETNET IP','GETNET ADQUIRÊNCIA E SERVIÇOS PARA MEIOS DE PAGAMENTO S.A. INSTITUIÇÃO DE PAGAMENTO','GetNet','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/10440482.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(410,'704','44663846','FESTOR IP LTDA.','FESTOR INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(411,'707','62232889','BCO DAYCOVAL S.A','Banco Daycoval S.A.','Daycoval',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(412,'708','33588252','BCO INDUSCRED DE INVESTIM. S/A','BANCO INDUSCRED DE INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(413,'712','78632767','OURIBANK S.A.','OURIBANK S.A. BANCO MÚLTIPLO','Ouribank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/78632767.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(414,'714','00411939','FINAMAX S.A. CFI','FINAMAX S.A. - CREDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(415,'719','33884941','BANCO MASTER MÚLTIPLO - EM LIQUIDAÇÃO EXTRAJUDICIAL','BANCO MASTER MÚLTIPLO S.A. - EM LIQUIDAÇÃO EXTRAJUDICIAL','Master',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(416,'741','00517645','BCO RIBEIRAO PRETO S.A.','BANCO RIBEIRAO PRETO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00517645.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(417,'743','00795423','BANCO SEMEAR','Banco Semear S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/00795423.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(418,'745','33479023','BCO CITIBANK S.A.','Banco Citibank S.A.','Citibank','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/33479023.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(419,'747','01023570','BCO RABOBANK INTL BRASIL S.A.','Banco Rabobank International Brasil S.A.','Rabobank',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(420,'748','01181521','BANCO COOPERATIVO SICREDI','BANCO COOPERATIVO SICREDI S.A.','Sicredi','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/01181521.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(421,'751','29030467','Scotiabank Brasil','Scotiabank Brasil S.A. Banco Múltiplo','Scotiabank',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(422,'752','01522368','BCO BNP PARIBAS BRASIL S A','Banco BNP Paribas Brasil S.A.','BNP Paribas',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(423,'753','74828799','NOVO BCO CONTINENTAL S.A. - BM','Novo Banco Continental S.A. - Banco Múltiplo',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(424,'754','76543115','BANCO SISTEMA','Banco Sistema S.A.','Banco Sistema',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(425,'755','62073200','BOFA MERRILL LYNCH BM S.A.','Bank of America Merrill Lynch Banco Múltiplo S.A.','Bank of America | BOFA',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(426,'756','02038232','BANCO SICOOB S.A.','BANCO COOPERATIVO SICOOB S.A. - BANCO SICOOB','Sicoob','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/02038232.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(427,'757','02318507','BCO KEB HANA DO BRASIL S.A.','BANCO KEB HANA DO BRASIL S.A.','KEB Hana',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(428,'759','42963742','BANSUR JM SCD S.A.','BANSUR JM SOCIEDADE DE CRÉDITO DIRETO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(429,'760','34139916','EMCASH SERV FINANC SEP S.A.','EMCASH SERVIÇOS FINANCEIROS SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(430,'761','53842122','URBANO S.A. SCFI','URBANO S.A. - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(431,'763','56106523','VUE IP S.A.','VUE INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(432,'764','04306351','INDEPENDÊNCIA CC','INDEPENDÊNCIA COOPERATIVA DE CRÉDITO E INVESTIMENTO - INDEPENDÊNCIA COOPERATIVA DE CRÉDITO','Independência',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:52:22'),
(433,'765','37753531','PAGSMILE IP LTDA.','PAGSMILE INSTITUIÇÃO DE PAGAMENTO LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(434,'766','52833288','LB PAY IP LTDA','LB PAY INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(435,'767','62264924','QORE','QORE DISTRIBUIDORA DE TITULOS E VALORES MOBILIÁRIOS LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(436,'768','20443996','BECKER FINANCEIRA SA - CFI','BECKER FINANCEIRA S.A. - CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(437,'769','24313102','99PAY IP S.A.','99PAY INSTITUICAO DE PAGAMENTO S.A.','99Pay | 99','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/24313102.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(438,'770','38320462','V3 IP S.A.','V3 INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(439,'771','57824223','WX IP LTDA.','WX INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(440,'773','53908413','KIWIFY IP','KIWIFY INSTITUICAO DE PAGAMENTO LTDA','Kiwify','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/53908413.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(441,'774','33959738','MOVA SEP S.A.','MOVA SOCIEDADE DE EMPRÉSTIMO ENTRE PESSOAS S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(442,'775','47381104','CONTAAZUL IP LTDA.','CONTAAZUL INSTITUICAO DE PAGAMENTO LTDA.','ContaAzul','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/png/47381104.png',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(443,'776','44650156','ONCRED - SCD S.A.','ONCRED - SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(444,'778','58674454','PB SCD','PB SOCIEDADE DE CREDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(445,'780','12102128','SAFETYPAY BRASIL IP LTDA','SAFETYPAY BRASIL INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(446,'781','58006471','BASE DTVM','BASE DISTRIBUIDORA DE TÍTULOS E VALORES MOBILIÁRIOS LTDA.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(447,'783','31680151','SWAP IP S.A.','SWAP INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/31680151.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(448,'784','17768068','PINPAG IP S.A.','PINPAG INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(449,'785','53058329','LA FINTECA IP LTDA','LA FINTECA INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(450,'786','52076716','AWX BRASIL IP LTDA.','AWX BRASIL  INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(451,'787','10789035','ATTRUS IP S/A','ATTRUS INSTITUIÇÃO DE PAGAMENTO S/A',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(452,'788','35713491','PROTOTYPE IP S.A.','PROTOTYPE INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(453,'789','57654096','APUSDIGITAL IP LTDA.','APUSDIGITAL INSTITUICAO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(454,'790','54024532','MAX IP','MAX INSTITUIÇÃO DE PAGAMENTO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(455,'791','62448932','MULTIPLIKE FINANCEIRA S.A. SCFI','MULTIPLIKE FINANCEIRA S.A. SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(456,'792','44921281','NIXFIN SCD','NIXFIN SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(457,'793','61021673','MAGALUPAY SCFI S.A.','MAGALUPAY - SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.','MagaluPay | Magalu','https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/61021673.svg',1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(458,'794','44323831','ATUAL CC LTDA','ATUAL SOCIEDADE CORRETORA DE CÂMBIO LTDA',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(459,'795','52067630','BANCO TRATON BRASIL S.A.','BANCO TRATON BRASIL S.A.','Traton',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(460,'796','48786608','ASAAS CFI S.A','ASAAS SOCIEDADE DE CRÉDITO, FINANCIAMENTO E INVESTIMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(461,'798','01648418','NSTECH IP S.A.','NSTECH IP INSTITUICAO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(462,'803','25021356','DLOCAL BRASIL IP S.A.','DLOCAL BRASIL INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(463,'804','32343119','MÊNTORE IP S.A.','MÊNTORE INSTITUIÇÃO DE PAGAMENTO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(464,'805','38486817','BCO DES. DE MG S.A.','BANCO DE DESENVOLVIMENTO DE MINAS GERAIS S.A.-BDMG','Desenvolve MG',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(465,'807','63822040','GUARDIAN SCD S.A.','GUARDIAN SOCIEDADE DE CRÉDITO DIRETO S.A.',NULL,NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34'),
(466,'808','40867163','RENDIMENTO SCD','RENDIMENTO SOCIEDADE DE CRÉDITO DIRETO S.A.','Rendimento',NULL,1,'2026-11-27 23:51:34','2026-11-27 23:51:34');
/*!40000 ALTER TABLE `banks` ENABLE KEYS */;
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

LOCK TABLES `cost_centers` WRITE;
/*!40000 ALTER TABLE `cost_centers` DISABLE KEYS */;
INSERT INTO `cost_centers` VALUES
(1,NULL,'Pessoal','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'PES','Despesas e receitas pessoais','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,NULL,'Casa','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'CAS','Moradia e manutenção','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(3,NULL,'Empresa','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'EMP','Operação do negócio','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(4,NULL,'Carro','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'CAR','Veículo e transporte','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(5,NULL,'Operacional','general',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'OPE','Custos operacionais gerais','active','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(6,2,'Apartamento Centro','property','Rua das Flores 100',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'99887766, 123456789',NULL,NULL,'active','2026-11-28 00:45:02','2026-11-28 00:45:02'),
(8,1,'Imovel Teste CEP','property','Praça Sete de Setembro, 1000 - Sala 5 — Centro, Belo Horizonte/MG','30130-010','Praça Sete de Setembro','1000','Sala 5','Centro','Belo Horizonte','MG','11223344',NULL,NULL,'active','2026-11-28 11:26:53','2026-11-28 11:26:53');
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
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `investment_movements` WRITE;
/*!40000 ALTER TABLE `investment_movements` DISABLE KEYS */;
INSERT INTO `investment_movements` VALUES
(17,11,'application',10000.00,'2026-11-28',110.000000,'Aplicação inicial','2026-11-28 11:27:07');
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
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `investment_returns` WRITE;
/*!40000 ALTER TABLE `investment_returns` DISABLE KEYS */;
INSERT INTO `investment_returns` VALUES
(1,1,11,2026,15000.00,127.50,0.850000,15127.50,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,2,11,2026,8000.00,68.00,0.850000,8068.00,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(3,1,10,2026,15000.00,133.50,0.890000,15133.50,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(4,2,10,2026,8000.00,71.20,0.890000,8071.20,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(5,1,9,2026,15000.00,139.50,0.930000,15139.50,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(6,2,9,2026,8000.00,74.40,0.930000,8074.40,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(16,11,11,2026,10000.00,92.74,0.927400,10092.74,'2026-11-28 11:27:14','2026-11-28 11:27:14');
/*!40000 ALTER TABLE `investment_returns` ENABLE KEYS */;
UNLOCK TABLES;
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

LOCK TABLES `investment_types` WRITE;
/*!40000 ALTER TABLE `investment_types` DISABLE KEYS */;
INSERT INTO `investment_types` VALUES
(1,NULL,'CDB','cdb','cdi',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(2,NULL,'LCI','lci','cdi',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(3,NULL,'LCA','lca','cdi',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(4,NULL,'Tesouro Selic','tesouro_selic','selic',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(5,NULL,'Tesouro IPCA+','tesouro_ipca','ipca',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(6,NULL,'Tesouro Prefixado','tesouro_prefixado','prefixado',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(7,NULL,'CDI','cdi','cdi',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(8,NULL,'Poupança','poupanca','none',0.500000,'monthly','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(9,NULL,'Fundo DI','fundo_di','cdi',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(10,NULL,'Ações','acoes','none',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(11,NULL,'ETF','etf','none',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(12,NULL,'Previdência','previdencia','none',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(13,NULL,'Cripto','cripto','none',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(14,NULL,'Outros','outros','none',NULL,'annual','active','2026-11-28 11:18:29','2026-11-28 11:18:29'),
(15,1,'CDB Teste','cdb_teste','cdi',110.000000,'annual','active','2026-11-28 11:27:01','2026-11-28 11:27:01');
/*!40000 ALTER TABLE `investment_types` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `investments` WRITE;
/*!40000 ALTER TABLE `investments` DISABLE KEYS */;
INSERT INTO `investments` VALUES
(1,1,1,'XP Investimentos','cdb',NULL,'CDB Liquidez Diaria',15000.00,'2026-06-27',11.500000,'annual',NULL,'annual','cdi','diaria','2028-05-27','active','SOMASE demo','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,1,1,'Tesouro Direto','tesouro',NULL,'Tesouro Selic 2029',8000.00,'2026-07-27',10.750000,'annual',NULL,'annual','selic','d1','2029-05-27','active','SOMASE demo','2026-11-27 16:31:16','2026-11-27 16:31:16'),
(11,1,1,'Banco Teste','CDB Teste',15,'CDB Teste 110 CDI',10000.00,'2026-11-28',110.000000,NULL,10.650000,'annual',NULL,NULL,NULL,'active',NULL,'2026-11-28 11:27:07','2026-11-28 11:27:07');
/*!40000 ALTER TABLE `investments` ENABLE KEYS */;
UNLOCK TABLES;
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `payment_methods` WRITE;
/*!40000 ALTER TABLE `payment_methods` DISABLE KEYS */;
INSERT INTO `payment_methods` VALUES
(1,NULL,'PIX','pix','bank',NULL,1,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(2,NULL,'DÉBITO EM CONTA','debito_conta','bank',NULL,2,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(3,NULL,'DÉBITO AUTOMÁTICO','debito_automatico','bank',NULL,3,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(4,NULL,'CARTÃO DE DÉBITO','cartao_debito','card',NULL,4,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(5,NULL,'CARTÃO DE CRÉDITO','cartao_credito','card',NULL,5,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(6,NULL,'BOLETO','boleto','bank',NULL,6,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(7,NULL,'DINHEIRO','dinheiro','cash',NULL,7,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(8,NULL,'TRANSFERÊNCIA','transferencia','transfer',NULL,8,'active','2026-11-28 15:37:46','2026-11-28 15:37:46'),
(9,NULL,'OUTRO','outro','other',NULL,9,'active','2026-11-28 15:37:46','2026-11-28 15:37:46');
/*!40000 ALTER TABLE `payment_methods` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
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
) ENGINE=InnoDB AUTO_INCREMENT=228 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES
(1,1,1,2,NULL,'expense','Supermercado do mes',720.00,'2026-11-08','2026-11-13','2026-11-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(2,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-11-05','2026-11-10',NULL,'pending','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(3,1,1,3,NULL,'expense','Energia eletrica',215.00,'2026-11-15','2026-11-20','2026-11-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(4,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-11-20','2026-11-25','2026-11-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(5,1,1,4,NULL,'expense','Combustivel',380.00,'2026-11-22','2026-11-27','2026-11-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(6,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-11-12','2026-11-17','2026-11-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(7,1,1,11,NULL,'income','Salario mensal',7800.00,'2026-11-05','2026-11-10','2026-11-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(8,1,1,13,NULL,'income','Projeto freelance',1350.00,'2026-11-18','2026-11-23','2026-11-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(9,1,1,2,NULL,'expense','Supermercado do mes',752.00,'2026-10-08','2026-10-13','2026-10-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(10,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-10-05','2026-10-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(11,1,1,3,NULL,'expense','Energia eletrica',227.00,'2026-10-15','2026-10-20','2026-10-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(12,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-10-20','2026-10-25','2026-10-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(13,1,1,4,NULL,'expense','Combustivel',406.00,'2026-10-22','2026-10-27','2026-10-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(14,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-10-12','2026-10-17','2026-10-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(15,1,1,11,NULL,'income','Salario mensal',7920.00,'2026-10-05','2026-10-10','2026-10-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(16,1,1,13,NULL,'income','Projeto freelance',1530.00,'2026-10-18','2026-10-23','2026-10-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(17,1,1,2,NULL,'expense','Supermercado do mes',784.00,'2026-09-08','2026-09-13','2026-09-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(18,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-09-05','2026-09-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(19,1,1,3,NULL,'expense','Energia eletrica',239.00,'2026-09-15','2026-09-20','2026-09-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(20,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-09-20','2026-09-25','2026-09-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(21,1,1,4,NULL,'expense','Combustivel',432.00,'2026-09-22','2026-09-27','2026-09-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(22,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-09-12','2026-09-17','2026-09-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(23,1,1,11,NULL,'income','Salario mensal',8040.00,'2026-09-05','2026-09-10','2026-09-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(24,1,1,13,NULL,'income','Projeto freelance',1710.00,'2026-09-18','2026-09-23','2026-09-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(25,1,1,2,NULL,'expense','Supermercado do mes',816.00,'2026-08-08','2026-08-13','2026-08-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(26,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-08-05','2026-08-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(27,1,1,3,NULL,'expense','Energia eletrica',251.00,'2026-08-15','2026-08-20','2026-08-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(28,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-08-20','2026-08-25','2026-08-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(29,1,1,4,NULL,'expense','Combustivel',458.00,'2026-08-22','2026-08-27','2026-08-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(30,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-08-12','2026-08-17','2026-08-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(31,1,1,11,NULL,'income','Salario mensal',8160.00,'2026-08-05','2026-08-10','2026-08-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(32,1,1,13,NULL,'income','Projeto freelance',1890.00,'2026-08-18','2026-08-23','2026-08-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(33,1,1,2,NULL,'expense','Supermercado do mes',848.00,'2026-07-08','2026-07-13','2026-07-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(34,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-07-05','2026-07-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(35,1,1,3,NULL,'expense','Energia eletrica',263.00,'2026-07-15','2026-07-20','2026-07-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(36,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-07-20','2026-07-25','2026-07-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(37,1,1,4,NULL,'expense','Combustivel',484.00,'2026-07-22','2026-07-27','2026-07-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(38,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-07-12','2026-07-17','2026-07-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(39,1,1,11,NULL,'income','Salario mensal',8280.00,'2026-07-05','2026-07-10','2026-07-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(40,1,1,13,NULL,'income','Projeto freelance',2070.00,'2026-07-18','2026-07-23','2026-07-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(41,1,1,2,NULL,'expense','Supermercado do mes',880.00,'2026-06-08','2026-06-13','2026-06-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(42,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-06-05','2026-06-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(43,1,1,3,NULL,'expense','Energia eletrica',275.00,'2026-06-15','2026-06-20','2026-06-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(44,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-06-20','2026-06-25','2026-06-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(45,1,1,4,NULL,'expense','Combustivel',510.00,'2026-06-22','2026-06-27','2026-06-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(46,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-06-12','2026-06-17','2026-06-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(47,1,1,11,NULL,'income','Salario mensal',8400.00,'2026-06-05','2026-06-10','2026-06-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(48,1,1,13,NULL,'income','Projeto freelance',2250.00,'2026-06-18','2026-06-23','2026-06-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(49,1,1,2,NULL,'expense','Supermercado do mes',912.00,'2026-05-08','2026-05-13','2026-05-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(50,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-05-05','2026-05-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(51,1,1,3,NULL,'expense','Energia eletrica',287.00,'2026-05-15','2026-05-20','2026-05-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(52,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-05-20','2026-05-25','2026-05-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(53,1,1,4,NULL,'expense','Combustivel',536.00,'2026-05-22','2026-05-27','2026-05-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(54,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-05-12','2026-05-17','2026-05-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(55,1,1,11,NULL,'income','Salario mensal',8520.00,'2026-05-05','2026-05-10','2026-05-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(56,1,1,13,NULL,'income','Projeto freelance',2430.00,'2026-05-18','2026-05-23','2026-05-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(57,1,1,2,NULL,'expense','Supermercado do mes',944.00,'2026-04-08','2026-04-13','2026-04-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(58,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-04-05','2026-04-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(59,1,1,3,NULL,'expense','Energia eletrica',299.00,'2026-04-15','2026-04-20','2026-04-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(60,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-04-20','2026-04-25','2026-04-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(61,1,1,4,NULL,'expense','Combustivel',562.00,'2026-04-22','2026-04-27','2026-04-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(62,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-04-12','2026-04-17','2026-04-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(63,1,1,11,NULL,'income','Salario mensal',8640.00,'2026-04-05','2026-04-10','2026-04-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(64,1,1,13,NULL,'income','Projeto freelance',2610.00,'2026-04-18','2026-04-23','2026-04-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(65,1,1,2,NULL,'expense','Supermercado do mes',976.00,'2026-03-08','2026-03-13','2026-03-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(66,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-03-05','2026-03-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(67,1,1,3,NULL,'expense','Energia eletrica',311.00,'2026-03-15','2026-03-20','2026-03-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(68,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-03-20','2026-03-25','2026-03-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(69,1,1,4,NULL,'expense','Combustivel',588.00,'2026-03-22','2026-03-27','2026-03-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(70,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-03-12','2026-03-17','2026-03-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(71,1,1,11,NULL,'income','Salario mensal',8760.00,'2026-03-05','2026-03-10','2026-03-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(72,1,1,13,NULL,'income','Projeto freelance',2790.00,'2026-03-18','2026-03-23','2026-03-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(73,1,1,2,NULL,'expense','Supermercado do mes',1008.00,'2026-02-08','2026-02-13','2026-02-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(74,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-02-05','2026-02-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(75,1,1,3,NULL,'expense','Energia eletrica',323.00,'2026-02-15','2026-02-20','2026-02-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(76,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-02-20','2026-02-25','2026-02-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(77,1,1,4,NULL,'expense','Combustivel',614.00,'2026-02-22','2026-02-27','2026-02-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(78,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-02-12','2026-02-17','2026-02-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(79,1,1,11,NULL,'income','Salario mensal',8880.00,'2026-02-05','2026-02-10','2026-02-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(80,1,1,13,NULL,'income','Projeto freelance',2970.00,'2026-02-18','2026-02-23','2026-02-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(81,1,1,2,NULL,'expense','Supermercado do mes',1040.00,'2026-01-08','2026-01-13','2026-01-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(82,1,1,3,NULL,'expense','Aluguel',2400.00,'2026-01-05','2026-01-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(83,1,1,3,NULL,'expense','Energia eletrica',335.00,'2026-01-15','2026-01-20','2026-01-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(84,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-01-20','2026-01-25','2026-01-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(85,1,1,4,NULL,'expense','Combustivel',640.00,'2026-01-22','2026-01-27','2026-01-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(86,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-01-12','2026-01-17','2026-01-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(87,1,1,11,NULL,'income','Salario mensal',9000.00,'2026-01-05','2026-01-10','2026-01-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(88,1,1,13,NULL,'income','Projeto freelance',3150.00,'2026-01-18','2026-01-23','2026-01-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(89,1,1,2,NULL,'expense','Supermercado do mes',1072.00,'2025-12-08','2025-12-13','2025-12-08','paid','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(90,1,1,3,NULL,'expense','Aluguel',2400.00,'2025-12-05','2025-12-10',NULL,'paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(91,1,1,3,NULL,'expense','Energia eletrica',347.00,'2025-12-15','2025-12-20','2025-12-15','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(92,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2025-12-20','2025-12-25','2025-12-20','paid','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(93,1,1,4,NULL,'expense','Combustivel',666.00,'2025-12-22','2025-12-27','2025-12-22','paid','debit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(94,1,1,5,NULL,'expense','Plano de saude',640.00,'2025-12-12','2025-12-17','2025-12-12','paid','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(95,1,1,11,NULL,'income','Salario mensal',9120.00,'2025-12-05','2025-12-10','2025-12-05','received','transfer','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(96,1,1,13,NULL,'income','Projeto freelance',3330.00,'2025-12-18','2025-12-23','2025-12-18','received','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(128,1,1,3,NULL,'expense','Aluguel do proximo mes',2400.00,'2026-11-27','2026-12-03',NULL,'pending','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(129,1,1,10,NULL,'expense','Fatura do cartao',1380.45,'2026-11-27','2026-12-09',NULL,'pending','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(130,1,1,5,NULL,'expense','Plano de saude',640.00,'2026-11-27','2026-12-15',NULL,'pending','boleto','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(131,1,1,13,NULL,'income','Projeto freelance (2a parcela)',1350.00,'2026-11-27','2026-12-18',NULL,'expected','pix','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(132,1,1,7,NULL,'expense','Assinaturas digitais',89.90,'2026-11-27','2026-12-22',NULL,'pending','credit','SOMASE demo',NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-27 16:31:16','2026-11-27 16:31:16'),
(183,2,18,NULL,NULL,'expense','Conta de luz - ENEL',195.79,'2026-11-05','2026-11-05','2026-11-05','paid','transfer','Importado de extrato em 27/11/2026 21:46',NULL,'csv:e691a809bef9bca2ea961d27c80455783b66cbb2',NULL,NULL,NULL,NULL,'2026-11-28 00:46:53','2026-11-28 00:46:53'),
(184,2,18,NULL,NULL,'income','PIX recebido cliente ABC',2500.00,'2026-11-10','2026-11-10','2026-11-10','received','transfer','Importado de extrato em 27/11/2026 21:46',NULL,'csv:52916331a37041fe1e18a12008c2ef124a28b525',NULL,NULL,NULL,NULL,'2026-11-28 00:46:53','2026-11-28 00:46:53'),
(185,2,18,NULL,NULL,'expense','Teste anexo protegido',10.50,'2026-11-27',NULL,NULL,'paid',NULL,NULL,NULL,NULL,'u2/2026/11/dc246a97821d700a3bcb4020.pdf',NULL,NULL,NULL,'2026-11-28 00:48:03','2026-11-28 00:48:03'),
(186,2,18,NULL,NULL,'expense','Teste anexo protegido',10.50,'2026-11-27',NULL,NULL,'paid',NULL,NULL,NULL,NULL,'u2/2026/11/b9bb855f2fe4eff0bb247d04.pdf',NULL,NULL,NULL,'2026-11-28 00:48:37','2026-11-28 00:48:37'),
(203,1,1,NULL,NULL,'expense','CONTA DE TESTE MINUSCULA',123.45,'2026-11-28',NULL,NULL,'paid','debito_conta',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-11-28 11:26:37','2026-11-28 11:26:37');
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
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'Administrador','admin@example.com','$2b$10$vWAdPPDyhPW0u/UeSpdf1eLsXidEiwemycK/I9x7I1DcVjCLSTJii',1,'active',NULL,'local',NULL,NULL,NULL,NULL,'2026-11-28 11:32:01','2026-11-27 16:31:16','2026-11-28 11:32:01'),
(2,'Administrador SOMASE','admin@somase.com','$2y$10$CLh5deExaEM80yzUleFVs.HBUfoLoeXRKr3TU4ACciq6a92wFoj/C',1,'active','1985-03-12','local',NULL,'2026-11-27 19:36:04','2026-11-27 19:47:49',NULL,'2026-11-28 15:40:00','2026-11-27 19:36:04','2026-11-28 15:40:00'),
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
