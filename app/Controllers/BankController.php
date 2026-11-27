<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Core\Logger;
use App\Models\Bank;
use Throwable;

/**
 * API interna do catalogo de bancos (autocomplete do formulario de conta).
 *
 * GET /api/bancos?q=nubank   -> { items: [ { code, ispb, name, fullName, logo } ] }
 */
class BankController extends Controller
{
    public function search(): void
    {
        $termo = mb_substr(trim((string) ($_GET['q'] ?? '')), 0, 60);

        try {
            $bancos = (new Bank())->search($termo, 12);
        } catch (Throwable $e) {
            // Sem a migration 0005 a tabela nao existe: o formulario continua
            // funcionando como campo de texto livre.
            Logger::warning('Falha ao consultar o catalogo de bancos', [
                'termo'   => $termo,
                'excecao' => get_class($e),
                'erro'    => $e->getMessage(),
            ]);
            $this->json(['items' => [], 'aviso' => 'Catálogo de bancos indisponível.']);
        }

        $itens = array_map(static function (object $banco): array {
            $codigo = $banco->compe !== null ? (string) $banco->compe : '';

            return [
                'code'     => $codigo,
                'ispb'     => (string) ($banco->ispb ?? ''),
                'label'    => Bank::rotulo($banco),
                'name'     => (string) ($banco->name ?? ''),
                'fullName' => (string) ($banco->full_name ?? ''),
                'logo'     => (string) ($banco->logo_url ?? ''),
            ];
        }, $bancos);

        $this->json(['items' => $itens, 'total' => count($itens)]);
    }
}
