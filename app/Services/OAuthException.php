<?php
namespace App\Services;

/**
 * Falha no fluxo OAuth. A mensagem e uma chave curta que o controller
 * traduz em texto amigavel (?erro=...), sem expor detalhes do provedor.
 */
class OAuthException extends \RuntimeException
{
    public function __construct(private string $motivo = 'oauth_credenciais')
    {
        parent::__construct($motivo);
    }

    public function motivo(): string
    {
        return $this->motivo;
    }
}
