-- ============================================================
-- SOMASE — versao PostgreSQL de 0006_documents_properties.sql
-- GERADO AUTOMATICAMENTE por tools/build_postgres_sql.py
-- Nao edite este arquivo a mao: altere database/migrations e rode
--   python3 tools/build_postgres_sql.py
-- origem: database/migrations/0006_documents_properties.sql
-- sha256: 4c5b5ffb2f36883d
-- ============================================================
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET client_min_messages = warning;

-- funcao usada pelos gatilhos de updated_at (equivale ao ON UPDATE do MySQL)
CREATE OR REPLACE FUNCTION somase_set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE "cost_centers" ADD COLUMN IF NOT EXISTS "kind" varchar(20) NOT NULL DEFAULT 'general';

ALTER TABLE "cost_centers" ADD COLUMN IF NOT EXISTS "address" varchar(255) NULL;

ALTER TABLE "cost_centers" ADD COLUMN IF NOT EXISTS "identifiers" varchar(500) NULL;

ALTER TABLE "transactions" ADD COLUMN IF NOT EXISTS "document_code" varchar(64) NULL;

ALTER TABLE "transactions" ADD COLUMN IF NOT EXISTS "import_ref" varchar(100) NULL;

ALTER TABLE "transactions" ADD COLUMN IF NOT EXISTS "attachment_path" varchar(255) NULL;

CREATE INDEX IF NOT EXISTS "idx_transactions_document" ON "transactions" ("user_id", "document_code");

CREATE INDEX IF NOT EXISTS "idx_transactions_import" ON "transactions" ("user_id", "account_id", "import_ref");

CREATE INDEX IF NOT EXISTS "idx_cost_centers_kind" ON "cost_centers" ("user_id", "kind");
