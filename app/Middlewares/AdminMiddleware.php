<?php
namespace App\Middlewares;

use App\Core\Auth;
use App\Core\ErrorPage;
use App\Core\Middleware;

/**
 * Restringe o painel administrativo a superadmin ou a quem tem a
 * permissao access_admin_panel. Responde 403 no visual do sistema.
 */
class AdminMiddleware extends Middleware
{
    public function handle(): void
    {
        if (!Auth::check()) {
            header('Location: /login');
            exit;
        }

        if (!Auth::canAccessAdmin()) {
            ErrorPage::forbidden('Esta área é restrita aos administradores do SOMASE.');
        }
    }
}
