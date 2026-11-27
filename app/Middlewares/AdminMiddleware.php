<?php
namespace App\Middlewares;

use App\Core\Auth;
use App\Core\ErrorPage;
use App\Core\Middleware;
use App\Core\Schema;

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

        // Codigo novo + banco sem a migration 0004: 503 explicativo, nunca 500
        if (!Schema::accessReady()) {
            ErrorPage::outdatedSchema(Schema::missingLabel(), \App\Core\Logger::requestId());
        }

        if (!Auth::canAccessAdmin()) {
            ErrorPage::forbidden('Esta área é restrita aos administradores do SOMASE.');
        }
    }
}
