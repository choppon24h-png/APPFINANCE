<?php
use App\Core\Auth;
use App\Core\Flash;
use App\Core\Schema;
$usuarioLogado = Auth::user();

// Aviso de banco desatualizado: consulta no maximo a cada 5 minutos e
// guarda na sessao para nao pesar nas paginas.
$schemaPendentes = [];
if (!isset($_SESSION['_schema_pend'], $_SESSION['_schema_pend_ts'])
    || (time() - (int) $_SESSION['_schema_pend_ts']) > 300) {
    try {
        $schemaPendentes = Schema::pending();
    } catch (\Throwable $e) {
        $schemaPendentes = [];
    }
    $_SESSION['_schema_pend'] = $schemaPendentes;
    $_SESSION['_schema_pend_ts'] = time();
} elseif (is_array($_SESSION['_schema_pend'] ?? null)) {
    $schemaPendentes = $_SESSION['_schema_pend'];
}
$uriAtual = strtok($_SERVER['REQUEST_URI'], '?');
$flash = null;
$flashPendentes = Flash::pull();
if ($flashPendentes) {
    $flash = ['type' => $flashPendentes[0]['type'], 'message' => $flashPendentes[0]['message']];
}
$appName = 'SOMASE';
$menu = [
    ['/dashboard', 'Visão geral', 'home'],
    ['/lancamentos/novo', 'Novo lançamento', 'plus'],
    ['/lancamentos', 'Lançamentos', 'list'],
    ['/contas', 'Contas', 'wallet'],
    ['/investimentos', 'Investimentos', 'trend'],
    ['/investimentos/tipos', 'Tipos de investimento', 'trend', true],
    ['/categorias', 'Categorias', 'tag'],
    ['/formas-pagamento', 'Formas de pagamento', 'wallet', true],
    ['/centros-custo', 'Imóveis e centros', 'layers'],
    ['/relatorios', 'Relatórios', 'chart'],
];
$menuAdmin = Auth::canAccessAdmin() ? [
    ['/admin', 'Visão geral', 'shield'],
    ['/admin/usuarios', 'Usuários', 'users'],
    ['/admin/auditoria', 'Auditoria', 'clipboard'],
] : [];

// Marca apenas o item mais especifico do menu (evita dois itens ativos)
$hrefAtivo = '';
foreach (array_column(array_merge($menu, $menuAdmin), 0) as $hrefMenu) {
    $casa = $uriAtual === $hrefMenu || str_starts_with($uriAtual, rtrim($hrefMenu, '/') . '/');
    if ($casa && strlen($hrefMenu) > strlen($hrefAtivo)) {
        $hrefAtivo = $hrefMenu;
    }
}
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="theme-color" content="#07101f">
    <meta name="color-scheme" content="dark">
    <meta name="description" content="SOMASE — Controle Financeiro: receitas, despesas, contas e investimentos em um só lugar.">
    <meta property="og:title" content="SOMASE — Controle Financeiro">
    <meta property="og:description" content="Clareza sobre o seu dinheiro: saldo, receitas, despesas e investimentos.">
    <meta property="og:image" content="/assets/brand/somase-og.png">
    <meta property="og:type" content="website">
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" href="/favicon.ico" sizes="any">
    <link rel="icon" type="image/png" sizes="32x32" href="/assets/icons/favicon-32.png">
    <link rel="apple-touch-icon" href="/assets/icons/apple-touch-icon.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <title><?= htmlspecialchars($title ?? $appName) ?> · <?= $appName ?></title>
    <link href="/assets/css/app.css" rel="stylesheet">
</head>
<body>
<div class="app-shell">
    <div class="mobile-backdrop" data-nav-close></div>
    <aside class="sidebar" id="app-sidebar">
        <div class="brand-row">
            <a href="/dashboard" class="brand" aria-label="SOMASE — Visão geral">
                <img src="/assets/brand/somase-wordmark-light.png" alt="SOMASE" width="136" height="30">
            </a>
            <button class="icon-button sidebar-close" type="button" data-nav-close aria-label="Fechar menu">×</button>
        </div>
        <p class="sidebar-caption">Controle Financeiro</p>
        <nav class="main-nav" aria-label="Navegação principal">
            <?php foreach ($menu as $item): [$href, $label, $icon] = $item; $sub = !empty($item[3]); ?>
                <a class="nav-item <?= $sub ? 'nav-sub' : '' ?> <?= $hrefAtivo === $href ? 'active' : '' ?>" href="<?= $href ?>"<?= $hrefAtivo === $href ? ' aria-current="page"' : '' ?>>
                    <span class="nav-icon" data-icon="<?= $icon ?>" aria-hidden="true"></span><span><?= $sub ? '↳ ' : '' ?><?= $label ?></span>
                </a>
            <?php endforeach; ?>
        </nav>
        <?php if ($menuAdmin): ?>
            <nav class="main-nav nav-admin" aria-label="Administração">
                <p class="nav-section-title">Administração</p>
                <?php foreach ($menuAdmin as [$href, $label, $icon]): ?>
                    <a class="nav-item <?= $hrefAtivo === $href ? 'active' : '' ?>" href="<?= $href ?>"<?= $hrefAtivo === $href ? ' aria-current="page"' : '' ?>>
                        <span class="nav-icon" data-icon="<?= $icon ?>" aria-hidden="true"></span><span><?= $label ?></span>
                    </a>
                <?php endforeach; ?>
            </nav>
        <?php endif; ?>
        <div class="sidebar-bottom">
            <div class="user-mini"><span class="avatar"><?= htmlspecialchars(mb_strtoupper(mb_substr($usuarioLogado->name ?? 'U', 0, 1))) ?></span><div><strong><?= htmlspecialchars($usuarioLogado->name ?? '') ?></strong><small><?= htmlspecialchars($usuarioLogado->role_name ?? 'Usuário') ?></small></div></div>
            <a href="/logout" class="logout-link"><span class="nav-icon" data-icon="logout" aria-hidden="true"></span>Sair</a>
        </div>
    </aside>

    <div class="app-main">
        <header class="topbar">
            <button class="icon-button menu-trigger" type="button" data-nav-open aria-label="Abrir menu"><span class="hamburger"></span></button>
            <a class="topbar-brand" href="/dashboard" aria-label="SOMASE — Visão geral">
                <img src="/assets/icons/icon-192.png" alt="" width="26" height="26" aria-hidden="true">
                <img src="/assets/brand/somase-wordmark-light.png" alt="SOMASE" width="91" height="20">
            </a>
            <div class="topbar-title"><span class="eyebrow"><?= Auth::canAccessAdmin() ? 'SOMASE · Administração' : 'SOMASE' ?></span><h1><?= htmlspecialchars($title ?? '') ?></h1></div>
            <?php if (Auth::canAccessAdmin() && str_starts_with($uriAtual, '/admin')): ?>
                <a class="quick-add" href="/admin/usuarios" aria-label="Ver usuários"><span aria-hidden="true">◎</span><b>Usuários</b></a>
            <?php else: ?>
                <a class="quick-add" href="/lancamentos/novo" aria-label="Novo lançamento"><span aria-hidden="true">+</span><b>Novo</b></a>
            <?php endif; ?>
        </header>
        <main class="page-content">
            <?php if ($flash): ?><div class="flash flash-<?= htmlspecialchars($flash['type']) ?>" role="status"><?= htmlspecialchars($flash['message']) ?><button type="button" class="flash-close" data-dismiss aria-label="Fechar aviso">×</button></div><?php endif; ?>
            <?php if ($schemaPendentes): ?>
                <?php
                $pend = $schemaPendentes[0];
                $itens = array_slice($pend['missing'] ?? [], 0, 3);
                $texto = ($pend['label'] ?? $pend['file'] ?? 'migration') . ($itens ? ' — falta ' . implode(', ', $itens) : '');
                ?>
                <div class="flash flash-error" role="alert">
                    <strong>Banco desatualizado:</strong> <?= htmlspecialchars($texto) ?>.
                    <a href="/_atualizar.php" style="color:inherit;text-decoration:underline">Abrir atualizador</a>
                </div>
            <?php endif; ?>
