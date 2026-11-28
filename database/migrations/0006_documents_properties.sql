-- ============================================================
-- SOMASE — Imoveis/centros de custo e documentos (boletos, NFC-e)
-- Migration 0006
--
-- IMPORTANTE: o pedido original citava "0005_documents_properties.sql",
-- mas a 0005 ja foi usada pelo cadastro de bancos (0005_banks.sql).
-- Para nao colidir, esta migration e a 0006.
--
-- 100% idempotente: cada ALTER e protegido por consulta ao
-- information_schema + PREPARE/EXECUTE. Pode ser importada duas vezes
-- no phpMyAdmin sem erro (a segunda execucao apenas nao faz nada).
--
--  * cost_centers.kind        -> general | property | vehicle | company | project
--  * cost_centers.address     -> endereco do imovel (opcional)
--  * cost_centers.identifiers -> numeros de instalacao/medidor/conta,
--                               separados por virgula (usados para
--                               reconhecer o imovel ao ler um documento)
--  * transactions.document_code   -> codigo de barras/QR lido (44-48 digitos)
--  * transactions.import_ref      -> referencia unica da linha importada (OFX/CSV)
--  * transactions.attachment_path -> caminho relativo do anexo em storage/uploads
--
-- Equivalente PostgreSQL: database/postgresql/0006_documents_properties.pg.sql
-- ============================================================

-- ---------- cost_centers.kind ----------
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'kind');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `kind` VARCHAR(20) NOT NULL DEFAULT ''general'' AFTER `name`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------- cost_centers.address ----------
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'address');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `address` VARCHAR(255) NULL AFTER `kind`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------- cost_centers.identifiers ----------
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND COLUMN_NAME = 'identifiers');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD COLUMN `identifiers` VARCHAR(500) NULL AFTER `address`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------- transactions.document_code ----------
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transactions' AND COLUMN_NAME = 'document_code');
SET @sql := IF(@has = 0,
    'ALTER TABLE `transactions` ADD COLUMN `document_code` VARCHAR(64) NULL AFTER `notes`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------- transactions.import_ref ----------
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transactions' AND COLUMN_NAME = 'import_ref');
SET @sql := IF(@has = 0,
    'ALTER TABLE `transactions` ADD COLUMN `import_ref` VARCHAR(100) NULL AFTER `document_code`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------- transactions.attachment_path ----------
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transactions' AND COLUMN_NAME = 'attachment_path');
SET @sql := IF(@has = 0,
    'ALTER TABLE `transactions` ADD COLUMN `attachment_path` VARCHAR(255) NULL AFTER `import_ref`',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------- indices ----------
SET @has := (SELECT COUNT(*) FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transactions' AND INDEX_NAME = 'idx_transactions_document');
SET @sql := IF(@has = 0,
    'ALTER TABLE `transactions` ADD INDEX `idx_transactions_document` (`user_id`, `document_code`)',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'transactions' AND INDEX_NAME = 'idx_transactions_import');
SET @sql := IF(@has = 0,
    'ALTER TABLE `transactions` ADD INDEX `idx_transactions_import` (`user_id`, `account_id`, `import_ref`)',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has := (SELECT COUNT(*) FROM information_schema.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'cost_centers' AND INDEX_NAME = 'idx_cost_centers_kind');
SET @sql := IF(@has = 0,
    'ALTER TABLE `cost_centers` ADD INDEX `idx_cost_centers_kind` (`user_id`, `kind`)',
    'DO 0');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- Fim da migration 0006. Nenhum dado existente e alterado: as novas
-- colunas nascem NULL (ou 'general' nos centros de custo), portanto
-- centros de custo antigos continuam funcionando como "Outros".
-- ============================================================
