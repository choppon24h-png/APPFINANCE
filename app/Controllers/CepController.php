<?php
namespace App\Controllers;

use App\Core\Controller;
use App\Services\CepService;

class CepController extends Controller
{
    /** GET /api/cep?cep=30130010 — usado pelo formulário de imóveis. */
    public function lookup(): void
    {
        $cep = CepService::normalize($_GET['cep'] ?? null);
        if ($cep === null) {
            $this->json(['ok' => false, 'error' => 'Informe um CEP com 8 dígitos.'], 422);
        }

        $service = new CepService();
        $endereco = $service->lookup($cep);
        if ($endereco === null) {
            $this->json([
                'ok' => false,
                'error' => 'CEP não encontrado. Confira o número ou preencha o endereço manualmente.',
                'providers_tried' => ['ViaCEP', 'BrasilAPI', 'OpenCEP'],
            ], 404);
        }

        $this->json(['ok' => true] + $endereco);
    }
}
