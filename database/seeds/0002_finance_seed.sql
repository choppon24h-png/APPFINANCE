-- ============================================================
-- APPFINANCE — Dados auxiliares padrão
-- Somente categorias e centros de custo genéricos; sem dados reais.
-- ============================================================

INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Alimentação', 'expense', 'utensils', '#ef4444', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Alimentação' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Supermercado', 'expense', 'shopping-cart', '#f97316', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Supermercado' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Moradia', 'expense', 'home', '#eab308', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Moradia' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Transporte', 'expense', 'car', '#d97706', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Transporte' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Saúde', 'expense', 'heart', '#ec4899', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Saúde' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Educação', 'expense', 'book', '#8b5cf6', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Educação' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Assinaturas', 'expense', 'repeat', '#06b6d4', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Assinaturas' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Lazer', 'expense', 'smile', '#14b8a6', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Lazer' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Impostos', 'expense', 'receipt', '#64748b', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Impostos' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Outros', 'expense', 'tag', '#64748b', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Outros' AND type = 'expense');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Salário', 'income', 'briefcase', '#16a34a', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Salário' AND type = 'income');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Vendas', 'income', 'shopping-bag', '#22c55e', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Vendas' AND type = 'income');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Serviços', 'income', 'briefcase', '#84cc16', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Serviços' AND type = 'income');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Comissões', 'income', 'percent', '#10b981', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Comissões' AND type = 'income');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Rendimentos', 'income', 'trending-up', '#0ea5e9', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Rendimentos' AND type = 'income');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Reembolso', 'income', 'rotate-ccw', '#6366f1', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Reembolso' AND type = 'income');
INSERT INTO categories (user_id, name, type, icon, color, status)
SELECT NULL, 'Outros', 'income', 'tag', '#64748b', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE user_id IS NULL AND name = 'Outros' AND type = 'income');

INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Pessoal', 'PES', 'Despesas e receitas pessoais', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Pessoal');
INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Casa', 'CAS', 'Moradia e manutenção', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Casa');
INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Empresa', 'EMP', 'Operação do negócio', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Empresa');
INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Carro', 'CAR', 'Veículo e transporte', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Carro');
INSERT INTO cost_centers (user_id, name, code, description, status)
SELECT NULL, 'Operacional', 'OPE', 'Custos operacionais gerais', 'active' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM cost_centers WHERE user_id IS NULL AND name = 'Operacional');
