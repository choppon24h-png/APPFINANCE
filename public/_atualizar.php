<?php
/**
 * SOMASE — Diagnóstico e atualização do banco (hospedagem compartilhada).
 *
 * Mostra o estado do ambiente (PHP, .env, banco, schema, permissões de
 * escrita, últimos erros do log) e aplica a migration 0004 quando ela
 * ainda não foi executada.
 *
 * Acesso: logado como administrador OU com a chave do .env:
 *   https://seu-dominio.com/_atualizar.php   (formulário pede APP_SECRET)
 *
 * IMPORTANTE: apague este arquivo do servidor depois de usar.
 */
declare(strict_types=1);

const BASE_PATH = __DIR__ . '/..';

header('X-Robots-Tag: noindex, nofollow');
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-store');

$envFile = BASE_PATH . '/.env';
$env = [];
if (is_file($envFile)) {
    foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $linha) {
        $linha = trim($linha);
        if ($linha === '' || str_starts_with($linha, '#') || !str_contains($linha, '=')) {
            continue;
        }
        [$k, $v] = explode('=', $linha, 2);
        $env[trim($k)] = trim($v, " \t\n\r\0\x0B\"'");
    }
}

$appSecret = (string) ($env['APP_SECRET'] ?? '');
$erro      = '';
$mensagens = [];

// ── Sessão (mesma pasta do app) ───────────────────────────────────────────────
$sessPath = BASE_PATH . '/storage/sessions';
if (is_dir($sessPath) && is_writable($sessPath)) {
    session_save_path($sessPath);
}
if (session_status() === PHP_SESSION_NONE) {
    @session_start();
}

// ── Conexão ───────────────────────────────────────────────────────────────────
$pdo = null;
$dbErro = '';
try {
    $pdo = new PDO(
        sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $env['DB_HOST'] ?? 'localhost', $env['DB_PORT'] ?? '3306', $env['DB_DATABASE'] ?? ''),
        $env['DB_USERNAME'] ?? '',
        $env['DB_PASSWORD'] ?? '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
    );
} catch (Throwable $e) {
    $dbErro = $e->getMessage();
}

// ── Autorização: sessão de administrador ou chave do .env ────────────────────
$autorizado = false;
$motivoAuth = '';

$userId = (int) ($_SESSION['user_id'] ?? 0);
if ($userId > 0 && $pdo) {
    try {
        $stmt = $pdo->prepare("SELECT r.slug FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = :id");
        $stmt->execute(['id' => $userId]);
        $slug = (string) ($stmt->fetchColumn() ?: '');
        if (in_array($slug, ['superadmin', 'admin'], true)) {
            $autorizado = true;
            $motivoAuth = 'sessão de ' . $slug;
        }
    } catch (Throwable $e) {
        // segue para a chave
    }
}

if (!$autorizado && $appSecret !== '' && ($_POST['chave'] ?? '') !== '') {
    if (hash_equals($appSecret, (string) $_POST['chave'])) {
        $autorizado = true;
        $motivoAuth = 'chave do .env';
        $_SESSION['_diag_ok'] = true;
    } else {
        $erro = 'Chave incorreta. Use o valor de APP_SECRET no .env.';
    }
}

if (!$autorizado && !empty($_SESSION['_diag_ok'])) {
    $autorizado = true;
    $motivoAuth = 'chave validada nesta sessão';
}

// ── Token do formulário ───────────────────────────────────────────────────────
$token = hash('sha256', ($appSecret !== '' ? $appSecret : 'sem-secret') . session_id());

// ── Aplicar migration 0004 ────────────────────────────────────────────────────
function aplicarSql(PDO $pdo, string $arquivo): array
{
    $ok = 0;
    $erros = [];
    if (!is_file($arquivo)) {
        return [0, ['arquivo não encontrado: ' . basename($arquivo)]];
    }
    $sql = preg_replace('/^--.*$/m', '', (string) file_get_contents($arquivo));
    foreach (array_filter(array_map('trim', explode(';', $sql))) as $stmt) {
        if ($stmt === '') {
            continue;
        }
        try {
            $pdo->exec($stmt);
            $ok++;
        } catch (Throwable $e) {
            if (preg_match('/duplicate column|duplicate key name|already exists|Duplicate entry/i', $e->getMessage())) {
                $ok++;
                continue;
            }
            $erros[] = mb_substr($e->getMessage(), 0, 200);
        }
    }
    return [$ok, $erros];
}

if ($autorizado && $pdo && ($_POST['acao'] ?? '') === 'aplicar') {
    if (!hash_equals($token, (string) ($_POST['token'] ?? ''))) {
        $erro = 'Sessão expirada. Recarregue a página e tente novamente.';
    } else {
        [$ok, $erros] = aplicarSql($pdo, BASE_PATH . '/database/migrations/0004_user_registration.sql');
        $mensagens[] = $ok . ' comando(s) aplicado(s) na migration 0004.';
        foreach ($erros as $e) {
            $mensagens[] = 'Falha: ' . $e;
        }
        if (!$erros) {
            $mensagens[] = 'Atualização concluída. Recarregue o sistema e teste o cadastro e o painel.';
        }
        @file_put_contents(
            BASE_PATH . '/storage/logs/app-' . date('Y-m-d') . '.log',
            '[' . date('Y-m-d H:i:s') . '] [INFO] Migration 0004 aplicada via _atualizar.php | '
                . json_encode(['comandos' => $ok, 'erros' => $erros], JSON_UNESCAPED_UNICODE) . PHP_EOL,
            FILE_APPEND
        );
    }
}

// ── Diagnóstico ───────────────────────────────────────────────────────────────
$checks = [];
$checks[] = ['PHP', PHP_VERSION, version_compare(PHP_VERSION, '8.0', '>=')];
foreach (['pdo_mysql', 'curl', 'mbstring', 'openssl', 'json'] as $ext) {
    $checks[] = ['Extensão ' . $ext, extension_loaded($ext) ? 'carregada' : 'AUSENTE', extension_loaded($ext)];
}
$checks[] = ['.env na raiz', is_file($envFile) ? 'encontrado' : 'AUSENTE', is_file($envFile)];
$checks[] = ['APP_URL', (string) ($env['APP_URL'] ?? '(vazio)'), !empty($env['APP_URL'])];
$checks[] = ['Conexão com o banco', $dbErro !== '' ? $dbErro : 'ok', $dbErro === ''];
if ($pdo) {
    try {
        $checks[] = ['Versão do banco', (string) $pdo->query('SELECT VERSION()')->fetchColumn(), true];
    } catch (Throwable $e) {
        $checks[] = ['Versão do banco', $e->getMessage(), false];
    }
}
foreach (['storage/logs', 'storage/sessions', 'storage/uploads'] as $dir) {
    $path = BASE_PATH . '/' . $dir;
    $okDir = is_dir($path) && is_writable($path);
    $checks[] = ['Escrita em ' . $dir, $okDir ? 'ok' : 'SEM PERMISSÃO', $okDir];
}

$faltando = [];
if ($pdo) {
    try {
        $banco = (string) ($env['DB_DATABASE'] ?? '');
        $stmt = $pdo->prepare('SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = :b');
        $stmt->execute(['b' => $banco]);
        $tabelas = array_map('strtolower', $stmt->fetchAll(PDO::FETCH_COLUMN));
        foreach (['user_identities', 'auth_attempts'] as $t) {
            if (!in_array($t, $tabelas, true)) {
                $faltando[] = 'tabela ' . $t;
            }
        }
        $stmt = $pdo->prepare("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = :b AND TABLE_NAME = 'users'");
        $stmt->execute(['b' => $banco]);
        $colunas = array_map('strtolower', $stmt->fetchAll(PDO::FETCH_COLUMN));
        foreach (['birth_date', 'auth_provider', 'avatar_url', 'email_verified_at', 'terms_accepted_at', 'registration_ip'] as $c) {
            if (!in_array($c, $colunas, true)) {
                $faltando[] = 'users.' . $c;
            }
        }
        if (in_array('permissions', $tabelas, true)) {
            $tem = (int) $pdo->query("SELECT COUNT(*) FROM permissions WHERE slug = 'access_admin_panel'")->fetchColumn();
            if ($tem === 0) {
                $faltando[] = 'permissão access_admin_panel';
            }
        }
        $checks[] = ['Migration 0004 (acesso)', $faltando ? 'PENDENTE: ' . implode(', ', $faltando) : 'aplicada', !$faltando];
    } catch (Throwable $e) {
        $checks[] = ['Migration 0004 (acesso)', $e->getMessage(), false];
    }
}

// Últimos erros do log (arquivos diarios app-AAAA-MM-DD.log + legado app.log)
$logLinhas = [];
$arquivosLog = glob(BASE_PATH . '/storage/logs/app-*.log') ?: [];
usort($arquivosLog, static fn ($a, $b) => filemtime($b) <=> filemtime($a));
if (is_file(BASE_PATH . '/storage/logs/app.log')) {
    $arquivosLog[] = BASE_PATH . '/storage/logs/app.log';
}
foreach ($arquivosLog as $logPath) {
    $todas = @file($logPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [];
    foreach (array_reverse($todas) as $linha) {
        if (stripos($linha, '[ERROR]') !== false || stripos($linha, '[WARNING]') !== false) {
            $logLinhas[] = mb_substr($linha, 0, 400);
            if (count($logLinhas) >= 25) {
                break 2;
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Diagnóstico · SOMASE</title>
<style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body { margin: 0; padding: 28px 16px 60px; background: #07101f; color: #e8eef9;
        font-family: Inter, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; font-size: 14px; line-height: 1.55; }
    .wrap { max-width: 900px; margin: 0 auto; }
    .brand { width: 190px; display: block; margin-bottom: 18px; }
    h1 { font-size: 24px; margin: 0 0 6px; }
    h2 { font-size: 15px; margin: 28px 0 10px; color: #9db6d8; text-transform: uppercase; letter-spacing: .08em; }
    p.lead { color: #a9bcd8; margin: 0 0 18px; }
    .card { background: linear-gradient(180deg, rgba(18,37,74,.92), rgba(9,20,40,.96));
        border: 1px solid #1f3560; border-radius: 16px; padding: 18px 20px; }
    table { width: 100%; border-collapse: collapse; }
    td { padding: 8px 6px; border-bottom: 1px solid rgba(31,53,96,.7); vertical-align: top; }
    td:first-child { color: #9db6d8; width: 44%; }
    tr:last-child td { border-bottom: 0; }
    .ok { color: #7ee08a; font-weight: 700; }
    .bad { color: #ff9aa8; font-weight: 700; }
    code { background: #0a1628; border: 1px solid #1f3560; border-radius: 6px; padding: 1px 6px; font-size: 12px; }
    .msg { margin: 14px 0; padding: 12px 14px; border-radius: 12px; border: 1px solid rgba(59,139,255,.3); background: rgba(59,139,255,.1); }
    .msg.err { border-color: rgba(255,93,115,.4); background: rgba(255,93,115,.1); }
    .msg.ok { border-color: rgba(67,193,58,.4); background: rgba(67,193,58,.1); }
    .btn { display: inline-block; margin-top: 12px; padding: 11px 18px; border: 0; border-radius: 12px;
        background: #1f6fe0; color: #fff; font-weight: 700; font-size: 13px; cursor: pointer; }
    input[type=password] { width: 100%; padding: 11px 12px; border-radius: 10px; border: 1px solid #2b4a7d;
        background: #0a1628; color: #e8eef9; font-size: 13px; margin-top: 8px; }
    pre { margin: 0; padding: 14px; background: #050b16; border: 1px solid #1f3560; border-radius: 12px;
        font-size: 11px; line-height: 1.5; color: #9db6d8; white-space: pre-wrap; word-break: break-word; max-height: 360px; overflow: auto; }
    .foot { margin-top: 26px; font-size: 11px; color: #6d82a6; }
</style>
</head>
<body>
<div class="wrap">
    <img class="brand" src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE">
    <h1>Diagnóstico do servidor</h1>
    <p class="lead">Verifica o ambiente, o banco e aplica a atualização da etapa de acesso (migration 0004).</p>

    <?php if ($erro !== ''): ?>
        <div class="msg err"><?= htmlspecialchars($erro) ?></div>
    <?php endif; ?>

    <?php foreach ($mensagens as $m): ?>
        <div class="msg ok"><?= htmlspecialchars($m) ?></div>
    <?php endforeach; ?>

    <?php
    // Status público e sanitizado da conexão: permite diagnosticar o 500
    // sem precisar da chave do .env.
    $statusBanco = 'ok';
    if ($dbErro !== '') {
        $statusBanco = (string) preg_replace("/'[^']*'@'[^']*'/", "'***'@'***'", $dbErro);
        $statusBanco = (string) preg_replace('/\b\d{1,3}(?:\.\d{1,3}){3}\b/', '***', $statusBanco);
        $statusBanco = mb_substr($statusBanco, 0, 240);
    }
    ?>
    <?php
    // Teste real de leitura na tabela users: é o que falha no 500 do login.
    $testeUsers = 'não executado';
    $testeUsersOk = null;
    if ($pdo) {
        try {
            $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
            $testeUsers = 'ok';
            $testeUsersOk = true;
        } catch (Throwable $e) {
            $testeUsers = (string) preg_replace("/'[^']*'@'[^']*'/", "'***'@'***'", $e->getMessage());
            $testeUsers = mb_substr($testeUsers, 0, 240);
            $testeUsersOk = false;
        }
    }
    ?>
    <div class="card" style="border-color:<?= $dbErro === '' ? '#1f7a4d' : '#8a2b2b' ?>">
        <p style="margin:0;font-size:13px">
            <strong>Conexão com o banco:</strong>
            <span class="<?= $dbErro === '' ? 'ok' : 'bad' ?>">
                <?= $dbErro === '' ? 'ok' : htmlspecialchars($statusBanco) ?>
            </span>
        </p>
        <p class="foot" style="margin:6px 0 0">
            PHP <?= PHP_VERSION ?> · driver pdo_mysql: <?= extension_loaded('pdo_mysql') ? 'ok' : 'AUSENTE' ?>
            · .env: <?= is_file($envFile) ? 'ok' : 'AUSENTE' ?>
            · banco configurado: <?= htmlspecialchars((string) ($env['DB_DATABASE'] ?? '(vazio)')) ?>
        </p>
        <p style="margin:8px 0 0;font-size:13px">
            <strong>Leitura da tabela users:</strong>
            <span class="<?= $testeUsersOk === false ? 'bad' : 'ok' ?>"><?= htmlspecialchars($testeUsers) ?></span>
        </p>
    </div>

    <?php if (!$autorizado): ?>
        <div class="card">
            <p>Este diagnóstico mostra detalhes técnicos do servidor. Informe a chave <code>APP_SECRET</code> do arquivo <code>.env</code> para continuar.</p>
            <form method="post">
                <input type="password" name="chave" placeholder="APP_SECRET" autocomplete="off" required>
                <button class="btn" type="submit">Entrar</button>
            </form>
            <p class="foot">Se você já está logado como administrador no SOMASE, abra esta página no mesmo navegador — não é preciso digitar nada.</p>
        </div>
    <?php else: ?>
        <p class="foot">Acesso liberado por: <?= htmlspecialchars($motivoAuth) ?>.
            · <a href="/_logs.php" style="color:#8fb6ff;font-weight:700">Ver logs do sistema</a></p>

        <h2>Ambiente</h2>
        <div class="card">
            <table>
                <?php foreach ($checks as [$rotulo, $valor, $ok]): ?>
                    <tr>
                        <td><?= htmlspecialchars($rotulo) ?></td>
                        <td class="<?= $ok ? 'ok' : 'bad' ?>"><?= htmlspecialchars((string) $valor) ?></td>
                    </tr>
                <?php endforeach; ?>
            </table>
        </div>

        <?php if ($pdo && $faltando): ?>
            <h2>Atualizar o banco</h2>
            <div class="card">
                <p>Faltam: <strong><?= htmlspecialchars(implode(', ', $faltando)) ?></strong>.</p>
                <form method="post">
                    <input type="hidden" name="acao" value="aplicar">
                    <input type="hidden" name="token" value="<?= htmlspecialchars($token) ?>">
                    <button class="btn" type="submit">Aplicar atualização do banco</button>
                </form>
                <p class="foot">Executa apenas <code>database/migrations/0004_user_registration.sql</code>. É seguro repetir.</p>
            </div>
        <?php elseif ($pdo): ?>
            <div class="msg ok">Banco atualizado: nenhuma pendência encontrada.</div>
        <?php endif; ?>

        <h2>Últimos erros registrados</h2>
        <div class="card">
            <?php if (!$logLinhas): ?>
                <p class="ok">Nenhum erro ou aviso no log.</p>
            <?php else: ?>
                <pre><?= htmlspecialchars(implode("\n", $logLinhas)) ?></pre>
            <?php endif; ?>
        </div>

        <p class="foot">Apague <code>public/_atualizar.php</code> e <code>public/_instalar.php</code> depois de usar.</p>
    <?php endif; ?>
</div>
</body>
</html>
