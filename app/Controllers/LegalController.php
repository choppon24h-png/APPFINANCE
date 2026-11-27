<?php
namespace App\Controllers;

use App\Core\Controller;

/**
 * Paginas institucionais publicas.
 *
 * O texto e um MODELO de referencia: precisa de revisao juridica antes
 * de valer como documento oficial (por isso o selo de rascunho).
 */
class LegalController extends Controller
{
    public function termos(): void
    {
        $this->view('legal/index', [
            'title'   => 'Termos de uso',
            'pagina'  => 'termos',
            'contato' => $this->contato(),
        ], 'site');
    }

    public function privacidade(): void
    {
        $this->view('legal/index', [
            'title'   => 'Política de privacidade',
            'pagina'  => 'privacidade',
            'contato' => $this->contato(),
        ], 'site');
    }

    private function contato(): string
    {
        $email = trim((string) ($_ENV['MAIL_FROM'] ?? ''));
        return $email !== '' ? $email : 'contato@somase.com';
    }
}
