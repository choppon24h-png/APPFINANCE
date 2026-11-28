<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Logger;
use App\Models\Category;
use App\Models\CostCenter;
use App\Models\Transaction;
use App\Services\Documents\AttachmentStorage;
use App\Services\Documents\CodeParser;
use App\Services\Documents\DocumentAnalyzer;
use Throwable;

/**
 * Leitura de documentos (boleto/conta/cupom) e entrega protegida de anexos.
 * O OCR roda no navegador; aqui so interpretamos o texto/codigos recebidos.
 */
class DocumentController extends Controller
{
    private function userId(): int
    {
        return (int) Auth::user()->id;
    }

    /** POST /lancamentos/ler-documento (JSON) */
    public function read(): void
    {
        $payload = $this->payload();
        $texto = trim((string) ($payload['text'] ?? ''));
        $codigoDigitado = CodeParser::digits((string) ($payload['code'] ?? ''));
        $codigos = [];
        foreach ((array) ($payload['codes'] ?? []) as $c) {
            $d = CodeParser::digits((string) $c);
            if (strlen($d) >= 20) {
                $codigos[] = $d;
            }
        }
        if ($codigoDigitado !== '') {
            $codigos[] = $codigoDigitado;
        }
        if ($texto === '' && !$codigos) {
            $this->json(['ok' => false, 'error' => 'Envie o texto do documento ou o código de barras.'], 422);
            return;
        }
        if (strlen($texto) > 20000) {
            $texto = substr($texto, 0, 20000);
        }

        try {
            $codigo = CodeParser::detect($codigos, $texto);
            $userId = $this->userId();
            $transacoes = new Transaction();
            $duplicado = false;
            if ($codigo && !empty($codigo['document_code'])) {
                $duplicado = $transacoes->existsDocumentCode($userId, (string) $codigo['document_code']);
            }
            $resultado = DocumentAnalyzer::analyze($codigo, $texto, [
                'today' => date('Y-m-d'),
                'duplicate' => $duplicado,
                'cost_centers' => (new CostCenter())->forUser($userId),
                'categories' => (new Category())->forUser($userId),
            ]);
            Logger::debug('documento.lido', [
                'user_id' => $userId,
                'kind' => $resultado['suggestion']['kind'] ?? null,
                'code_len' => $codigo ? strlen((string) $codigo['document_code']) : 0,
                'text_len' => strlen($texto),
            ]);
            $this->json($resultado);
        } catch (Throwable $e) {
            Logger::error('documento.erro', ['erro' => $e->getMessage()]);
            $this->json(['ok' => false, 'error' => 'Não foi possível interpretar o documento.'], 500);
        }
    }

    /**
     * POST /lancamentos/ler-documento/ocr
     * Fallback opcional: usa OCR.space quando o Tesseract do navegador falha.
     * A chave fica so no servidor (.env), nunca no JavaScript.
     */
    public function ocr(): void
    {
        $chave = trim((string) ($_ENV['OCR_SPACE_API_KEY'] ?? ''));
        if ($chave === '') {
            $this->json(['ok' => false, 'error' => 'OCR alternativo não configurado.'], 503);
            return;
        }
        if (empty($_FILES['file']['tmp_name']) || !is_uploaded_file($_FILES['file']['tmp_name'])) {
            $this->json(['ok' => false, 'error' => 'Envie uma imagem ou PDF de até 1 MB.'], 422);
            return;
        }
        if ((int) $_FILES['file']['size'] > 1024 * 1024) {
            $this->json(['ok' => false, 'error' => 'Para o OCR alternativo o arquivo deve ter até 1 MB.'], 422);
            return;
        }
        try {
            $curl = curl_init('https://api.ocr.space/parse/image');
            curl_setopt_array($curl, [
                CURLOPT_POST => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 40,
                CURLOPT_POSTFIELDS => [
                    'apikey' => $chave,
                    'language' => 'por',
                    'OCREngine' => (string) ($_ENV['OCR_SPACE_ENGINE'] ?? '2'),
                    'scale' => 'true',
                    'isTable' => 'false',
                    'file' => new \CURLFile($_FILES['file']['tmp_name'], (string) ($_FILES['file']['type'] ?? 'image/jpeg'), 'documento'),
                ],
            ]);
            $resposta = curl_exec($curl);
            $status = (int) curl_getinfo($curl, CURLINFO_HTTP_CODE);
            curl_close($curl);
            if (!is_string($resposta) || $status >= 400) {
                $this->json(['ok' => false, 'error' => 'O OCR alternativo não respondeu.'], 502);
                return;
            }
            $json = json_decode($resposta, true);
            $texto = '';
            foreach ((array) ($json['ParsedResults'] ?? []) as $parte) {
                $texto .= (string) ($parte['ParsedText'] ?? '');
            }
            $this->json(['ok' => $texto !== '', 'text' => $texto]);
        } catch (Throwable $e) {
            Logger::error('documento.ocr', ['erro' => $e->getMessage()]);
            $this->json(['ok' => false, 'error' => 'Falha no OCR alternativo.'], 502);
        }
    }

    /** GET /lancamentos/{id}/anexo[?baixar=1] */
    public function attachment(string $id): void
    {
        $transacao = (new Transaction())->findForUser((int) $id, $this->userId());
        if (!$transacao) {
            http_response_code(404);
            exit('Anexo não encontrado.');
        }
        $storage = new AttachmentStorage();
        $abs = $storage->absolute($transacao->attachment_path ?? null);
        if ($abs === null) {
            http_response_code(404);
            exit('Este lançamento não possui anexo.');
        }
        $mime = $storage->mimeOf($abs);
        $nome = 'anexo-' . $transacao->id . '.' . pathinfo($abs, PATHINFO_EXTENSION);
        $baixar = !empty($_GET['baixar']);
        header('Content-Type: ' . $mime);
        header('Content-Length: ' . (string) filesize($abs));
        header('Content-Disposition: ' . ($baixar ? 'attachment' : 'inline') . '; filename="' . $nome . '"');
        header('X-Content-Type-Options: nosniff');
        header('Content-Security-Policy: sandbox');
        header('Cache-Control: private, max-age=300');
        readfile($abs);
        exit;
    }

    /** Corpo JSON (ou POST tradicional, para testes com curl). */
    private function payload(): array
    {
        $raw = file_get_contents('php://input') ?: '';
        if ($raw !== '' && str_contains((string) ($_SERVER['CONTENT_TYPE'] ?? ''), 'application/json')) {
            $json = json_decode($raw, true);
            return is_array($json) ? $json : [];
        }
        return $_POST;
    }
}
