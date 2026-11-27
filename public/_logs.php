<?php
/**
 * SOMASE — Visualizador de logs (hospedagem compartilhada, sem SSH).
 *
 * Lê storage/logs/*.log, mostra as últimas linhas, permite filtrar por
 * texto e por nível (erros/avisos), baixar o arquivo e apagar logs antigos.
 *
 * Acesso: logado como administrador OU com a chave do .env:
 *   https://seu-dominio.com/_logs.php            (formulário pede APP_SECRET)
 *   https://seu-dominio.com/_logs.php?key=CHAVE
 *
 * IMPORTANTE: apague este arquivo do servidor depois de usar.
 */
declare(strict_types=1);

const BASE_PATH = __DIR__ . '/..';
const LOG_DIR   = BASE_PATH . '/storage/logs';

header('X-Robots-Tag: noindex, nofollow');
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-store');

// ── .env ─────────────────────────────────────────────────────────────────────
$env = [];
if (is_file(BASE_PATH . '/.env')) {
    foreach (file(BASE_PATH . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $linha) {
        $linha = trim($linha);
        if ($linha === '' || str_starts_with($linha, '#') || !str_contains($linha, '=')) {
            continue;
        }
        [$k, $v] = explode('=', $linha, 2);
        $env[trim($k)] = trim($v, " \t\n\r\0\x0B\"'");
    }
}
$appSecret = (string) ($env['APP_SECRET'] ?? '');

// ── Sessão ───────────────────────────────────────────────────────────────────
$sessPath = BASE_PATH . '/storage/sessions';
if (is_dir($sessPath) && is_writable($sessPath)) {
    session_save_path($sessPath);
}
if (session_status() === PHP_SESSION_NONE) {
    @session_start();
}

// ── Pasta de logs ────────────────────────────────────────────────────────────
if (!is_dir(LOG_DIR)) {
    @mkdir(LOG_DIR, 0755, true);
}
$dirOk     = is_dir(LOG_DIR) && is_writable(LOG_DIR);
$dirStatus = $dirOk ? 'gravável' : (is_dir(LOG_DIR) ? 'SEM PERMISSÃO DE ESCRITA' : 'NÃO EXISTE');

// ── Autorização: sessão de administrador ou chave do .env ────────────────────
$pdo = null;
try {
    $pdo = new PDO(
        sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $env['DB_HOST'] ?? 'localhost', $env['DB_PORT'] ?? '3306', $env['DB_DATABASE'] ?? ''),
        $env['DB_USERNAME'] ?? '',
        $env['DB_PASSWORD'] ?? '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
    );
} catch (Throwable $e) {
    $pdo = null;
}

$autorizado = false;
$motivoAuth = '';
$erro       = '';

$userId = (int) ($_SESSION['user_id'] ?? 0);
if ($userId > 0 && $pdo) {
    try {
        $stmt = $pdo->prepare('SELECT r.slug FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = :id');
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

$chaveRecebida = (string) ($_POST['chave'] ?? $_GET['key'] ?? '');
if (!$autorizado && $appSecret !== '' && $chaveRecebida !== '') {
    if (hash_equals($appSecret, $chaveRecebida)) {
        $autorizado = true;
        $motivoAuth = 'chave do .env';
        $_SESSION['_logs_ok'] = true;
    } else {
        $erro = 'Chave incorreta. Use o valor de APP_SECRET no .env.';
    }
}
if (!$autorizado && !empty($_SESSION['_logs_ok'])) {
    $autorizado = true;
    $motivoAuth = 'chave validada nesta sessão';
}

$token = hash('sha256', ($appSecret !== '' ? $appSecret : 'sem-secret') . session_id());

// ── Arquivos disponíveis ─────────────────────────────────────────────────────
$arquivos = glob(LOG_DIR . '/*.log') ?: [];
usort($arquivos, static fn ($a, $b) => filemtime($b) <=> filemtime($a));

// ── Ações (somente autenticado) ──────────────────────────────────────────────
$aviso = '';
if ($autorizado) {
    // apagar logs com mais de N dias
    if (($_POST['acao'] ?? '') === 'limpar' && hash_equals($token, (string) ($_POST['token'] ?? ''))) {
        $dias = max(1, (int) ($_POST['dias'] ?? 30));
        $limite = time() - ($dias * 86400);
        $apagados = 0;
        foreach ($arquivos as $arq) {
            if (filemtime($arq) < $limite && @unlink($arq)) {
                $apagados++;
            }
        }
        $arquivos = glob(LOG_DIR . '/*.log') ?: [];
        usort($arquivos, static fn ($a, $b) => filemtime($b) <=> filemtime($a));
        $aviso = $apagados . ' arquivo(s) com mais de ' . $dias . ' dias apagado(s).';
    }

    // download do arquivo bruto
    if (isset($_GET['baixar'])) {
        $alvo = LOG_DIR . '/' . basename((string) $_GET['baixar']);
        if (is_file($alvo) && str_ends_with($alvo, '.log')) {
            header('Content-Type: text/plain; charset=utf-8');
            header('Content-Disposition: attachment; filename="' . basename($alvo) . '"');
            header('Content-Length: ' . filesize($alvo));
            readfile($alvo);
            exit;
        }
    }
}

// ── Seleção e leitura ────────────────────────────────────────────────────────
$arquivoSel = basename((string) ($_GET['arquivo'] ?? ''));
if ($arquivoSel === '' || !is_file(LOG_DIR . '/' . $arquivoSel)) {
    $arquivoSel = $arquivos ? basename($arquivos[0]) : '';
}

$limite  = in_array((int) ($_GET['linhas'] ?? 300), [100, 300, 1000, 5000], true) ? (int) ($_GET['linhas'] ?? 300) : 300;
$busca   = trim((string) ($_GET['q'] ?? ''));
$nivel   = in_array(($_GET['nivel'] ?? 'todos'), ['todos', 'erros', 'avisos', 'acesso'], true) ? (string) ($_GET['nivel'] ?? 'todos') : 'todos';

$linhas = [];
$totalLinhas = 0;
if ($autorizado && $arquivoSel !== '') {
    $caminho = LOG_DIR . '/' . $arquivoSel;
    $todas = @file($caminho, FILE_IGNORE_NEW_LINES) ?: [];
    $totalLinhas = count($todas);
    $todas = array_reverse($todas);

    foreach ($todas as $linha) {
        if ($busca !== '' && mb_stripos($linha, $busca) === false) {
            continue;
        }
        $ehErro   = str_contains($linha, '[ERROR]') || str_contains($linha, '[CRITICAL]');
        $ehAviso  = str_contains($linha, '[WARNING]');
        if ($nivel === 'erros' && !$ehErro) {
            continue;
        }
        if ($nivel === 'avisos' && !$ehAviso) {
            continue;
        }
        $linhas[] = $linha;
        if (count($linhas) >= $limite) {
            break;
        }
    }
    $linhas = array_reverse($linhas);
}

// ── Estatísticas ─────────────────────────────────────────────────────────────
$tamanhoTotal = 0;
foreach ($arquivos as $arq) {
    $tamanhoTotal += (int) @filesize($arq);
}

$fmtBytes = static function (int $b): string {
    if ($b >= 1048576) {
        return number_format($b / 1048576, 1, ',', '.') . ' MB';
    }
    if ($b >= 1024) {
        return number_format($b / 1024, 1, ',', '.') . ' KB';
    }
    return $b . ' B';
};

$escapar = static fn (string $t): string => htmlspecialchars($t, ENT_QUOTES, 'UTF-8');

/** Destaca nível e trechos da busca na linha do log. */
$renderLinha = static function (string $linha) use ($escapar, $busca): string {
    $html = $escapar($linha);
    $classe = 'log-line';
    if (str_contains($linha, '[ERROR]') || str_contains($linha, '[CRITICAL]')) {
        $classe .= ' is-error';
    } elseif (str_contains($linha, '[WARNING]')) {
        $classe .= ' is-warn';
    } elseif (str_contains($linha, '[INFO]')) {
        $classe .= ' is-info';
    }
    if ($busca !== '') {
        $html = (string) preg_replace(
            '/' . preg_quote($escapar($busca), '/') . '/iu',
            '<mark>$0</mark>',
            $html
        );
    }
    return '<div class="' . $classe . '">' . $html . '</div>';
};

$linkBase = static function (array $troca = []) use ($arquivoSel, $limite, $busca, $nivel, $chaveRecebida): string {
    $params = array_filter(array_merge([
        'arquivo' => $arquivoSel,
        'linhas'  => $limite,
        'q'       => $busca,
        'nivel'   => $nivel,
    ], $troca), static fn ($v) => $v !== '' && $v !== null);
    if ($chaveRecebida !== '') {
        $params['key'] = $chaveRecebida;
    }
    return '/_logs.php?' . http_build_query($params);
};
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#07101f">
<meta name="robots" content="noindex, nofollow">
<title>Logs · SOMASE</title>
<link rel="icon" href="/favicon.ico" sizes="any">
<style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body {
        margin: 0; padding: 26px 18px 60px; min-height: 100vh;
        font-family: Inter, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
        color: #e8eef9; background:
            radial-gradient(900px 500px at 12% 0%, rgba(31,111,224,.22), transparent 60%),
            radial-gradient(700px 420px at 92% 100%, rgba(67,193,58,.12), transparent 62%),
            #07101f;
    }
    .wrap { width: 100%; max-width: 1180px; margin: 0 auto; }
    .brand { display: block; width: min(210px, 60%); margin-bottom: 18px; }
    h1 { margin: 0 0 6px; font-size: 24px; letter-spacing: -.02em; }
    .sub { margin: 0 0 18px; color: #9db0cc; font-size: 13px; }
    .sub code { background: rgba(59,139,255,.14); padding: 1px 5px; border-radius: 5px; color: #cfe0ff; }
    .card {
        background: linear-gradient(180deg, rgba(18,37,74,.85), rgba(9,20,40,.92));
        border: 1px solid #1f3560; border-radius: 16px; padding: 18px; margin-bottom: 16px;
    }
    .grid { display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); }
    .stat { background: rgba(7,16,31,.55); border: 1px solid #1a2c4f; border-radius: 12px; padding: 10px 12px; }
    .stat span { display: block; font-size: 10.5px; letter-spacing: .12em; text-transform: uppercase; color: #7f96b8; }
    .stat strong { font-size: 14px; font-weight: 700; overflow-wrap: anywhere; }
    .ok { color: #7ee2a8; } .bad { color: #ff9aa7; }
    form.filtros { display: flex; flex-wrap: wrap; gap: 10px; align-items: flex-end; }
    label.campo { display: grid; gap: 5px; font-size: 11px; color: #93a8c7; text-transform: uppercase; letter-spacing: .1em; }
    select, input[type="text"], input[type="password"] {
        background: #0b1830; color: #e8eef9; border: 1px solid #24406d; border-radius: 9px;
        padding: 8px 10px; font-size: 13px; min-height: 38px;
    }
    input[type="text"] { min-width: 230px; }
    button, .botao {
        display: inline-flex; align-items: center; gap: 6px; min-height: 38px; padding: 8px 16px;
        border-radius: 10px; border: 1px solid transparent; background: #1f6fe0; color: #fff;
        font-size: 13px; font-weight: 700; cursor: pointer; text-decoration: none;
    }
    .botao.ghost, button.ghost { background: transparent; border-color: #2b4a7d; color: #cfe0ff; }
    .botao.danger, button.danger { background: transparent; border-color: #7a2c3a; color: #ffb3bf; }
    .log {
        margin: 0; padding: 12px; border-radius: 12px; background: #050b16; border: 1px solid #1a2c4f;
        max-height: 62vh; overflow: auto; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
        font-size: 11.5px; line-height: 1.65;
    }
    .log-line { white-space: pre-wrap; word-break: break-word; padding: 2px 4px; border-radius: 4px; color: #9fb4d3; }
    .log-line.is-error { color: #ff9aa7; background: rgba(255,77,99,.07); }
    .log-line.is-warn { color: #ffd28a; }
    .log-line.is-info { color: #9fb4d3; }
    .log-line mark { background: rgba(59,139,255,.35); color: #fff; border-radius: 3px; }
    .vazio { padding: 26px; text-align: center; color: #7f96b8; font-size: 13px; }
    .aviso { margin: 0 0 14px; padding: 10px 12px; border-radius: 10px; font-size: 13px;
             background: rgba(59,139,255,.1); border: 1px solid rgba(59,139,255,.3); color: #cfe0ff; }
    .aviso.erro { background: rgba(255,77,99,.1); border-color: rgba(255,77,99,.35); color: #ffc2cb; }
    .acoes { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 12px; }
    .rodape { margin-top: 18px; font-size: 11px; color: #6d82a6; text-align: center; }
    .rodape a { color: #8fb6ff; }
</style>
</head>
<body>
<div class="wrap">
    <img class="brand" src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE — Controle Financeiro">
    <h1>Logs do sistema</h1>
    <p class="sub">Arquivos em <code>storage/logs/</code>. Cada erro tem um código de 8 caracteres que também aparece na tela de falha.</p>

    <?php if (!$autorizado): ?>
        <div class="card" style="max-width:520px">
            <h2 style="margin:0 0 10px;font-size:16px">Acesso restrito</h2>
            <p class="sub" style="margin-bottom:14px">Entre como administrador ou informe a chave <code>APP_SECRET</code> do <code>.env</code>.</p>
            <?php if ($erro !== ''): ?>
                <p class="aviso erro"><?= $escapar($erro) ?></p>
            <?php endif; ?>
            <form method="post" class="filtros">
                <label class="campo">Chave APP_SECRET
                    <input type="password" name="chave" required autocomplete="off">
                </label>
                <button type="submit">Abrir logs</button>
            </form>
        </div>
        <p class="rodape">© <?= date('Y') ?> SOMASE · Controle Financeiro</p>
    </div></body></html>
        <?php exit; ?>
    <?php endif; ?>

    <?php if ($aviso !== ''): ?>
        <p class="aviso"><?= $escapar($aviso) ?></p>
    <?php endif; ?>

    <div class="card">
        <div class="grid">
            <div class="stat"><span>Pasta</span><strong title="<?= $escapar(LOG_DIR) ?>">storage/logs</strong></div>
            <div class="stat"><span>Permissão</span><strong class="<?= $dirOk ? 'ok' : 'bad' ?>"><?= $escapar($dirStatus) ?></strong></div>
            <div class="stat"><span>Arquivos</span><strong><?= count($arquivos) ?> · <?= $fmtBytes($tamanhoTotal) ?></strong></div>
            <div class="stat"><span>Acesso</span><strong><?= $escapar($motivoAuth) ?></strong></div>
            <div class="stat"><span>PHP</span><strong><?= $escapar(PHP_VERSION) ?></strong></div>
        </div>
        <?php if (!$dirOk): ?>
            <p class="aviso erro" style="margin-top:12px">A pasta de logs não aceita escrita. Ajuste a permissão para 755 em <code>storage/logs</code> (Gerenciador de Arquivos &gt; Permissions). Enquanto isso, o sistema grava no diretório temporário do PHP e os arquivos não aparecem aqui.</p>
        <?php endif; ?>
    </div>

    <div class="card">
        <form method="get" class="filtros">
            <label class="campo">Arquivo
                <select name="arquivo">
                    <?php if (!$arquivos): ?>
                        <option value="">(nenhum log ainda)</option>
                    <?php endif; ?>
                    <?php foreach ($arquivos as $arq): ?>
                        <?php $nome = basename($arq); ?>
                        <option value="<?= $escapar($nome) ?>" <?= $nome === $arquivoSel ? 'selected' : '' ?>>
                            <?= $escapar($nome) ?> · <?= $fmtBytes((int) @filesize($arq)) ?> · <?= date('d/m H:i', (int) @filemtime($arq)) ?>
                        </option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="campo">Nível
                <select name="nivel">
                    <?php foreach (['todos' => 'Tudo', 'erros' => 'Somente erros', 'avisos' => 'Somente avisos'] as $valor => $rotulo): ?>
                        <option value="<?= $valor ?>" <?= $nivel === $valor ? 'selected' : '' ?>><?= $rotulo ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="campo">Linhas
                <select name="linhas">
                    <?php foreach ([100, 300, 1000, 5000] as $n): ?>
                        <option value="<?= $n ?>" <?= $limite === $n ? 'selected' : '' ?>><?= $n ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="campo">Buscar
                <input type="text" name="q" value="<?= $escapar($busca) ?>" placeholder="código do erro, e-mail, rota...">
            </label>
            <?php if ($chaveRecebida !== ''): ?>
                <input type="hidden" name="key" value="<?= $escapar($chaveRecebida) ?>">
            <?php endif; ?>
            <button type="submit">Filtrar</button>
            <a class="botao ghost" href="<?= $escapar($linkBase(['nivel' => 'todos', 'q' => '', 'linhas' => 300])) ?>">Limpar filtros</a>
        </form>

        <div class="acoes">
            <?php if ($arquivoSel !== ''): ?>
                <a class="botao ghost" href="<?= $escapar($linkBase(['baixar' => $arquivoSel])) ?>">Baixar <?= $escapar($arquivoSel) ?></a>
            <?php endif; ?>
            <a class="botao ghost" href="/_atualizar.php">Diagnóstico do banco</a>
            <form method="post" onsubmit="return confirm('Apagar logs com mais de 30 dias?');" style="display:inline">
                <input type="hidden" name="acao" value="limpar">
                <input type="hidden" name="dias" value="30">
                <input type="hidden" name="token" value="<?= $escapar($token) ?>">
                <button type="submit" class="danger">Apagar logs &gt; 30 dias</button>
            </form>
        </div>
    </div>

    <div class="card">
        <p class="sub" style="margin-bottom:10px">
            <?= $arquivoSel !== '' ? '<code>' . $escapar($arquivoSel) . '</code> — ' . count($linhas) . ' de ' . number_format($totalLinhas, 0, ',', '.') . ' linha(s)' : 'Nenhum arquivo de log encontrado.' ?>
        </p>
        <?php if (!$linhas): ?>
            <p class="vazio">
                <?= $arquivoSel === '' ? 'Ainda não há logs. Navegue pelo sistema para gerar registros.' : 'Nenhuma linha corresponde ao filtro.' ?>
            </p>
        <?php else: ?>
            <div class="log">
                <?php foreach ($linhas as $linha): ?>
                    <?= $renderLinha($linha) ?>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>

    <p class="rodape">© <?= date('Y') ?> SOMASE · Controle Financeiro · apague <code>public/_logs.php</code> depois de usar</p>
</div>
</body>
</html>
