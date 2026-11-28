-- ============================================================
-- SOMASE — versao PostgreSQL de 0002_finance_seed.sql
-- GERADO AUTOMATICAMENTE por tools/build_postgres_sql.py
-- Nao edite este arquivo a mao: altere database/migrations e rode
--   python3 tools/build_postgres_sql.py
-- origem: database/seeds/0002_finance_seed.sql
-- sha256: 70b1ecd10c0dbeb8
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

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Alimentação', 'expense', 'utensils', '#ef4444', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Alimentação' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Supermercado', 'expense', 'shopping-cart', '#f97316', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Supermercado' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Moradia', 'expense', 'home', '#eab308', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Moradia' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Transporte', 'expense', 'car', '#d97706', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Transporte' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Saúde', 'expense', 'heart', '#ec4899', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Saúde' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Educação', 'expense', 'book', '#8b5cf6', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Educação' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Assinaturas', 'expense', 'repeat', '#06b6d4', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Assinaturas' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Lazer', 'expense', 'smile', '#14b8a6', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Lazer' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Impostos', 'expense', 'receipt', '#64748b', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Impostos' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Outros', 'expense', 'tag', '#64748b', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Outros' AND type = 'expense');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Salário', 'income', 'briefcase', '#16a34a', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Salário' AND type = 'income');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Vendas', 'income', 'shopping-bag', '#22c55e', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Vendas' AND type = 'income');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Serviços', 'income', 'briefcase', '#84cc16', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Serviços' AND type = 'income');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Comissões', 'income', 'percent', '#10b981', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Comissões' AND type = 'income');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Rendimentos', 'income', 'trending-up', '#0ea5e9', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Rendimentos' AND type = 'income');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Reembolso', 'income', 'rotate-ccw', '#6366f1', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Reembolso' AND type = 'income');

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Outros', 'income', 'tag', '#64748b', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Outros' AND type = 'income');

INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Pessoal', 'PES', 'Despesas e receitas pessoais', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Pessoal');

INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Casa', 'CAS', 'Moradia e manutenção', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Casa');

INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Empresa', 'EMP', 'Operação do negócio', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Empresa');

INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Carro', 'CAR', 'Veículo e transporte', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Carro');

INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Operacional', 'OPE', 'Custos operacionais gerais', 'active' 
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Operacional');
