-- =====================================================================
-- SOMASE — Diagnóstico de usuários x dados (somente leitura)
--
-- Use quando aparecer:
--   SQLSTATE[23000]: Integrity constraint violation: 1452
--   Cannot add or update a child row: a foreign key constraint fails
--   (`...`.`accounts`, CONSTRAINT `fk_accounts_user` FOREIGN KEY (`user_id`)
--    REFERENCES `users` (`id`) ON DELETE CASCADE)
--
-- Esse erro significa que o user_id gravado na sessão não existe na tabela
-- users — normalmente porque o banco foi reimportado e os IDs mudaram,
-- enquanto o navegador continuou com o cookie antigo.
--
-- Nada aqui altera dados: são apenas consultas. Rode no phpMyAdmin, na aba
-- SQL, com o banco selecionado.
-- =====================================================================

-- 1. Usuários que existem hoje (id, nome, e-mail, perfil, status)
SELECT u.id, u.name, u.email, r.slug AS perfil, u.status, u.created_at
FROM users u
JOIN roles r ON r.id = u.role_id
ORDER BY u.id;

-- 2. Quanto cada usuário tem em cada tabela
SELECT u.id, u.name, u.email,
       (SELECT COUNT(*) FROM accounts      a WHERE a.user_id = u.id) AS contas,
       (SELECT COUNT(*) FROM transactions  t WHERE t.user_id = u.id) AS lancamentos,
       (SELECT COUNT(*) FROM investments   i WHERE i.user_id = u.id) AS investimentos,
       (SELECT COUNT(*) FROM cost_centers  c WHERE c.user_id = u.id) AS centros_custo,
       (SELECT COUNT(*) FROM categories    g WHERE g.user_id = u.id) AS categorias
FROM users u
ORDER BY u.id;

-- 3. Dados órfãos: linhas cujo user_id não existe mais em users
SELECT 'accounts' AS tabela, user_id, COUNT(*) AS linhas
FROM accounts WHERE user_id NOT IN (SELECT id FROM users) GROUP BY user_id
UNION ALL
SELECT 'transactions', user_id, COUNT(*) FROM transactions WHERE user_id NOT IN (SELECT id FROM users) GROUP BY user_id
UNION ALL
SELECT 'investments', user_id, COUNT(*) FROM investments WHERE user_id NOT IN (SELECT id FROM users) GROUP BY user_id
UNION ALL
SELECT 'cost_centers', user_id, COUNT(*) FROM cost_centers WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users) GROUP BY user_id
UNION ALL
SELECT 'categories', user_id, COUNT(*) FROM categories WHERE user_id IS NOT NULL AND user_id NOT IN (SELECT id FROM users) GROUP BY user_id;

-- 4. Sessões não ficam no banco: para encerrar a sessão antiga, o usuário
--    precisa sair e entrar novamente (o sistema faz isso sozinho na próxima
--    página, com a mensagem "Sua sessão era de um banco anterior").
--
-- 5. Se houver dados órfãos de um usuário que voltou a existir com outro id,
--    o vínculo pode ser refeito manualmente (exemplo comentado):
--
--    -- UPDATE accounts      SET user_id = 7 WHERE user_id = 5;
--    -- UPDATE transactions  SET user_id = 7 WHERE user_id = 5;
--    -- UPDATE investments   SET user_id = 7 WHERE user_id = 5;
--    -- UPDATE cost_centers  SET user_id = 7 WHERE user_id = 5;
--    -- UPDATE categories    SET user_id = 7 WHERE user_id = 5;
--
--    Troque 7 pelo id do usuário novo e 5 pelo id antigo, confira o resultado
--    do item 3 antes e depois. Faça backup do banco antes de qualquer UPDATE.
