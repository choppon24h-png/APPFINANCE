<?php
namespace App\Middlewares;

use App\Core\Auth;
use App\Core\ErrorPage;
use App\Core\Middleware;

/**
 * Restringe uma rota a usuarios com role 'superadmin' (acesso total,
 * independente de tenant). Util para paineis administrativos globais.
 */
class SuperAdminMiddleware extends Middleware {
    public function handle(): void {
        if (!Auth::check() || !Auth::isSuperAdmin()) {
            ErrorPage::forbidden('Acesso restrito ao administrador do sistema.');
        }
    }
}
