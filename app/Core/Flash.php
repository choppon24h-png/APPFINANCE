<?php
namespace App\Core;

/**
 * Mensagens de uma unica exibicao (pos-redirect).
 * Guardadas na sessao e consumidas pelo layout.
 */
class Flash
{
    public static function set(string $type, string $message): void
    {
        $_SESSION['_flash'][] = ['type' => $type, 'message' => $message];
    }

    public static function success(string $message): void
    {
        self::set('success', $message);
    }

    public static function error(string $message): void
    {
        self::set('error', $message);
    }

    public static function info(string $message): void
    {
        self::set('info', $message);
    }

    /** Retorna e limpa as mensagens pendentes. */
    public static function pull(): array
    {
        // Aceita a chave nova (_flash) e a antiga (flash), usada por telas
        // antigas/controllers que ainda gravam direto na sessao.
        $messages = array_merge($_SESSION['_flash'] ?? [], $_SESSION['flash'] ?? []);
        unset($_SESSION['_flash'], $_SESSION['flash']);
        return array_values(array_filter($messages, static function ($m) {
            return is_array($m) && isset($m['message']) && $m['message'] !== '';
        }));
    }
}
