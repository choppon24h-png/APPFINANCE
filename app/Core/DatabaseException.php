<?php
namespace App\Core;

/**
 * Falha de conexao/operacao no banco de dados.
 *
 * Existe para que o Router consiga diferenciar "banco fora do ar"
 * (503 — Servico indisponivel) de um erro de programacao (500).
 * A mensagem original nunca vai para a tela: fica no log.
 */
class DatabaseException extends \RuntimeException
{
}
