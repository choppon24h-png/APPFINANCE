<?php
use App\Core\Auth;
$usuarioLogado = Auth::user();
$uriAtual = strtok($_SERVER['REQUEST_URI'], '?');
$flash = $_SESSION['flash'] ?? null;
unset($_SESSION['flash']);
$appName = 'SOMASE';
$menu = [
    ['/dashboard', 'Visão geral', 'home'],
    ['/lancamentos/novo', 'Novo lançamento', 'plus'],
    ['/lancamentos', 'Lançamentos', 'list'],
    ['/contas', 'Contas', 'wallet'],
    ['/investimentos', 'Investimentos', 'chart'],
    ['/categorias', 'Categorias', 'tag'],
    ['/centros-custo', 'Centros de custo', 'layers'],
    ['/relatorios', 'Relatórios', 'chart'],
];

// Marca apenas o item mais especifico do menu (evita dois itens ativos)
$hrefAtivo = '';
foreach (array_column($menu, 0) as $hrefMenu) {
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
            <?php foreach ($menu as [$href, $label, $icon]): ?>
                <a class="nav-item <?= $hrefAtivo === $href ? 'active' : '' ?>" href="<?= $href ?>"<?= $hrefAtivo === $href ? ' aria-current="page"' : '' ?>>
                    <span class="nav-icon" data-icon="<?= $icon ?>" aria-hidden="true"></span><span><?= $label ?></span>
                </a>
            <?php endforeach; ?>
            <?php if (Auth::can('manage_users')): ?>
                <a class="nav-item <?= str_starts_with($uriAtual, '/usuarios') ? 'active' : '' ?>" href="/usuarios"><span class="nav-icon" data-icon="users" aria-hidden="true"></span><span>Usuários</span></a>
            <?php endif; ?>
        </nav>
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
            <div class="topbar-title"><span class="eyebrow">SOMASE</span><h1><?= htmlspecialchars($title ?? '') ?></h1></div>
            <a class="quick-add" href="/lancamentos/novo" aria-label="Novo lançamento"><span aria-hidden="true">+</span><b>Novo</b></a>
        </header>
        <main class="page-content">
            <?php if ($flash): ?><div class="flash flash-<?= htmlspecialchars($flash['type']) ?>" role="status"><?= htmlspecialchars($flash['message']) ?><button type="button" class="flash-close" data-dismiss aria-label="Fechar aviso">×</button></div><?php endif; ?>
