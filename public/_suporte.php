<?php
/**
 * SOMASE — Suporte técnico do usuário.
 *
 * Mostra, para o usuário logado: identificação da conta, estado das
 * migrations, contagens dos próprios dados e o resultado de um teste de
 * gravação no banco (feito dentro de uma transação com rollback, sem
 * deixar lixo). Também lista os últimos erros do log com o código de
 * referência que aparece nas mensagens de falha.
 *
 * Acesso: qualquer usuário autenticado. Não exige administrador.
 */
declare(strict_types=1);

require_once dirname(__DIR__) . '/app/bootstrap.php';

use App\Core\Auth;
use App\Core\Database;
use App\Core\Diagnostics;
use App\Core\Logger;
use App\Core\Schema;

header('X-Robots-Tag: noindex, nofollow');
header('Cache-Control: no-store');

if (!Auth::check()) {
    header('Location: /login');
    exit;
}

$usuario = Auth::user();
$userId  = (int) ($usuario->id ?? 0);
$pdo     = Database::getInstance();

$resultadoTeste = null;
$codigoTeste    = '';

if (($_POST['acao'] ?? '') === 'teste') {
    $codigoTeste = Diagnostics::codigo();
    $passos = [];

    // 1. Leitura simples
    try {
        $stmt = $pdo->prepare('SELECT COUNT(*) FROM accounts WHERE user_id = :id');
        $stmt->execute(['id' => $userId]);
        $passos[] = ['Leitura de contas', 'ok', (int) $stmt->fetchColumn() . ' conta(s)'];
    } catch (Throwable $e) {
        $passos[] = ['Leitura de contas', 'falhou', $e->getMessage()];
    }

    // 2. Gravação com as colunas básicas (estrutura antiga)
    try {
        $pdo->beginTransaction();
        $stmt = $pdo->prepare(
            'INSERT INTO accounts (user_id, name, account_type, initial_balance, current_balance, initial_date, status)
             VALUES (:user_id, :name, :tipo, 0, 0, CURDATE(), :status)'
        );
        $stmt->execute(['user_id' => $userId, 'name' => '__TESTE_DIAGNOSTICO__', 'tipo' => 'checking', 'status' => 'inactive']);
        $id = (int) $pdo->lastInsertId();
        $pdo->rollBack();
        $passos[] = ['Gravação básica de conta', 'ok', 'inseriu e desfez (id ' . $id . ')'];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        $passos[] = ['Gravação básica de conta', 'falhou', $e->getMessage()];
    }

    // 3. Gravação com as colunas da migration 0007
    try {
        $pdo->beginTransaction();
        $stmt = $pdo->prepare(
            'INSERT INTO accounts
                (user_id, name, bank_name, bank_code, account_type, agency, account_number,
                 investment_type_id, investment_rate, investment_rate_period,
                 initial_balance, current_balance, initial_date, status, notes)
             VALUES (:user_id, :name, NULL, NULL, :tipo, NULL, NULL, NULL, NULL, :periodo, 0, 0, CURDATE(), :status, NULL)'
        );
        $stmt->execute(['user_id' => $userId, 'name' => '__TESTE_DIAGNOSTICO__', 'tipo' => 'checking', 'periodo' => 'annual', 'status' => 'inactive']);
        $id = (int) $pdo->lastInsertId();
        $pdo->rollBack();
        $passos[] = ['Gravação completa (com campos de investimento)', 'ok', 'inseriu e desfez (id ' . $id . ')'];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        $passos[] = ['Gravação completa (com campos de investimento)', 'falhou', $e->getMessage()];
    }

    // 4. Catálogos novos
    foreach (['payment_methods', 'investment_types'] as $tabela) {
        try {
            $total = (int) $pdo->query('SELECT COUNT(*) FROM `' . $tabela . '`')->fetchColumn();
            $passos[] = ['Tabela ' . $tabela, 'ok', $total . ' registro(s)'];
        } catch (Throwable $e) {
            $passos[] = ['Tabela ' . $tabela, 'falhou', $e->getMessage()];
        }
    }

    $resultadoTeste = $passos;

    $falhas = array_values(array_filter($passos, static fn (array $p): bool => $p[1] === 'falhou'));
    if ($falhas === []) {
        Logger::info('suporte.teste_gravacao.ok', ['user_id' => $userId, 'codigo' => $codigoTeste]);
    } else {
        Logger::error('suporte.teste_gravacao.falhou', [
            'user_id' => $userId, 'codigo' => $codigoTeste,
            'falhas' => array_map(static fn (array $p): array => [$p[0], $p[2]], $falhas),
        ]);
    }
}

// Migrations pendentes (nao derruba a pagina se o banco estiver fora)
$pendentes = [];
try {
    $pendentes = Schema::pending();
} catch (Throwable $e) {
    Logger::warning('suporte.schema_indisponivel', ['erro' => $e->getMessage()]);
}

// Contagens do usuário (o que ele espera ver nas telas)
$contagens = [];
foreach ([
    'accounts' => 'Contas',
    'transactions' => 'Lançamentos',
    'categories' => 'Categorias (inclui padrão)',
    'cost_centers' => 'Centros de custo (inclui padrão)',
    'investments' => 'Investimentos',
    'payment_methods' => 'Formas de pagamento (inclui padrão)',
    'investment_types' => 'Tipos de investimento (inclui padrão)',
] as $tabela => $rotulo) {
    try {
        $sql = in_array($tabela, ['categories', 'cost_centers', 'payment_methods', 'investment_types'], true)
            ? 'SELECT COUNT(*) FROM `' . $tabela . '` WHERE user_id IS NULL OR user_id = :id'
            : 'SELECT COUNT(*) FROM `' . $tabela . '` WHERE user_id = :id';
        $stmt = $pdo->prepare($sql);
        $stmt->execute(['id' => $userId]);
        $contagens[$rotulo] = (int) $stmt->fetchColumn();
    } catch (Throwable $e) {
        $contagens[$rotulo] = 'erro: ' . mb_substr($e->getMessage(), 0, 120);
    }
}

$erros = array_values(array_filter(
    Logger::ultimosErros(60),
    static function (string $linha): bool {
        foreach (['"method":"CLI"', 't.php', 'tests/', 'teste_erro'] as $ruido) {
            if (str_contains($linha, $ruido)) {
                return false;
            }
        }
        return true;
    }
));
$erros = array_slice($erros, -15);
$diagnosticoTexto = 'SOMASE — diagnóstico de ' . date('d/m/Y H:i') . PHP_EOL
    . 'Usuário: #' . $userId . ' ' . ($usuario->name ?? '') . ' <' . ($usuario->email ?? '') . '>' . PHP_EOL
    . 'Migrations pendentes: ' . ($pendentes === [] ? 'nenhuma' : implode(', ', array_column($pendentes, 'file'))) . PHP_EOL
    . 'Contagens: ' . json_encode($contagens, JSON_UNESCAPED_UNICODE) . PHP_EOL
    . ($resultadoTeste ? 'Teste: ' . json_encode($resultadoTeste, JSON_UNESCAPED_UNICODE) . PHP_EOL : '')
    . 'Código do teste: ' . ($codigoTeste ?: '—') . PHP_EOL;
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Suporte técnico · SOMASE</title>
<style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body { margin: 0; padding: 28px 16px 60px; background: #07101f; color: #e8eef9;
        font-family: Inter, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; font-size: 14px; line-height: 1.55; }
    .wrap { max-width: 940px; margin: 0 auto; }
    .brand { width: 190px; display: block; margin-bottom: 18px; }
    h1 { font-size: 24px; margin: 0 0 6px; }
    h2 { font-size: 14px; margin: 28px 0 10px; color: #9db6d8; text-transform: uppercase; letter-spacing: .08em; }
    p.lead { color: #a9bcd8; margin: 0 0 18px; }
    .card { background: linear-gradient(180deg, rgba(18,37,74,.92), rgba(9,20,40,.96));
        border: 1px solid #1f3560; border-radius: 16px; padding: 18px 20px; }
    table { width: 100%; border-collapse: collapse; }
    td, th { padding: 8px 6px; border-bottom: 1px solid rgba(31,53,96,.7); text-align: left; vertical-align: top; }
    td:first-child { color: #9db6d8; width: 46%; }
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
    .btn.ghost { background: transparent; border: 1px solid #2b4a7d; color: #cfe0f8; }
    pre { margin: 0; padding: 14px; background: #050b16; border: 1px solid #1f3560; border-radius: 12px;
        font-size: 11px; line-height: 1.5; color: #9db6d8; white-space: pre-wrap; word-break: break-word; max-height: 340px; overflow: auto; }
    .foot { margin-top: 24px; font-size: 11px; color: #6d82a6; }
    a { color: #8fb6ff; }
</style>
</head>
<body>
<div class="wrap">
    <img class="brand" src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE">
    <h1>Suporte técnico</h1>
    <p class="lead">Confira o estado da sua conta no banco, teste a gravação e veja os últimos erros registrados.</p>

    <?php if ($pendentes !== []): ?>
        <div class="msg err">
            <strong>Banco desatualizado.</strong> Falta(m):
            <?= htmlspecialchars(implode(', ', array_map(static fn (array $p): string => $p['label'], $pendentes))) ?>.
            <?php if (Auth::canAccessAdmin()): ?>
                <a href="/_atualizar.php">Abrir atualizador</a>.
            <?php else: ?>
                Peça ao administrador para abrir <code>/_atualizar.php</code>.
            <?php endif; ?>
        </div>
    <?php else: ?>
        <div class="msg ok">Estrutura do banco em dia: nenhuma migration pendente.</div>
    <?php endif; ?>

    <h2>Identificação</h2>
    <div class="card">
        <table>
            <tr><td>Usuário</td><td>#<?= $userId ?> · <?= htmlspecialchars((string) ($usuario->name ?? '')) ?></td></tr>
            <tr><td>E-mail</td><td><?= htmlspecialchars((string) ($usuario->email ?? '')) ?></td></tr>
            <tr><td>Perfil</td><td><?= htmlspecialchars((string) ($usuario->role_slug ?? $usuario->role ?? '—')) ?></td></tr>
            <tr><td>Código da requisição</td><td><code><?= htmlspecialchars(Logger::requestId()) ?></code></td></tr>
        </table>
    </div>

    <h2>Seus dados no banco</h2>
    <div class="card">
        <table>
            <?php foreach ($contagens as $rotulo => $total): ?>
                <tr>
                    <td><?= htmlspecialchars($rotulo) ?></td>
                    <td class="<?= is_int($total) ? 'ok' : 'bad' ?>"><?= htmlspecialchars((string) $total) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <p class="foot" style="margin-bottom:0">Se você cadastrou uma conta e ela não aparece, o número acima continua em zero — isso indica que a gravação falhou. Use o teste abaixo para ver o motivo exato.</p>
    </div>

    <h2>Teste de gravação</h2>
    <div class="card">
        <p style="margin-top:0">O teste insere uma conta temporária e desfaz tudo em seguida (transação com rollback). Nada fica gravado.</p>
        <form method="post">
            <input type="hidden" name="acao" value="teste">
            <button class="btn" type="submit">Testar gravação no banco</button>
        </form>

        <?php if ($resultadoTeste !== null): ?>
            <table style="margin-top:14px">
                <tr><th>Passo</th><th>Resultado</th><th>Detalhe</th></tr>
                <?php foreach ($resultadoTeste as [$passo, $estado, $detalhe]): ?>
                    <tr>
                        <td><?= htmlspecialchars($passo) ?></td>
                        <td class="<?= $estado === 'ok' ? 'ok' : 'bad' ?>"><?= htmlspecialchars($estado) ?></td>
                        <td><small><?= htmlspecialchars((string) $detalhe) ?></small></td>
                    </tr>
                <?php endforeach; ?>
            </table>
            <p class="foot">Código do teste: <code><?= htmlspecialchars($codigoTeste) ?></code> — o mesmo código está no log. Informe-o no suporte.</p>
        <?php endif; ?>
    </div>

    <h2>Últimos erros e avisos do log</h2>
    <div class="card">
        <?php if ($erros === []): ?>
            <p class="ok">Nenhum erro ou aviso registrado.</p>
        <?php else: ?>
            <pre><?= htmlspecialchars(implode("\n", $erros)) ?></pre>
        <?php endif; ?>
        <p class="foot">O log completo fica em <code>storage/logs/app-AAAA-MM-DD.log</code> e <code>erros-AAAA-MM-DD.log</code>. Erros de execução por linha de comando (testes automatizados) são omitidos aqui.
            <?php if (Auth::canAccessAdmin()): ?>
                <a href="/_logs.php">Abrir visualizador de logs</a>.
            <?php endif; ?>
        </p>
    </div>

    <h2>Diagnóstico para copiar</h2>
    <div class="card">
        <pre id="diag"><?= htmlspecialchars($diagnosticoTexto) ?></pre>
        <button class="btn ghost" type="button" onclick="navigator.clipboard.writeText(document.getElementById('diag').innerText).then(()=>{this.textContent='Copiado!'})">Copiar diagnóstico</button>
    </div>

    <p class="foot">Página de uso interno. Apague <code>public/_suporte.php</code> se não quiser mantê-la no servidor.</p>
</div>
</body>
</html>
