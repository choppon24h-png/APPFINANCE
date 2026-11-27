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
        $messages = $_SESSION['_flash'] ?? [];
        unset($_SESSION['_flash']);
        return $messages;
    }
}
