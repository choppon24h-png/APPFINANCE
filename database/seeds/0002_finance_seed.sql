-- ============================================================
-- APPFINANCE — Dados auxiliares padrão
-- Somente categorias e centros de custo genéricos; sem dados reais.
-- ============================================================

INSERT IGNORE INTO categories (user_id, name, type, icon, color, status) VALUES
(NULL, 'Alimentação', 'expense', 'utensils', '#ef4444', 'active'),
(NULL, 'Supermercado', 'expense', 'shopping-cart', '#f97316', 'active'),
(NULL, 'Moradia', 'expense', 'home', '#eab308', 'active'),
(NULL, 'Transporte', 'expense', 'car', '#d97706', 'active'),
(NULL, 'Saúde', 'expense', 'heart', '#ec4899', 'active'),
(NULL, 'Educação', 'expense', 'book', '#8b5cf6', 'active'),
(NULL, 'Assinaturas', 'expense', 'repeat', '#06b6d4', 'active'),
(NULL, 'Lazer', 'expense', 'smile', '#14b8a6', 'active'),
(NULL, 'Impostos', 'expense', 'receipt', '#64748b', 'active'),
(NULL, 'Outros', 'expense', 'tag', '#64748b', 'active'),
(NULL, 'Salário', 'income', 'briefcase', '#16a34a', 'active'),
(NULL, 'Vendas', 'income', 'shopping-bag', '#22c55e', 'active'),
(NULL, 'Serviços', 'income', 'briefcase', '#84cc16', 'active'),
(NULL, 'Comissões', 'income', 'percent', '#10b981', 'active'),
(NULL, 'Rendimentos', 'income', 'trending-up', '#0ea5e9', 'active'),
(NULL, 'Reembolso', 'income', 'rotate-ccw', '#6366f1', 'active'),
(NULL, 'Outros', 'income', 'tag', '#64748b', 'active');

INSERT IGNORE INTO cost_centers (user_id, name, code, description, status) VALUES
(NULL, 'Pessoal', 'PES', 'Despesas e receitas pessoais', 'active'),
(NULL, 'Casa', 'CAS', 'Moradia e manutenção', 'active'),
(NULL, 'Empresa', 'EMP', 'Operação do negócio', 'active'),
(NULL, 'Carro', 'CAR', 'Veículo e transporte', 'active'),
(NULL, 'Operacional', 'OPE', 'Custos operacionais gerais', 'active');
