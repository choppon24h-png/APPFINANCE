-- ============================================================
-- SOMASE — Controle Financeiro
-- Seed OPCIONAL de demonstracao (nao roda no instalador padrao).
-- Use apenas em ambiente de teste/homologacao:
--   /_instalar.php?key=SEU_APP_SECRET&demo=1
--
-- Regras de seguranca:
--  * so insere se o usuario admin@example.com ainda nao tiver contas;
--  * todos os lancamentos recebem a marca 'SOMASE demo' em notes;
--  * pode ser reaplicado sem duplicar registros.
-- ============================================================

SET @uid := (SELECT id FROM users WHERE email = 'admin@example.com' LIMIT 1);

-- ---------- contas ----------
INSERT INTO accounts (user_id, name, bank_name, account_type, agency, account_number, initial_balance, current_balance, initial_date, status, notes)
SELECT @uid, 'Conta Corrente', 'Banco do Brasil', 'checking', '1234', '56789-0', 4200.00, 4200.00,
       DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 7 MONTH), 'active', 'SOMASE demo'
FROM DUAL
WHERE @uid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM accounts WHERE user_id = @uid);

INSERT INTO accounts (user_id, name, bank_name, account_type, agency, account_number, initial_balance, current_balance, initial_date, status, notes)
SELECT @uid, 'Reserva de emergencia', 'Nubank', 'savings', NULL, '0001', 12000.00, 12000.00,
       DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 7 MONTH), 'active', 'SOMASE demo'
FROM DUAL
WHERE @uid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM accounts WHERE user_id = @uid AND name = 'Reserva de emergencia');

SET @acc1 := (SELECT id FROM accounts WHERE user_id = @uid ORDER BY id LIMIT 1);
SET @acc2 := (SELECT id FROM accounts WHERE user_id = @uid AND id <> @acc1 ORDER BY id LIMIT 1);

-- ---------- lancamentos dos ultimos 6 meses ----------
INSERT INTO transactions
    (user_id, account_id, category_id, cost_center_id, type, description, amount,
     transaction_date, due_date, payment_date, status, payment_method, notes)
SELECT @uid, @acc1, c.id, NULL, d.type, d.description,
       ROUND(d.base + (m.n * d.step), 2),
       DATE_ADD(DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL m.n MONTH), INTERVAL (d.day - 1) DAY),
       DATE_ADD(DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL m.n MONTH), INTERVAL (d.day + 4) DAY),
       CASE WHEN d.status = 'paid' OR d.status = 'received'
            THEN DATE_ADD(DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL m.n MONTH), INTERVAL (d.day - 1) DAY)
            ELSE NULL END,
       CASE WHEN d.status = 'pending' AND m.n > 0 THEN 'paid' ELSE d.status END,
       d.method, 'SOMASE demo'
FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
      UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11) m
JOIN (
    SELECT 'expense' AS type, 'Supermercado do mes' AS description, 720.00 AS base, 32.00 AS step, 'Supermercado' AS category, 'paid' AS status, 8 AS day, 'pix' AS method
    UNION ALL SELECT 'expense', 'Aluguel', 2400.00, 0.00, 'Moradia', 'pending', 5, 'boleto'
    UNION ALL SELECT 'expense', 'Energia eletrica', 215.00, 12.00, 'Moradia', 'paid', 15, 'debit'
    UNION ALL SELECT 'expense', 'Assinaturas digitais', 89.90, 0.00, 'Assinaturas', 'paid', 20, 'credit'
    UNION ALL SELECT 'expense', 'Combustivel', 380.00, 26.00, 'Transporte', 'paid', 22, 'debit'
    UNION ALL SELECT 'expense', 'Plano de saude', 640.00, 0.00, 'Saúde', 'paid', 12, 'boleto'
    UNION ALL SELECT 'income', 'Salario mensal', 7800.00, 120.00, 'Salário', 'received', 5, 'transfer'
    UNION ALL SELECT 'income', 'Projeto freelance', 1350.00, 180.00, 'Serviços', 'received', 18, 'pix'
) d
JOIN (SELECT MIN(id) AS id, name FROM categories WHERE user_id IS NULL OR user_id = @uid GROUP BY name) c
  ON c.name = d.category
WHERE @uid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = @uid);

-- ---------- proximos vencimentos (30 dias) ----------
-- Alimenta o painel "Proximos 30 dias" e o botao "marcar como pago".
INSERT INTO transactions
    (user_id, account_id, category_id, cost_center_id, type, description, amount,
     transaction_date, due_date, payment_date, status, payment_method, notes)
SELECT @uid, @acc1, c.id, NULL, d.type, d.description, d.amount,
       CURDATE(), DATE_ADD(CURDATE(), INTERVAL d.dias DAY), NULL, d.status, d.method, 'SOMASE demo'
FROM (
    SELECT 'expense' AS type, 'Aluguel do proximo mes' AS description, 2400.00 AS amount, 'Moradia' AS category, 'pending' AS status, 6 AS dias, 'boleto' AS method
    UNION ALL SELECT 'expense', 'Fatura do cartao', 1380.45, 'Outros', 'pending', 12, 'credit'
    UNION ALL SELECT 'expense', 'Plano de saude', 640.00, 'Saúde', 'pending', 18, 'boleto'
    UNION ALL SELECT 'income', 'Projeto freelance (2a parcela)', 1350.00, 'Serviços', 'expected', 21, 'pix'
    UNION ALL SELECT 'expense', 'Assinaturas digitais', 89.90, 'Assinaturas', 'pending', 25, 'credit'
) d
JOIN (SELECT MIN(id) AS id, name FROM categories WHERE user_id IS NULL OR user_id = @uid GROUP BY name) c
  ON c.name = d.category
WHERE @uid IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM transactions WHERE user_id = @uid AND notes = 'SOMASE demo' AND status IN ('pending','expected') AND due_date >= CURDATE());

-- ---------- investimentos ----------
INSERT INTO investments
    (user_id, account_id, institution, investment_type, name, amount_invested, application_date,
     interest_rate, rate_type, benchmark, liquidity, maturity_date, status, notes)
SELECT @uid, @acc1, 'XP Investimentos', 'cdb', 'CDB Liquidez Diaria', 15000.00,
       DATE_SUB(CURDATE(), INTERVAL 5 MONTH), 11.500000, 'annual', 'cdi', 'diaria',
       DATE_ADD(CURDATE(), INTERVAL 18 MONTH), 'active', 'SOMASE demo'
FROM DUAL
WHERE @uid IS NOT NULL AND @acc1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM investments WHERE user_id = @uid);

INSERT INTO investments
    (user_id, account_id, institution, investment_type, name, amount_invested, application_date,
     interest_rate, rate_type, benchmark, liquidity, maturity_date, status, notes)
SELECT @uid, @acc1, 'Tesouro Direto', 'tesouro', 'Tesouro Selic 2029', 8000.00,
       DATE_SUB(CURDATE(), INTERVAL 4 MONTH), 10.750000, 'annual', 'selic', 'd1',
       DATE_ADD(CURDATE(), INTERVAL 30 MONTH), 'active', 'SOMASE demo'
FROM DUAL
WHERE @uid IS NOT NULL AND @acc1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM investments WHERE user_id = @uid AND name = 'Tesouro Selic 2029');

-- ---------- rendimentos dos ultimos 3 meses ----------
INSERT INTO investment_returns (investment_id, reference_month, reference_year, initial_value, return_amount, return_percentage, final_value)
SELECT i.id,
       MONTH(DATE_SUB(CURDATE(), INTERVAL m.n MONTH)),
       YEAR(DATE_SUB(CURDATE(), INTERVAL m.n MONTH)),
       i.amount_invested,
       ROUND(i.amount_invested * (0.0085 + (m.n * 0.0004)), 2),
       ROUND((0.0085 + (m.n * 0.0004)) * 100, 6),
       ROUND(i.amount_invested * (1 + 0.0085 + (m.n * 0.0004)), 2)
FROM investments i
JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2) m
WHERE i.user_id = @uid
  AND i.notes = 'SOMASE demo'
  AND NOT EXISTS (SELECT 1 FROM investment_returns r WHERE r.investment_id = i.id);

-- ---------- saldo coerente com os lancamentos ----------
UPDATE accounts a
SET a.current_balance = ROUND(
        a.initial_balance
        + COALESCE((SELECT SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE -t.amount END)
                    FROM transactions t
                    WHERE t.account_id = a.id AND t.user_id = @uid
                      AND t.status IN ('paid', 'received')), 0)
        - COALESCE((SELECT SUM(i.amount_invested) FROM investments i WHERE i.account_id = a.id AND i.user_id = @uid), 0), 2)
WHERE a.user_id = @uid AND a.notes = 'SOMASE demo';
