-- ============================================================
-- SOMASE — versao PostgreSQL de 0001_admin_seed.sql
-- GERADO AUTOMATICAMENTE por tools/build_postgres_sql.py
-- Nao edite este arquivo a mao: altere database/migrations e rode
--   python3 tools/build_postgres_sql.py
-- origem: database/seeds/0001_admin_seed.sql
-- sha256: f389a84cdcd84a2f
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

INSERT INTO "roles" ("slug", "name", "is_system") VALUES
('superadmin', 'Super Administrador', 1),
('admin',      'Administrador',       0),
('user',       'Usuario',             0)
ON CONFLICT DO NOTHING;

INSERT INTO "permissions" ("slug", "name", "group_name") VALUES
('view_dashboard', 'Ver dashboard',        'geral'),
('manage_users',   'Gerenciar usuarios',   'administracao'),
('manage_roles',   'Gerenciar roles',      'administracao')
ON CONFLICT DO NOTHING;

INSERT INTO "role_permissions" ("role_id", "permission_id")
SELECT r.id, p.id FROM "roles" r, "permissions" p
WHERE r.slug = 'admin' AND p.slug IN ('view_dashboard', 'manage_users', 'manage_roles')
ON CONFLICT DO NOTHING;

INSERT INTO "role_permissions" ("role_id", "permission_id")
SELECT r.id, p.id FROM "roles" r, "permissions" p
WHERE r.slug = 'user' AND p.slug IN ('view_dashboard')
ON CONFLICT DO NOTHING;

INSERT INTO "users" ("name", "email", "password", "role_id", "status", "created_at", "updated_at")
SELECT 'Administrador', 'admin@example.com',
       '$2b$10$vWAdPPDyhPW0u/UeSpdf1eLsXidEiwemycK/I9x7I1DcVjCLSTJii',
       r.id, 'active', NOW(), NOW()
FROM "roles" r WHERE r.slug = 'superadmin'
ON CONFLICT ("email") DO UPDATE SET "name" = EXCLUDED."name", "password" = EXCLUDED."password", "role_id" = EXCLUDED."role_id", "status" = EXCLUDED."status", "updated_at" = NOW();
