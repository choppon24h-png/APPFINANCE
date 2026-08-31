<?php
/**
 * BASEAPP — Instalador via navegador (para hospedagem compartilhada,
 * quando nao ha acesso facil ao phpMyAdmin ou terminal).
 *
 * Executa todas as migrations e seeds SQL versionados direto no banco
 * configurado no .env. Os arquivos são processados em ordem alfabética.
 * As migrations do projeto são idempotentes e podem ser reaplicadas com segurança.
 *
 * Acesso: https://seu-dominio.com/_instalar.php?key=SEU_APP_SECRET
 * (a chave e o valor de APP_SECRET no seu .env — assim ninguem mais
 * consegue rodar o instalador sem saber esse segredo).
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

// Protege o instalador com a APP_SECRET do .env
$appSecret = $_ENV['APP_SECRET'] ?? '';
if ($appSecret === '' || $appSecret === 'troque_por_uma_chave_aleatoria_de_32_chars') {
    die('Defina um APP_SECRET real no .env antes de usar o instalador.');
}
if (!hash_equals($appSecret, $_GET['key'] ?? '')) {
    http_response_code(403);
    die('Acesso negado. Use ?key=SEU_APP_SECRET (o valor de APP_SECRET no .env).');
}

try {
    $pdo = new PDO(
        "mysql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_DATABASE']};charset=utf8mb4",
        $_ENV['DB_USERNAME'],
        $_ENV['DB_PASSWORD'],
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Exception $e) {
    die('<h2 style="color:red">Erro de conexao com o banco: ' . htmlspecialchars($e->getMessage()) . '</h2>');
}

/**
 * Executa um arquivo .sql estatuto-a-estatuto (split simples por ";").
 * Suficiente para os arquivos deste projeto (sem procedures/triggers).
 */
function executarArquivoSql(PDO $pdo, string $path): array {
    if (!file_exists($path)) {
        return [['status' => 'error', 'msg' => "Arquivo nao encontrado: {$path}"]];
    }

    $sql = file_get_contents($path);
    $sql = preg_replace('/^--.*$/m', '', $sql); // remove comentarios de linha

    $statements = array_filter(array_map('trim', explode(';', $sql)));
    $resultados = [];

    foreach ($statements as $stmt) {
        if ($stmt === '') continue;
        try {
            $pdo->exec($stmt);
            $resumo = strlen($stmt) > 90 ? substr($stmt, 0, 90) . '…' : $stmt;
            $resultados[] = ['status' => 'ok', 'msg' => htmlspecialchars($resumo)];
        } catch (Exception $e) {
            $resultados[] = ['status' => 'error', 'msg' => htmlspecialchars($e->getMessage())];
        }
    }

    return $resultados;
}

$resultados = [];
$migrations = glob(BASE_PATH . '/database/migrations/*.sql') ?: [];
$seeds = glob(BASE_PATH . '/database/seeds/*.sql') ?: [];
foreach ($migrations as $migration) $resultados = array_merge($resultados, executarArquivoSql($pdo, $migration));
foreach ($seeds as $seed) $resultados = array_merge($resultados, executarArquivoSql($pdo, $seed));

$ok    = count(array_filter($resultados, fn($r) => $r['status'] === 'ok'));
$erros = count(array_filter($resultados, fn($r) => $r['status'] === 'error'));
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>APPFINANCE — Instalador</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
<div class="container py-5" style="max-width:800px">
    <div class="card shadow-sm">
                    <div class="card-header bg-primary text-white">
                <h4 class="mb-0">APPFINANCE — Instalador de Banco de Dados</h4>

        </div>
        <div class="card-body">
            <div class="alert <?= $erros > 0 ? 'alert-warning' : 'alert-success' ?>">
                <strong>Resultado:</strong> <?= $ok ?> comandos executados, <?= $erros ?> erros.
            </div>

            <table class="table table-sm table-bordered">
                <thead class="table-dark"><tr><th style="width:90px">Status</th><th>Comando</th></tr></thead>
                <tbody>
                <?php foreach ($resultados as $r): ?>
                    <tr class="<?= $r['status'] === 'ok' ? 'table-success' : 'table-danger' ?>">
                        <td><strong><?= strtoupper($r['status']) ?></strong></td>
                        <td><code><?= $r['msg'] ?></code></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>

            <?php if ($erros === 0): ?>
                <div class="alert alert-success">
                    <strong>Instalacao concluida.</strong><br>
                    Login inicial: <code>admin@example.com</code> / <code>Admin@123</code> —
                    troque a senha assim que entrar.<br>
                    <span class="text-danger">Apague este arquivo (<code>public/_instalar.php</code>) do servidor agora.</span>
                </div>
                <a href="/login" class="btn btn-primary">Ir para o login</a>
            <?php endif; ?>
        </div>
    </div>
</div>
</body>
</html>
