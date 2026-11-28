<?php
/**
 * SOMASE — Diagnóstico e atualização do banco (hospedagem compartilhada).
 *
 * Mostra o estado do ambiente (PHP, .env, banco, schema, permissões de
 * escrita, volume de dados e últimos erros do log) e aplica TODAS as
 * migrations pendentes em `database/migrations/` (0004, 0005, 0006, 0007...).
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

@set_time_limit(180);

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

// ── Migrations conhecidas (as mesmas sentinelas de App\Core\Schema) ──────────
const MIGRACOES = [
    '0004_user_registration.sql' => [
        'label'   => '0004 — acesso, login social e painel',
        'tables'  => ['user_identities', 'auth_attempts'],
        'columns' => ['users' => ['birth_date', 'auth_provider', 'avatar_url', 'email_verified_at', 'terms_accepted_at', 'registration_ip']],
        'seeds'   => [['permissions', 'slug', 'access_admin_panel']],
    ],
    '0005_banks.sql' => [
        'label'   => '0005 — catálogo de bancos',
        'tables'  => ['banks'],
        'minRows' => ['banks' => 100],
    ],
    '0006_documents_properties.sql' => [
        'label'   => '0006 — documentos, imóveis e importação',
        'columns' => [
            'cost_centers' => ['kind', 'address', 'identifiers'],
            'transactions' => ['document_code', 'import_ref', 'attachment_path'],
        ],
    ],
    '0007_cep_payments_investments.sql' => [
        'label'   => '0007 — CEP, formas de pagamento e investimentos',
        'tables'  => ['payment_methods', 'investment_types'],
        'columns' => [
            'cost_centers' => ['zip_code', 'street', 'address_number', 'complement', 'neighborhood', 'city', 'state'],
            'investments'  => ['investment_type_id', 'benchmark_rate', 'rate_period'],
            'accounts'     => ['investment_type_id', 'investment_rate', 'investment_rate_period'],
        ],
    ],
];

/**
 * Lê tabelas e colunas do banco uma única vez.
 * @return array{tables:array<int,string>,columns:array<string,array<int,string>>}
 */
function lerSchema(PDO $pdo): array
{
    $tabelas = [];
    $colunas = [];
    try {
        $stmt = $pdo->query('SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()');
        foreach ($stmt->fetchAll() as $linha) {
            $tabela = strtolower((string) $linha['TABLE_NAME']);
            $tabelas[$tabela] = true;
            $colunas[$tabela][] = strtolower((string) $linha['COLUMN_NAME']);
        }
    } catch (Throwable $e) {
        // banco sem permissão no information_schema: segue com o que tem
    }
    return ['tables' => array_keys($tabelas), 'columns' => $colunas];
}

/**
 * Compara as sentinelas com o banco.
 * @return array<string,array<int,string>> arquivo => pendências
 */
function pendencias(array $schema): array
{
    $resultado = [];
    foreach (MIGRACOES as $arquivo => $m) {
        $faltando = [];
        foreach ($m['tables'] ?? [] as $tabela) {
            if (!in_array($tabela, $schema['tables'], true)) {
                $faltando[] = 'tabela ' . $tabela;
            }
        }
        foreach ($m['columns'] ?? [] as $tabela => $cols) {
            if (!in_array($tabela, $schema['tables'], true)) {
                $faltando[] = 'tabela ' . $tabela;
                continue;
            }
            $existentes = $schema['columns'][$tabela] ?? [];
            foreach ($cols as $col) {
                if (!in_array(strtolower($col), $existentes, true)) {
                    $faltando[] = $tabela . '.' . $col;
                }
            }
        }
        $resultado[$arquivo] = $faltando;
    }
    return $resultado;
}

/**
 * Executa um arquivo .sql statement por statement, tolerando o que já existe.
 * @return array{0:int,1:int,2:array<int,string>} [aplicados, ignorados, erros]
 */
function aplicarSql(PDO $pdo, string $arquivo): array
{
    if (!is_file($arquivo)) {
        return [0, 0, ['arquivo não encontrado: ' . basename($arquivo)]];
    }

    $sql = (string) file_get_contents($arquivo);
    $sql = preg_replace('/^\s*--.*$/m', '', $sql);       // comentários de linha
    $sql = preg_replace('/^\s*#.*$/m', '', $sql);        // comentários #
    $sql = preg_replace('#/\*.*?\*/#s', '', $sql);       // comentários de bloco

    $aplicados = 0;
    $ignorados = 0;
    $erros = [];

    foreach (array_filter(array_map('trim', explode(';', $sql))) as $stmt) {
        if ($stmt === '' || strtoupper($stmt) === 'DO 0') {
            continue;
        }
        try {
            $pdo->exec($stmt);
            $aplicados++;
        } catch (Throwable $e) {
            $msg = $e->getMessage();
            if (preg_match('/duplicate column|duplicate key name|already exists|Duplicate entry|check that column\/key exists/i', $msg)) {
                $ignorados++;
                continue;
            }
            if (str_contains($msg, 'errno: 121')) {
                $msg .= ' — nome de constraint duplicado: existe uma tabela de backup com o mesmo nome de chave estrangeira. Apague a tabela de backup e aplique de novo.';
            } elseif (str_contains($msg, 'errno: 150')) {
                $msg .= ' — chave estrangeira sem tabela de origem: verifique se as migrations anteriores (0003) foram aplicadas.';
            }
            $erros[] = mb_substr($msg, 0, 320);
        }
    }

    return [$aplicados, $ignorados, $erros];
}

/** Grava uma linha no log diário do app (mesmo formato do Logger). */
function registrarLog(string $nivel, string $mensagem, array $contexto = []): void
{
    $linha = '[' . date('Y-m-d H:i:s') . '] [' . $nivel . '] [DIAG] ' . $mensagem
        . ($contexto ? ' | ' . json_encode($contexto, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : '')
        . PHP_EOL;
    @file_put_contents(BASE_PATH . '/storage/logs/app-' . date('Y-m-d') . '.log', $linha, FILE_APPEND | LOCK_EX);
}

// ── Aplicar migrations pendentes ─────────────────────────────────────────────
$schema = $pdo ? lerSchema($pdo) : ['tables' => [], 'columns' => []];
$pend = $pdo ? pendencias($schema) : [];
$pendentes = array_keys(array_filter($pend, static fn (array $f): bool => $f !== []));

if ($autorizado && $pdo && ($_POST['acao'] ?? '') === 'aplicar') {
    if (!hash_equals($token, (string) ($_POST['token'] ?? ''))) {
        $erro = 'Sessão expirada. Recarregue a página e tente novamente.';
    } else {
        $totalErros = 0;
        $paraAplicar = $pendentes !== [] ? $pendentes : [];
        if ($paraAplicar === []) {
            $mensagens[] = 'Nenhuma migration pendente: o banco já está atualizado.';
        }
        foreach ($paraAplicar as $arquivo) {
            $caminho = BASE_PATH . '/database/migrations/' . $arquivo;
            [$aplicados, $ignorados, $erros] = aplicarSql($pdo, $caminho);
            $mensagens[] = $arquivo . ': ' . $aplicados . ' comando(s) aplicado(s)'
                . ($ignorados ? ', ' . $ignorados . ' já existente(s)' : '') . '.';
            foreach ($erros as $e) {
                $mensagens[] = 'Falha em ' . $arquivo . ': ' . $e;
                $totalErros++;
            }
            registrarLog('INFO', 'migration.aplicada', [
                'arquivo' => $arquivo, 'aplicados' => $aplicados,
                'ignorados' => $ignorados, 'erros' => $erros,
            ]);
        }

        $schema = lerSchema($pdo);
        $pend = pendencias($schema);
        $restantes = array_keys(array_filter($pend, static fn (array $f): bool => $f !== []));

        unset($_SESSION['_schema_pend'], $_SESSION['_schema_pend_ts']);

        if ($totalErros === 0 && $restantes === []) {
            $mensagens[] = 'Atualização concluída. Recarregue o sistema e teste as telas.';
            registrarLog('INFO', 'migration.concluida', ['migrations' => $paraAplicar]);
        } elseif ($restantes !== []) {
            $mensagens[] = 'Ainda pendente: ' . implode(', ', $restantes) . '. Veja os erros acima.';
            registrarLog('WARNING', 'migration.incompleta', ['pendentes' => $restantes, 'erros' => $totalErros]);
        }
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
        $checks[] = ['Banco em uso', (string) $pdo->query('SELECT DATABASE()')->fetchColumn(), true];
    } catch (Throwable $e) {
        $checks[] = ['Versão do banco', $e->getMessage(), false];
    }
}
foreach (['storage/logs', 'storage/sessions', 'storage/uploads', 'storage/cache/cep'] as $dir) {
    $path = BASE_PATH . '/' . $dir;
    $okDir = is_dir($path) && is_writable($path);
    $checks[] = ['Escrita em ' . $dir, $okDir ? 'ok' : 'SEM PERMISSÃO', $okDir];
}

// ── Volume de dados (para detectar banco recriado/vazio) ─────────────────────
$contagens = [];
if ($pdo) {
    foreach (['users', 'accounts', 'categories', 'cost_centers', 'transactions', 'investments', 'payment_methods', 'investment_types'] as $tabela) {
        if (!in_array($tabela, $schema['tables'], true)) {
            $contagens[$tabela] = null;
            continue;
        }
        try {
            $contagens[$tabela] = (int) $pdo->query('SELECT COUNT(*) FROM `' . $tabela . '`')->fetchColumn();
        } catch (Throwable $e) {
            $contagens[$tabela] = null;
        }
    }
}
$semDados = $pdo && ($contagens['transactions'] ?? null) === 0 && ($contagens['accounts'] ?? null) === 0;

// Últimos erros do log (arquivos diários app-AAAA-MM-DD.log + legado app.log)
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
    td, th { padding: 8px 6px; border-bottom: 1px solid rgba(31,53,96,.7); vertical-align: top; text-align: left; }
    td:first-child { color: #9db6d8; width: 44%; }
    th { color: #9db6d8; font-size: 12px; text-transform: uppercase; letter-spacing: .06em; }
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
    .pill { display: inline-block; padding: 2px 9px; border-radius: 999px; font-size: 11px; font-weight: 700; }
    .pill.ok { background: rgba(67,193,58,.16); color: #7ee08a; }
    .pill.bad { background: rgba(255,93,115,.16); color: #ff9aa8; }
</style>
</head>
<body>
<div class="wrap">
    <img class="brand" src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE">
    <h1>Diagnóstico do servidor</h1>
    <p class="lead">Verifica o ambiente, o banco e aplica todas as migrations pendentes (0004 a 0007).</p>

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

        <h2>Migrations do banco</h2>
        <div class="card">
            <?php if (!$pdo): ?>
                <p class="bad">Sem conexão com o banco: não é possível verificar as migrations.</p>
            <?php else: ?>
                <table>
                    <tr><th>Migration</th><th>Status</th></tr>
                    <?php foreach (MIGRACOES as $arquivo => $m): ?>
                        <?php $faltando = $pend[$arquivo] ?? []; ?>
                        <tr>
                            <td><?= htmlspecialchars($m['label']) ?><br><code><?= htmlspecialchars($arquivo) ?></code></td>
                            <td>
                                <?php if ($faltando === []): ?>
                                    <span class="pill ok">aplicada</span>
                                <?php else: ?>
                                    <span class="pill bad">pendente</span><br>
                                    <small><?= htmlspecialchars(implode(', ', array_slice($faltando, 0, 6))) ?></small>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </table>

                <?php if ($pendentes !== []): ?>
                    <form method="post">
                        <input type="hidden" name="acao" value="aplicar">
                        <input type="hidden" name="token" value="<?= htmlspecialchars($token) ?>">
                        <button class="btn" type="submit">Aplicar <?= count($pendentes) ?> migration(s) pendente(s)</button>
                    </form>
                    <p class="foot">Executa, nesta ordem: <code><?= htmlspecialchars(implode('</code>, <code>', $pendentes)) ?></code>. É seguro repetir: nada é apagado.</p>
                <?php else: ?>
                    <div class="msg ok" style="margin-bottom:0">Banco atualizado: nenhuma migration pendente.</div>
                <?php endif; ?>
            <?php endif; ?>
        </div>

        <?php if ($pdo): ?>
            <h2>Seus dados</h2>
            <div class="card">
                <table>
                    <?php foreach ($contagens as $tabela => $total): ?>
                        <tr>
                            <td><?= htmlspecialchars($tabela) ?></td>
                            <td class="<?= $total === null ? 'bad' : 'ok' ?>">
                                <?= $total === null ? 'tabela ausente' : (int) $total . ' registro(s)' ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </table>
                <?php if ($semDados): ?>
                    <div class="msg err" style="margin-bottom:0">
                        <strong>Atenção:</strong> não há contas nem lançamentos neste banco. Se você tinha dados e importou
                        <code>database/sql/somase_instalacao_completa.sql</code>, esse arquivo <strong>apaga as tabelas</strong> antes de criar.
                        Restaure o backup mais recente pelo cPanel (Arquivos → Backup) e use, para atualizar,
                        <code>database/migrations/0007_cep_payments_investments.sql</code> ou <code>somase_atualizar_banco.sql</code>.
                    </div>
                <?php else: ?>
                    <p class="foot" style="margin-bottom:0">Para atualizar um banco com dados, use sempre as migrations (ou <code>somase_atualizar_banco.sql</code>), nunca o arquivo de instalação completa.</p>
                <?php endif; ?>
            </div>
        <?php endif; ?>

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
