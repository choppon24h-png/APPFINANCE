<?php
namespace App\Support;

/** Gera slugs estaveis para catalogos (formas de pagamento, tipos de investimento). */
final class Slug
{
    public static function make(string $text, string $fallback = 'item'): string
    {
        $text = trim($text);
        if (function_exists('iconv')) {
            $convertido = @iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $text);
            if ($convertido !== false) {
                $text = $convertido;
            }
        }
        $text = strtolower($text);
        $text = preg_replace('/[^a-z0-9]+/', '_', $text) ?? '';
        $text = trim($text, '_');
        $text = substr($text, 0, 40);
        return $text !== '' ? $text : $fallback;
    }

    /** Garante um slug unico dentro da lista informada (sufixo _2, _3...). */
    public static function unique(string $slug, array $existentes): string
    {
        $base = substr($slug, 0, 36);
        $tentativa = $base;
        $i = 2;
        while (in_array($tentativa, $existentes, true)) {
            $tentativa = $base . '_' . $i;
            $i++;
        }
        return $tentativa;
    }
}
