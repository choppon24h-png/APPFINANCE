<?php
use App\Core\Router;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\CsrfMiddleware;
use App\Middlewares\PermissionMiddleware;
use App\Middlewares\SessionTimeoutMiddleware;

Router::get('/', fn() => header('Location: /dashboard'));

Router::group(['middleware' => [CsrfMiddleware::class]], function () {
    Router::get('/login', 'AuthController@showLogin');
    Router::post('/login', 'AuthController@login');
});
Router::get('/logout', 'AuthController@logout');

Router::group(['middleware' => [AuthMiddleware::class, SessionTimeoutMiddleware::class, CsrfMiddleware::class]], function () {
    Router::get('/selecionar-empresa', 'AuthController@selectTenant');
    Router::post('/selecionar-empresa', 'AuthController@setTenant');
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
    });

    Router::group(['prefix' => '/usuarios'], function () {
        Router::get('', 'UsuariosController@index', [[PermissionMiddleware::class, 'manage_users']]);
        Router::get('/create', 'UsuariosController@create', [[PermissionMiddleware::class, 'manage_users']]);
        Router::post('', 'UsuariosController@store', [[PermissionMiddleware::class, 'manage_users']]);
        Router::get('/{id}/edit', 'UsuariosController@edit', [[PermissionMiddleware::class, 'manage_users']]);
        Router::post('/{id}/update', 'UsuariosController@update', [[PermissionMiddleware::class, 'manage_users']]);
        Router::post('/{id}/toggle', 'UsuariosController@toggleStatus', [[PermissionMiddleware::class, 'manage_users']]);
        Router::post('/{id}/remover', 'UsuariosController@remover', [[PermissionMiddleware::class, 'manage_users']]);
    });
});
