<?php
namespace App\Middlewares;

use App\Core\Middleware;

class CsrfMiddleware extends Middleware {
    public function handle(): void {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            // Formularios tradicionais mandam _csrf_token no corpo; o JS de
            // leitura de documentos/importacao manda no cabecalho X-CSRF-Token
            // (o corpo e JSON e nao passa por $_POST).
            $token = (string) ($_POST['_csrf_token'] ?? ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? ''));
            if (!hash_equals($_SESSION['csrf_token'] ?? '', $token)) {
                http_response_code(403);
                exit('CSRF token invalido.');
            }
        }

        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
    }
}
