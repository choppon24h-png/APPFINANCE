<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta name="theme-color" content="#0f4c81">
    <meta name="description" content="APPFINANCE: controle financeiro simples e seguro.">
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" href="/assets/icons/icon.svg" type="image/svg+xml">
    <title><?= htmlspecialchars($title ?? ($_ENV['APP_NAME'] ?? 'APPFINANCE')) ?></title>
    <link href="/assets/css/app.css" rel="stylesheet">
</head>
<body>
<div class="auth-wrapper">
    <div class="auth-card">
        <div class="auth-brand"><span class="brand-mark">A</span><span><?= htmlspecialchars($_ENV['APP_NAME'] ?? 'APPFINANCE') ?></span></div>
