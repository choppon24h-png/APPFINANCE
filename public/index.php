<?php
/**
 * BASEAPP - Entry Point
 * Compativel com hospedagem compartilhada (Apache + PHP 8.x)
 *
 * Todo o fluxo roda dentro de um try/catch: qualquer excecao fora do
 * Router (rotas, middleware de tenant, Auth) tambem cai no ErrorHandler,
 * que registra o log completo e mostra a pagina de erro com codigo.
 */

// Carrega o bootstrap: paths, sessao, headers, autoload, env e handlers de erro
require_once dirname(__DIR__) . '/app/bootstrap.php';

use App\Core\Auth;
use App\Core\ErrorHandler;
use App\Core\Logger;
use App\Core\Router;
use App\Middlewares\TenantMiddleware;

try {
    $uriAtual = strtok($_SERVER['REQUEST_URI'], '?');

    // Rotas que nao precisam de autenticacao
    $rotasPublicas = [
        '/login', '/logout', '/cadastro', '/cadastro/completar',
        '/termos', '/privacidade',
        '/auth/google', '/auth/google/callback',
        '/auth/microsoft', '/auth/microsoft/callback',
    ];

    $ehPublica = false;
    foreach ($rotasPublicas as $pub) {
        if ($uriAtual === $pub || strpos($uriAtual, $pub) === 0) {
            $ehPublica = true;
            break;
        }
    }

    // Carrega rotas
    require_once BASE_PATH . '/routes/web.php';

    // Multi-tenant (opcional): carrega o TenantContext a partir da sessao
    // antes do controller ser chamado. Se o projeto for single-tenant,
    // remova este bloco e o TenantMiddleware.
    if (!$ehPublica && $uriAtual !== '/selecionar-empresa' && $uriAtual !== '/cadastro/completar' && Auth::check()) {
        (new TenantMiddleware())->handle();
    }

    // Despacha a requisicao
    Router::dispatch();
} catch (\Throwable $e) {
    // Rede de seguranca: nada escapa sem log e sem pagina amigavel
    Logger::debug('Excecao capturada no front controller', [
        'exception' => get_class($e),
        'message'   => $e->getMessage(),
    ]);
    ErrorHandler::render($e);
}
