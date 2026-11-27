<?php
namespace App\Middlewares;

use App\Core\Auth;
use App\Core\Middleware;
use App\Core\Schema;

/**
 * Usuarios criados por Google/Microsoft so entram no sistema depois de
 * informar a data de nascimento e aceitar os termos.
 * Enquanto faltar algum dado, tudo redireciona para /cadastro/completar.
 */
class ProfileCompletionMiddleware extends Middleware
{
    private const LIBERADAS = [
        '/cadastro/completar',
        '/logout',
        '/termos',
        '/privacidade',
    ];

    public function handle(): void
    {
        if (!Auth::check()) {
            return;
        }

        // Banco sem a 0004: deixa o AdminMiddleware/Controller explicar o que
        // falta em vez de mandar o administrador para "completar cadastro".
        if (!Schema::accessReady()) {
            return;
        }

        $user = Auth::user();
        if (!empty($user->birth_date) && !empty($user->terms_accepted_at)) {
            return;
        }

        // Contas administrativas sao criadas pelo proprio painel/seed, sem
        // data de nascimento: nao faz sentido bloquear o acesso delas.
        if (Auth::canAccessAdmin()) {
            return;
        }

        $uri = strtok($_SERVER['REQUEST_URI'] ?? '/', '?');

        if (in_array($uri, self::LIBERADAS, true)) {
            return;
        }

        header('Location: /cadastro/completar');
        exit;
    }
}
