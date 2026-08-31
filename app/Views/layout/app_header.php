<?php
use App\Core\Auth;
$usuarioLogado = Auth::user();
$uriAtual = strtok($_SERVER['REQUEST_URI'], '?');
$flash = $_SESSION['flash'] ?? null;
unset($_SESSION['flash']);
$menu = [
    ['/dashboard', 'Visão geral', 'home'],
    ['/lancamentos/novo', 'Novo lançamento', 'plus'],
    ['/lancamentos', 'Lançamentos', 'list'],
    ['/contas', 'Contas', 'wallet'],
    ['/investimentos', 'Investimentos', 'chart'],
    ['/categorias', 'Categorias', 'tag'],
    ['/centros-custo', 'Centros de custo', 'layers'],
];
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="theme-color" content="#0f4c81">
    <meta name="description" content="APPFINANCE: sua visão simples e segura das finanças.">
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" href="/assets/icons/icon.svg" type="image/svg+xml">
    <title><?= htmlspecialchars($title ?? ($_ENV['APP_NAME'] ?? 'APPFINANCE')) ?> · <?= htmlspecialchars($_ENV['APP_NAME'] ?? 'APPFINANCE') ?></title>
    <link href="/assets/css/app.css" rel="stylesheet">
</head>
<body>
<div class="app-shell">
    <div class="mobile-backdrop" data-nav-close></div>
    <aside class="sidebar" id="app-sidebar">
        <div class="brand-row">
            <a href="/dashboard" class="brand"><span class="brand-mark">A</span><span><?= htmlspecialchars($_ENV['APP_NAME'] ?? 'APPFINANCE') ?></span></a>
            <button class="icon-button sidebar-close" type="button" data-nav-close aria-label="Fechar menu">×</button>
        </div>
        <p class="sidebar-caption">Controle financeiro simples</p>
        <nav class="main-nav" aria-label="Navegação principal">
            <?php foreach ($menu as [$href, $label, $icon]): ?>
                <a class="nav-item <?= $uriAtual === $href || ($href !== '/dashboard' && str_starts_with($uriAtual, $href)) ? 'active' : '' ?>" href="<?= $href ?>">
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
            <div class="topbar-title"><span class="eyebrow">APPFINANCE</span><h1><?= htmlspecialchars($title ?? '') ?></h1></div>
            <a class="quick-add" href="/lancamentos/novo" aria-label="Novo lançamento"><span>+</span><b>Novo</b></a>
        </header>
        <main class="page-content">
            <?php if ($flash): ?><div class="flash flash-<?= htmlspecialchars($flash['type']) ?>" role="status"><?= htmlspecialchars($flash['message']) ?><button type="button" class="flash-close" data-dismiss>×</button></div><?php endif; ?>
