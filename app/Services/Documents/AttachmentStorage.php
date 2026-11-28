<?php
namespace App\Services\Documents;

use RuntimeException;

/**
 * Guarda os anexos dos lancamentos fora de public/ e entrega apenas por
 * rota autenticada (GET /lancamentos/{id}/anexo).
 *
 * Caminho: storage/uploads/u{user_id}/AAAA/MM/{24 hex}.{ext}
 * Nada de binario no repositorio e nenhum arquivo executavel: a extensao e
 * derivada do MIME real (finfo), nunca do nome enviado pelo navegador.
 */
class AttachmentStorage
{
    private const MIMES = [
        'application/pdf' => 'pdf',
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/gif' => 'gif',
        'image/heic' => 'heic',
        'image/heif' => 'heif',
        'image/tiff' => 'tif',
    ];

    private string $root;

    public function __construct(?string $root = null)
    {
        $this->root = rtrim($root ?? (defined('STORAGE_PATH') ? STORAGE_PATH : dirname(__DIR__, 3) . '/storage'), '/') . '/uploads';
    }

    public function maxBytes(): int
    {
        $mb = (int) ($_ENV['ATTACHMENT_MAX_MB'] ?? 10);
        if ($mb < 1 || $mb > 50) {
            $mb = 10;
        }
        return $mb * 1024 * 1024;
    }

    public function maxMb(): int
    {
        return (int) round($this->maxBytes() / 1024 / 1024);
    }

    /**
     * @param array{name?:string,type?:string,tmp_name?:string,error?:int,size?:int} $file
     * @return string caminho relativo gravado no banco
     */
    public function save(int $userId, array $file): string
    {
        $erro = (int) ($file['error'] ?? UPLOAD_ERR_NO_FILE);
        if ($erro === UPLOAD_ERR_NO_FILE) {
            throw new RuntimeException('Nenhum arquivo enviado.');
        }
        if ($erro !== UPLOAD_ERR_OK) {
            throw new RuntimeException(match ($erro) {
                UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE => 'Arquivo maior que o limite do servidor.',
                UPLOAD_ERR_PARTIAL => 'O envio do arquivo foi interrompido. Tente novamente.',
                default => 'Não foi possível receber o arquivo (código ' . $erro . ').',
            });
        }
        $tmp = (string) ($file['tmp_name'] ?? '');
        if ($tmp === '' || !is_uploaded_file($tmp)) {
            throw new RuntimeException('Arquivo temporário inválido.');
        }
        $tamanho = (int) ($file['size'] ?? filesize($tmp));
        if ($tamanho <= 0) {
            throw new RuntimeException('Arquivo vazio.');
        }
        if ($tamanho > $this->maxBytes()) {
            throw new RuntimeException('O anexo deve ter no máximo ' . $this->maxMb() . ' MB.');
        }
        $finfo = new \finfo(FILEINFO_MIME_TYPE);
        $mime = (string) $finfo->file($tmp);
        if (!isset(self::MIMES[$mime])) {
            throw new RuntimeException('Formato não aceito. Envie PDF, JPG, PNG, WEBP ou HEIC.');
        }
        $ext = self::MIMES[$mime];
        $rel = sprintf('u%d/%s/%s/%s.%s', $userId, date('Y'), date('m'), bin2hex(random_bytes(12)), $ext);
        $destino = $this->root . '/' . $rel;
        $dir = dirname($destino);
        if (!is_dir($dir) && !@mkdir($dir, 0775, true) && !is_dir($dir)) {
            throw new RuntimeException('Não foi possível criar a pasta de anexos.');
        }
        if (!move_uploaded_file($tmp, $destino)) {
            throw new RuntimeException('Não foi possível gravar o anexo no servidor.');
        }
        @chmod($destino, 0644);
        return $rel;
    }

    /** Caminho absoluto seguro (null se o caminho for suspeito ou nao existir). */
    public function absolute(?string $rel): ?string
    {
        $rel = (string) $rel;
        if ($rel === '' || !preg_match('#^u\d+/\d{4}/\d{2}/[a-f0-9]{24}\.(pdf|jpg|png|webp|gif|heic|heif|tif)$#', $rel)) {
            return null;
        }
        $abs = $this->root . '/' . $rel;
        return is_file($abs) ? $abs : null;
    }

    public function mimeOf(string $abs): string
    {
        $finfo = new \finfo(FILEINFO_MIME_TYPE);
        $mime = (string) $finfo->file($abs);
        return isset(self::MIMES[$mime]) ? $mime : 'application/octet-stream';
    }

    public function delete(?string $rel): void
    {
        $abs = $this->absolute($rel);
        if ($abs !== null) {
            @unlink($abs);
        }
    }

    public function isPdf(?string $rel): bool
    {
        $abs = $this->absolute($rel);
        return $abs !== null && str_ends_with(strtolower($abs), '.pdf');
    }
}
