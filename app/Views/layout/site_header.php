<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="theme-color" content="#07101f">
    <meta name="color-scheme" content="dark">
    <meta name="description" content="SOMASE — Controle Financeiro. Termos de uso e política de privacidade.">
    <meta name="robots" content="index, follow">
    <link rel="icon" href="/favicon.ico" sizes="any">
    <link rel="icon" type="image/png" sizes="32x32" href="/assets/icons/favicon-32.png">
    <link rel="apple-touch-icon" href="/assets/icons/apple-touch-icon.png">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <title><?= htmlspecialchars($title ?? 'SOMASE') ?> · SOMASE</title>
    <link href="/assets/css/app.css" rel="stylesheet">
</head>
<body class="site-body">
<header class="site-header">
    <a class="site-brand" href="/login" aria-label="SOMASE — Controle Financeiro">
        <img src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE" width="230" height="78">
    </a>
    <nav class="site-nav" aria-label="Navegação institucional">
        <a href="/termos">Termos de uso</a>
        <a href="/privacidade">Privacidade</a>
        <a class="button button-primary" href="/login">Entrar</a>
    </nav>
</header>
<main class="site-main">
