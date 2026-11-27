<?php
/**
 * SOMASE — Controle Financeiro
 * Instalador / atualizador de banco via navegador (hospedagem compartilhada).
 *
 * Executa, em ordem alfabetica, todas as migrations e seeds versionados
 * (database/migrations e database/seeds) no banco configurado no .env.
 * Os arquivos sao idempotentes: podem ser reaplicados com seguranca para
 * atualizar um banco existente.
 *
 * Acesso: https://seu-dominio.com/_instalar.php?key=SEU_APP_SECRET
 * Demo opcional: ...?_instalar.php?key=...&demo=1 (carrega database/seeds/demo)
 *
 * IMPORTANTE: apague este arquivo do servidor depois de instalar.
 */

define('BASE_PATH', dirname(__DIR__));

$envFile = BASE_PATH . '/.env';
if (!file_exists($envFile)) {
    die('Arquivo .env nao encontrado. Copie .env.example para .env, configure o banco de dados e tente novamente.');
}

foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    if (strpos(trim($line), '#') === 0) continue;
    if (strpos($line, '=') === false) continue;
    [$key, $val] = explode('=', $line, 2);
    $_ENV[trim($key)] = trim($val, " \t\n\r\0\x0B\"'");
}

$appSecret = $_ENV['APP_SECRET'] ?? '';
if ($appSecret === '' || $appSecret === 'troque_por_uma_chave_aleatoria_de_32_chars') {
    die('Defina um APP_SECRET real no .env antes de usar o instalador.');
}
if (!hash_equals($appSecret, (string) ($_GET['key'] ?? ''))) {
    http_response_code(403);
    die('Acesso negado. Use ?key=SEU_APP_SECRET (o valor de APP_SECRET no .env).');
}

$comDemo = ($_GET['demo'] ?? '') === '1';

try {
    $pdo = new PDO(
        "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD'],
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Exception $e) {
    die('<h2 style="color:#ff5d73;font-family:system-ui">Erro de conexao com o banco: ' . htmlspecialchars($e->getMessage()) . '</h2>');
}

/**
 * Executa um arquivo .sql statement-a-statement (split simples por ";").
 * Suficiente para os arquivos deste projeto (sem procedures/triggers).
 */
function executarArquivoSql(PDO $pdo, string $path): array
{
    if (!file_exists($path)) {
        return ['arquivo' => basename($path), 'ok' => 0, 'erros' => ['Arquivo nao encontrado']];
    }

    $sql = file_get_contents($path);
    $sql = preg_replace('/^--.*$/m', '', $sql);
    $statements = array_filter(array_map('trim', explode(';', $sql)));

    $ok = 0;
    $erros = [];
    foreach ($statements as $stmt) {
        if ($stmt === '') continue;
        try {
            $pdo->exec($stmt);
            $ok++;
        } catch (Throwable $e) {
            // Reaplicar migrations gera erros benignos de "ja existe".
            // Eles nao indicam falha: o banco ja esta atualizado.
            $msg = $e->getMessage();
            if (preg_match('/duplicate column|duplicate key name|already exists|Duplicate entry/i', $msg)) {
                $ok++;
                continue;
            }
            $resumo = strlen($stmt) > 110 ? substr($stmt, 0, 110) . '...' : $stmt;
            $erros[] = $msg . ' :: ' . $resumo;
        }
    }

    return ['arquivo' => basename($path), 'ok' => $ok, 'erros' => $erros];
}

$resultados = [];
$migrations = glob(BASE_PATH . '/database/migrations/*.sql') ?: [];
$seeds = glob(BASE_PATH . '/database/seeds/*.sql') ?: [];
$demoSeeds = $comDemo ? (glob(BASE_PATH . '/database/seeds/demo/*.sql') ?: []) : [];

foreach (array_merge($migrations, $seeds, $demoSeeds) as $arquivo) {
    $resultados[] = executarArquivoSql($pdo, $arquivo);
}

$totalOk = array_sum(array_column($resultados, 'ok'));
$totalErros = array_sum(array_map(static fn($r) => count($r['erros']), $resultados));

// Verificacao do esquema esperado (tabelas e colunas criticas)
$schemaEsperado = [
    'roles' => ['id', 'slug', 'name'],
    'permissions' => ['id', 'slug', 'name'],
    'users' => ['id', 'name', 'email', 'password', 'role_id', 'status'],
    'accounts' => ['id', 'user_id', 'name', 'account_type', 'initial_balance', 'current_balance', 'initial_date', 'status'],
    'categories' => ['id', 'user_id', 'name', 'type', 'color', 'status'],
    'cost_centers' => ['id', 'user_id', 'name', 'status'],
    'transactions' => ['id', 'user_id', 'account_id', 'category_id', 'cost_center_id', 'type', 'description', 'amount', 'transaction_date', 'due_date', 'payment_date', 'status', 'recurrence_id', 'recurrence_key', 'transfer_id'],
    'recurring_transactions' => ['id', 'user_id', 'account_id', 'type', 'description', 'amount', 'frequency', 'start_date', 'next_date', 'status'],
    'investments' => ['id', 'user_id', 'account_id', 'institution', 'investment_type', 'name', 'amount_invested', 'application_date', 'status'],
    'investment_returns' => ['id', 'investment_id', 'reference_month', 'reference_year', 'return_amount', 'return_percentage'],
    'investment_movements' => ['id', 'investment_id', 'type', 'amount', 'movement_date'],
    'account_movements' => ['id', 'account_id', 'transaction_id', 'movement_type', 'amount', 'movement_date'],
    'audit_logs' => ['id', 'user_id', 'action', 'entity'],
];
$tabelas = [];
foreach ($pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN) as $tabela) {
    $tabelas[$tabela] = true;
}
$schema = [];
foreach ($schemaEsperado as $tabela => $colunas) {
    if (!isset($tabelas[$tabela])) {
        $schema[$tabela] = ['existe' => false, 'faltando' => $colunas];
        continue;
    }
    $existentes = $pdo->query("SHOW COLUMNS FROM `{$tabela}`")->fetchAll(PDO::FETCH_COLUMN);
    $schema[$tabela] = ['existe' => true, 'faltando' => array_values(array_diff($colunas, $existentes))];
}
$schemaOk = !array_filter($schema, static fn($t) => !$t['existe'] || $t['faltando']);
$tudoOk = $totalErros === 0 && $schemaOk;
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#07101f">
    <title>SOMASE — Instalador de banco</title>
    <link rel="icon" href="/favicon.ico" sizes="any">
    <link rel="icon" type="image/png" sizes="32x32" href="/assets/icons/favicon-32.png">
    <link href="/assets/css/app.css" rel="stylesheet">
    <style>
        body { padding: 28px 16px 60px; }
        .wrap { width: min(100%, 940px); margin: 0 auto; }
        .top { display: flex; align-items: center; gap: 14px; margin-bottom: 22px; }
        .top img { height: 40px; width: auto; }
        .top h1 { margin: 0; font-size: 20px; }
        .top p { margin: 2px 0 0; color: var(--muted); font-size: 12px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; margin-bottom: 16px; }
        .stat { padding: 14px; border: 1px solid var(--line); border-radius: 12px; background: var(--surface); }
        .stat span { display: block; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .08em; font-weight: 700; }
        .stat strong { display: block; margin-top: 4px; font-size: 22px; letter-spacing: -.03em; }
        .stat.ok strong { color: var(--positive); }
        .stat.err strong { color: var(--negative); }
        .box { padding: 18px; border: 1px solid var(--line); border-radius: 14px; background: var(--surface); margin-bottom: 14px; }
        .box h2 { margin: 0 0 12px; font-size: 15px; }
        .box table { width: 100%; border-collapse: collapse; font-size: 12px; }
        .box th { text-align: left; padding: 6px 8px; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; border-bottom: 1px solid var(--line); }
        .box td { padding: 7px 8px; border-bottom: 1px solid var(--line-soft); }
        .box tr:last-child td { border-bottom: 0; }
        .tag { display: inline-flex; padding: 2px 8px; border-radius: 999px; font-size: 10px; font-weight: 700; border: 1px solid transparent; }
        .tag-ok { color: #a8f0b2; background: var(--positive-soft); border-color: var(--positive-line); }
        .tag-err { color: #ffb3bf; background: var(--negative-soft); border-color: var(--negative-line); }
        code { font-size: 11px; color: var(--muted-2); word-break: break-word; }
        .erro { padding: 10px 12px; margin-top: 8px; border-left: 3px solid var(--negative); border-radius: 5px; background: var(--negative-soft); font-size: 11.5px; color: #ffc2cb; }
        .actions { display: flex; flex-wrap: wrap; gap: 9px; margin-top: 18px; }
        .note { color: var(--muted); font-size: 11.5px; line-height: 1.6; }
        .note strong { color: var(--text); }
    </style>
</head>
<body>
<div class="wrap">
    <div class="top">
        <img src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE" width="232" height="78">
        <div>
            <h1>Instalador de banco</h1>
            <p>Atualiza o banco <code><?= htmlspecialchars((string) ($_ENV['DB_DATABASE'] ?? '')) ?></code> com as migrations e seeds do projeto.</p>
        </div>
    </div>

    <div class="stats">
        <div class="stat"><span>Arquivos executados</span><strong><?= count($resultados) ?></strong></div>
        <div class="stat ok"><span>Comandos aplicados</span><strong><?= (int) $totalOk ?></strong></div>
        <div class="stat <?= $totalErros > 0 ? 'err' : '' ?>"><span>Erros</span><strong><?= (int) $totalErros ?></strong></div>
        <div class="stat <?= $schemaOk ? 'ok' : 'err' ?>"><span>Esquema</span><strong><?= $schemaOk ? 'OK' : 'PENDENTE' ?></strong></div>
    </div>

    <div class="box">
        <h2>Arquivos processados</h2>
        <table>
            <thead><tr><th>Arquivo</th><th style="width:90px">Comandos</th><th style="width:80px">Status</th></tr></thead>
            <tbody>
            <?php foreach ($resultados as $r): ?>
                <tr>
                    <td><code><?= htmlspecialchars($r['arquivo']) ?></code></td>
                    <td><?= (int) $r['ok'] ?></td>
                    <td><span class="tag <?= $r['erros'] ? 'tag-err' : 'tag-ok' ?>"><?= $r['erros'] ? count($r['erros']) . ' erro(s)' : 'ok' ?></span></td>
                </tr>
            <?php endforeach; ?>
            <?php if (!$resultados): ?>
                <tr><td colspan="3" class="note">Nenhum arquivo .sql encontrado em database/migrations ou database/seeds.</td></tr>
            <?php endif; ?>
            </tbody>
        </table>
        <?php foreach ($resultados as $r): foreach ($r['erros'] as $erro): ?>
            <div class="erro"><strong><?= htmlspecialchars($r['arquivo']) ?>:</strong> <?= htmlspecialchars($erro) ?></div>
        <?php endforeach; endforeach; ?>
    </div>

    <div class="box">
        <h2>Verificacao do esquema</h2>
        <table>
            <thead><tr><th>Tabela</th><th style="width:110px">Situacao</th><th>Colunas ausentes</th></tr></thead>
            <tbody>
            <?php foreach ($schema as $tabela => $info): ?>
                <tr>
                    <td><code><?= htmlspecialchars($tabela) ?></code></td>
                    <td><span class="tag <?= ($info['existe'] && !$info['faltando']) ? 'tag-ok' : 'tag-err' ?>"><?= $info['existe'] ? ($info['faltando'] ? 'incompleta' : 'ok') : 'ausente' ?></span></td>
                    <td><?= $info['faltando'] ? '<code>' . htmlspecialchars(implode(', ', $info['faltando'])) . '</code>' : '—' ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <div class="box">
        <h2><?= $tudoOk ? 'Banco atualizado' : 'Atencao' ?></h2>
        <?php if ($tudoOk): ?>
            <p class="note">
                <strong>Instalacao concluida.</strong> As tabelas, colunas e indices esperados estao presentes.<br>
                Login inicial: <code>admin@example.com</code> / <code>Admin@123</code> — troque a senha no primeiro acesso.
            </p>
            <?php if (!$comDemo): ?>
                <p class="note">Quer ver o dashboard com dados de exemplo? Rode com <code>&amp;demo=1</code> (cria dados fictícios para o usuario admin).</p>
            <?php endif; ?>
        <?php else: ?>
            <p class="note">Alguns comandos falharam ou o esquema esta incompleto. Revise os erros acima antes de usar o sistema em producao.</p>
        <?php endif; ?>
        <div class="actions">
            <a class="button button-primary" href="/login">Ir para o login</a>
            <a class="button button-ghost" href="/_diagnostico.php?key=<?= urlencode($appSecret) ?>">Abrir diagnostico</a>
        </div>
        <p class="note" style="margin-top:14px;color:#ffb3bf">Apague <code>public/_instalar.php</code> do servidor depois de usar.</p>
    </div>
</div>
</body>
</html>
