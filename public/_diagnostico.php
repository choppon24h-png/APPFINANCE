<?php
/**
 * SOMASE — Controle Financeiro
 * Diagnostico de ambiente, banco e assets (hospedagem compartilhada).
 *
 * Acesso: https://seu-dominio.com/_diagnostico.php?key=SEU_APP_SECRET
 *
 * IMPORTANTE: apague este arquivo do servidor depois de usar.
 */

$base = dirname(__DIR__);

$envFile = $base . '/.env';
if (!file_exists($envFile)) {
    die('Arquivo .env nao encontrado.');
}
foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    if (strpos(trim($line), '#') === 0) continue;
    if (strpos($line, '=') === false) continue;
    [$key, $val] = explode('=', $line, 2);
    $_ENV[trim($key)] = trim($val, " \t\n\r\0\x0B\"'");
}

$appSecret = $_ENV['APP_SECRET'] ?? '';
if ($appSecret === '' || !hash_equals($appSecret, (string) ($_GET['key'] ?? ''))) {
    http_response_code(403);
    die('Acesso negado. Use ?key=SEU_APP_SECRET (o valor de APP_SECRET no .env).');
}

require_once $base . '/app/autoload.php';

ini_set('display_errors', 1);
error_reporting(E_ALL);

$linhas = [];
$adicionar = static function (string $grupo, string $item, string $status, string $detalhe = '') use (&$linhas): void {
    $linhas[$grupo][] = ['item' => $item, 'status' => $status, 'detalhe' => $detalhe];
};

// 1. Ambiente
$adicionar('Ambiente', 'Versao do PHP', version_compare(PHP_VERSION, '8.1.0', '>=') ? 'ok' : 'erro', PHP_VERSION . ' (minimo 8.1)');
$adicionar('Ambiente', 'SAPI', 'info', php_sapi_name());
foreach (['pdo', 'pdo_mysql', 'mbstring', 'json', 'fileinfo', 'openssl'] as $ext) {
    $adicionar('Ambiente', 'Extensao ' . $ext, extension_loaded($ext) ? 'ok' : 'erro');
}

// 2. Diretorios
foreach ([$base . '/storage', $base . '/storage/logs', $base . '/storage/sessions', $base . '/storage/uploads'] as $dir) {
    if (!is_dir($dir)) {
        $adicionar('Permissoes', basename($dir), 'erro', 'diretorio inexistente');
    } else {
        $adicionar('Permissoes', basename($dir), is_writable($dir) ? 'ok' : 'erro', is_writable($dir) ? 'gravavel' : 'sem permissao de escrita (755)');
    }
}

// 3. Banco de dados
$contagens = [];
try {
    $pdo = \App\Core\Database::getInstance();
    $adicionar('Banco', 'Conexao', 'ok', (string) ($_ENV['DB_DATABASE'] ?? ''));
    $tabelas = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
    $esperadas = [
        'roles' => ['id', 'slug', 'name'],
        'permissions' => ['id', 'slug', 'name'],
        'users' => ['id', 'name', 'email', 'password', 'role_id', 'status'],
        'accounts' => ['id', 'user_id', 'name', 'account_type', 'current_balance', 'initial_date', 'status'],
        'categories' => ['id', 'user_id', 'name', 'type', 'color', 'status'],
        'cost_centers' => ['id', 'user_id', 'name', 'status'],
        'transactions' => ['id', 'user_id', 'account_id', 'type', 'description', 'amount', 'transaction_date', 'due_date', 'status', 'recurrence_id', 'transfer_id'],
        'recurring_transactions' => ['id', 'user_id', 'account_id', 'frequency', 'start_date', 'next_date', 'status'],
        'investments' => ['id', 'user_id', 'account_id', 'institution', 'name', 'amount_invested', 'status'],
        'investment_returns' => ['id', 'investment_id', 'reference_month', 'reference_year', 'return_amount'],
        'investment_movements' => ['id', 'investment_id', 'type', 'amount', 'movement_date'],
        'account_movements' => ['id', 'account_id', 'movement_type', 'amount', 'movement_date'],
        'audit_logs' => ['id', 'user_id', 'action', 'entity'],
    ];
    foreach ($esperadas as $tabela => $colunas) {
        if (!in_array($tabela, $tabelas, true)) {
            $adicionar('Esquema', $tabela, 'erro', 'tabela ausente — rode /_instalar.php');
            continue;
        }
        $existentes = $pdo->query("SHOW COLUMNS FROM `{$tabela}`")->fetchAll(PDO::FETCH_COLUMN);
        $faltando = array_diff($colunas, $existentes);
        $adicionar('Esquema', $tabela, $faltando ? 'erro' : 'ok', $faltando ? 'faltam: ' . implode(', ', $faltando) : 'colunas ok');
    }
    foreach (['users', 'accounts', 'transactions', 'investments'] as $tabela) {
        if (in_array($tabela, $tabelas, true)) {
            $contagens[$tabela] = (int) $pdo->query("SELECT COUNT(*) FROM `{$tabela}`")->fetchColumn();
        }
    }
} catch (\Throwable $e) {
    $adicionar('Banco', 'Conexao', 'erro', $e->getMessage());
}

// 4. Assets de marca
$assets = [
    'assets/brand/somase-logo-horizontal-light.png',
    'assets/brand/somase-logo-horizontal.png',
    'assets/brand/somase-wordmark-light.png',
    'assets/brand/somase-wordmark.png',
    'assets/brand/somase-icon.png',
    'assets/icons/icon-192.png',
    'assets/icons/icon-512.png',
    'assets/icons/icon-maskable-512.png',
    'assets/icons/apple-touch-icon.png',
    'assets/icons/favicon-32.png',
    'favicon.ico',
    'manifest.json',
    'sw.js',
];
foreach ($assets as $asset) {
    $caminho = $base . '/public/' . $asset;
    $adicionar('Assets', $asset, file_exists($caminho) ? 'ok' : 'erro', file_exists($caminho) ? round(filesize($caminho) / 1024) . ' KB' : 'arquivo ausente');
}

// 5. Versoes de banco
$migrations = glob($base . '/database/migrations/*.sql') ?: [];
$seeds = glob($base . '/database/seeds/*.sql') ?: [];
$demoSeeds = glob($base . '/database/seeds/demo/*.sql') ?: [];
$adicionar('Arquivos SQL', 'Migrations', 'info', count($migrations) . ' arquivo(s)');
$adicionar('Arquivos SQL', 'Seeds', 'info', count($seeds) . ' arquivo(s)');
$adicionar('Arquivos SQL', 'Seeds de demonstracao', 'info', count($demoSeeds) . ' arquivo(s)');

$erros = 0;
foreach ($linhas as $grupo) {
    foreach ($grupo as $linha) {
        if ($linha['status'] === 'erro') $erros++;
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#07101f">
    <meta name="robots" content="noindex, nofollow">
    <title>SOMASE — Diagnostico</title>
    <link rel="icon" href="/favicon.ico" sizes="any">
    <link rel="icon" type="image/png" sizes="32x32" href="/assets/icons/favicon-32.png">
    <link href="/assets/css/app.css" rel="stylesheet">
    <style>
        body { padding: 28px 16px 60px; }
        .wrap { width: min(100%, 980px); margin: 0 auto; }
        .top { display: flex; align-items: center; gap: 14px; margin-bottom: 20px; flex-wrap: wrap; }
        .top img { height: 40px; width: auto; }
        .top h1 { margin: 0; font-size: 20px; }
        .top p { margin: 2px 0 0; color: var(--muted); font-size: 12px; }
        .resumo { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 16px; }
        .pill { padding: 8px 13px; border: 1px solid var(--line); border-radius: 999px; background: var(--surface); font-size: 12px; }
        .pill.ok { border-color: var(--positive-line); color: #b8f0c4; background: var(--positive-soft); }
        .pill.err { border-color: var(--negative-line); color: #ffc2cb; background: var(--negative-soft); }
        .grupo { margin-bottom: 14px; padding: 16px 18px; border: 1px solid var(--line); border-radius: 14px; background: var(--surface); }
        .grupo h2 { margin: 0 0 10px; font-size: 14px; }
        .grupo table { width: 100%; border-collapse: collapse; font-size: 12px; }
        .grupo th { text-align: left; padding: 5px 8px; color: var(--muted); font-size: 10px; text-transform: uppercase; letter-spacing: .06em; border-bottom: 1px solid var(--line); }
        .grupo td { padding: 6px 8px; border-bottom: 1px solid var(--line-soft); vertical-align: top; }
        .grupo tr:last-child td { border-bottom: 0; }
        .st { font-weight: 800; font-size: 10px; letter-spacing: .04em; }
        .st-ok { color: var(--positive); }
        .st-erro { color: var(--negative); }
        .st-info { color: var(--brand-blue-2); }
        code { font-size: 11px; color: var(--muted-2); }
        .acoes { display: flex; gap: 9px; flex-wrap: wrap; margin-top: 18px; }
    </style>
</head>
<body>
<div class="wrap">
    <div class="top">
        <img src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE" width="232" height="78">
        <div>
            <h1>Diagnostico do ambiente</h1>
            <p>PHP, permissoes, banco de dados, esquema e assets de marca.</p>
        </div>
    </div>

    <div class="resumo">
        <span class="pill <?= $erros === 0 ? 'ok' : 'err' ?>"><?= $erros === 0 ? 'Nenhum problema encontrado' : $erros . ' ponto(s) de atencao' ?></span>
        <?php foreach ($contagens as $tabela => $total): ?>
            <span class="pill"><?= htmlspecialchars($tabela) ?>: <?= (int) $total ?></span>
        <?php endforeach; ?>
    </div>

    <p style="margin:14px 0 0;font-size:13px;color:#9db6d8">
        Precisa aplicar a atualizacao do banco (migration 0004)?
        <a href="/_atualizar.php" style="color:#5aa2ff;font-weight:700">Abrir o atualizador</a>
        (pede APP_SECRET ou aproveita a sessao de administrador).
        Para investigar um erro 500, abra os
        <a href="/_logs.php" style="color:#5aa2ff;font-weight:700">logs do sistema</a>.
    </p>

    <?php foreach ($linhas as $grupo => $itens): ?>
        <div class="grupo">
            <h2><?= htmlspecialchars($grupo) ?></h2>
            <table>
                <thead><tr><th style="width:60px">Status</th><th>Item</th><th>Detalhe</th></tr></thead>
                <tbody>
                <?php foreach ($itens as $item): ?>
                    <tr>
                        <td class="st st-<?= htmlspecialchars($item['status']) ?>"><?= strtoupper(htmlspecialchars($item['status'])) ?></td>
                        <td><?= htmlspecialchars($item['item']) ?></td>
                        <td><code><?= htmlspecialchars($item['detalhe']) ?></code></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endforeach; ?>

    <div class="grupo">
        <h2>Variaveis de ambiente</h2>
        <table>
            <tbody>
            <?php foreach (['APP_NAME', 'APP_ENV', 'APP_DEBUG', 'APP_TIMEZONE', 'DB_HOST', 'DB_DATABASE'] as $chave): ?>
                <tr><td style="width:160px"><code><?= $chave ?></code></td><td><code><?= htmlspecialchars((string) ($_ENV[$chave] ?? 'nao definido')) ?></code></td></tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <div class="acoes">
        <a class="button button-primary" href="/_instalar.php?key=<?= urlencode($appSecret) ?>">Atualizar banco agora</a>
        <a class="button button-ghost" href="/login">Ir para o login</a>
    </div>
    <p style="margin-top:16px;color:#ffb3bf;font-size:11.5px">Apague <code>public/_diagnostico.php</code> do servidor depois de usar.</p>
</div>
</body>
</html>
