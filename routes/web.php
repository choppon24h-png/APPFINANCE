<?php
use App\Core\Router;
use App\Middlewares\AdminMiddleware;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\CsrfMiddleware;
use App\Middlewares\ProfileCompletionMiddleware;
use App\Middlewares\SessionTimeoutMiddleware;

/* ------------------------------------------------------------------
 | Rotas publicas (sem sessao)
 | ------------------------------------------------------------------ */
Router::publicRoutes([
    '/login',
    '/logout',
    '/cadastro',
    '/cadastro/completar',
    '/termos',
    '/privacidade',
    '/auth/*',
]);

Router::get('/', fn() => header('Location: /dashboard'));

Router::group(['middleware' => [CsrfMiddleware::class]], function () {
    Router::get('/login', 'AuthController@showLogin');
    Router::post('/login', 'AuthController@login');

    Router::get('/cadastro', 'RegisterController@show');
    Router::post('/cadastro', 'RegisterController@store');
});

Router::get('/logout', 'AuthController@logout');

// Login social (OAuth 2.0 + PKCE + OIDC)
Router::get('/auth/{provider}', 'OAuthController@start');
Router::get('/auth/{provider}/callback', 'OAuthController@callback');

// Paginas institucionais
Router::get('/termos', 'LegalController@termos');
Router::get('/privacidade', 'LegalController@privacidade');

/* ------------------------------------------------------------------
 | Area autenticada
 | ------------------------------------------------------------------ */
Router::group([
    'middleware' => [AuthMiddleware::class, ProfileCompletionMiddleware::class, SessionTimeoutMiddleware::class, CsrfMiddleware::class],
], function () {
    Router::get('/selecionar-empresa', 'AuthController@selectTenant');
    Router::post('/selecionar-empresa', 'AuthController@setTenant');

    // Conclusao de cadastro (usuarios criados por Google/Microsoft)
    Router::get('/cadastro/completar', 'RegisterController@completeForm');
    Router::post('/cadastro/completar', 'RegisterController@completeStore');

    Router::get('/dashboard', 'DashboardController@index');

    Router::get('/lancamentos', 'TransactionController@index');
    Router::get('/lancamentos/novo', 'TransactionController@create');
    Router::post('/lancamentos', 'TransactionController@store');
    Router::get('/lancamentos/{id}/editar', 'TransactionController@edit');
    Router::post('/lancamentos/{id}/atualizar', 'TransactionController@update');
    Router::post('/lancamentos/{id}/excluir', 'TransactionController@destroy');
    Router::post('/lancamentos/{id}/duplicar', 'TransactionController@duplicate');
    Router::post('/lancamentos/{id}/status', 'TransactionController@status');
    Router::get('/transferencias/nova', 'TransactionController@transferForm');
    Router::post('/transferencias', 'TransactionController@transfer');

    Router::get('/contas', 'AccountController@index');
    Router::get('/contas/nova', 'AccountController@create');
    Router::post('/contas', 'AccountController@store');
    Router::get('/contas/{id}/editar', 'AccountController@edit');
    Router::post('/contas/{id}/atualizar', 'AccountController@update');
    Router::post('/contas/{id}/toggle', 'AccountController@toggle');
    Router::post('/contas/{id}/excluir', 'AccountController@destroy');

    Router::get('/investimentos', 'InvestmentController@index');
    Router::get('/investimentos/novo', 'InvestmentController@create');
    Router::post('/investimentos', 'InvestmentController@store');
    Router::get('/investimentos/{id}/resgatar', 'InvestmentController@redeemForm');
    Router::post('/investimentos/{id}/resgatar', 'InvestmentController@redeem');
    Router::get('/investimentos/{id}/rendimento', 'InvestmentController@returnForm');
    Router::post('/investimentos/{id}/rendimento', 'InvestmentController@addReturn');
    Router::get('/investimentos/{id}/historico', 'InvestmentController@history');

    Router::get('/categorias', 'CatalogController@categories');
    Router::post('/categorias', 'CatalogController@categoryStore');
    Router::post('/categorias/{id}/atualizar', 'CatalogController@categoryUpdate');
    Router::post('/categorias/{id}/toggle', 'CatalogController@categoryToggle');
    Router::post('/categorias/{id}/excluir', 'CatalogController@categoryDelete');

    Router::get('/centros-custo', 'CatalogController@costCenters');
    Router::post('/centros-custo', 'CatalogController@costCenterStore');
    Router::post('/centros-custo/{id}/atualizar', 'CatalogController@costCenterUpdate');
    Router::post('/centros-custo/{id}/toggle', 'CatalogController@costCenterToggle');
    Router::post('/centros-custo/{id}/excluir', 'CatalogController@costCenterDelete');

    Router::get('/relatorios', 'ReportController@index');
    Router::get('/relatorios/csv', 'ReportController@csv');

    Router::group(['prefix' => '/api'], function () {
        Router::get('/cnpj/{cnpj}', 'CnpjController@consultar');
        // Autocomplete de bancos (catalogo COMPE da migration 0005)
        Router::get('/bancos', 'BankController@search');
    });

    // Rota antiga de usuarios: agora aponta para o painel administrativo
    Router::get('/usuarios', fn() => header('Location: /admin/usuarios'));
    Router::get('/usuarios/create', fn() => header('Location: /admin/usuarios'));

    /* --------------------------------------------------------------
     | Painel administrativo (superadmin ou access_admin_panel)
     | -------------------------------------------------------------- */
    Router::group(['middleware' => [AdminMiddleware::class]], function () {
        Router::get('/admin', 'AdminController@index');

        Router::get('/admin/usuarios', 'AdminController@users');
        Router::get('/admin/usuarios/csv', 'AdminController@usersCsv');
        Router::get('/admin/usuarios/{id}', 'AdminController@show');
        Router::post('/admin/usuarios/{id}/atualizar', 'AdminController@update');
        Router::post('/admin/usuarios/{id}/toggle', 'AdminController@toggle');
        Router::post('/admin/usuarios/{id}/senha', 'AdminController@resetPassword');

        Router::get('/admin/auditoria', 'AdminController@audit');
    });
});
