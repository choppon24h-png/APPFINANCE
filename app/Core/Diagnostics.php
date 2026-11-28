<?php
namespace App\Core;

use PDOException;
use Throwable;

/**
 * Registro e mensagens de erro dos cadastros.
 *
 * Cada tentativa de gravar (conta, lancamento, centro de custo, categoria,
 * investimento...) recebe um codigo curto de 8 caracteres. O mesmo codigo
 * vai para o log (app-AAAA-MM-DD.log e erros-AAAA-MM-DD.log) e para a
 * mensagem exibida ao usuario. Assim o suporte consegue achar a linha exata
 * sem adivinhar, mesmo quando o erro foi capturado por um try/catch local.
 */
final class Diagnostics
{
    /** Codigo curto e unico para correlacionar tela e log. */
    public static function codigo(): string
    {
        return strtoupper(substr(bin2hex(random_bytes(4)), 0, 8));
    }

    /** Registra o inicio da operacao e devolve o codigo de referencia. */
    public static function inicio(string $evento, array $contexto = []): string
    {
        $codigo = self::codigo();
        Logger::info($evento . '.inicio', $contexto + [
            'codigo' => $codigo,
            'request_id' => Logger::requestId(),
        ]);
        return $codigo;
    }

    /** Registra o sucesso, com dados uteis para conferir o efeito no banco. */
    public static function sucesso(string $evento, string $codigo, array $contexto = []): void
    {
        Logger::info($evento . '.ok', $contexto + ['codigo' => $codigo]);
    }

    /** Registra a falha completa (classe, mensagem, SQLSTATE, arquivo e linha). */
    public static function falha(string $evento, string $codigo, Throwable $e, array $contexto = []): void
    {
        Logger::error($evento . '.falhou', $contexto + [
            'codigo' => $codigo,
            'excecao' => get_class($e),
            'mensagem' => $e->getMessage(),
            'sqlstate' => $e instanceof PDOException ? (string) $e->getCode() : null,
            'arquivo' => $e->getFile() . ':' . $e->getLine(),
            'trace' => self::traceResumida($e),
        ]);
    }

    /**
     * Mensagem para o usuario: erros de validacao aparecem como estao;
     * estrutura ausente vira instrucao de atualizacao; o resto ganha um
     * codigo de referencia para o suporte.
     */
    public static function mensagem(Throwable $e, string $codigo, string $padrao = 'Não foi possível concluir o cadastro.'): string
    {
        if ($e instanceof \InvalidArgumentException) {
            return $e->getMessage();
        }

        $estrutura = self::estruturaFaltante($e->getMessage());
        if ($estrutura !== null) {
            return 'Banco desatualizado: ' . $estrutura . '. Abra /_atualizar.php (ou importe '
                . 'database/sql/somase_mysql_unico.sql) e tente novamente. Código ' . $codigo . '.';
        }

        return $padrao . ' Código de referência: ' . $codigo . '. Informe esse código no suporte.';
    }

    /** Traduz "Table X doesn't exist" / "Unknown column Y" em texto util. */
    public static function estruturaFaltante(string $mensagem): ?string
    {
        if (preg_match("/Table '([^']+)' doesn't exist/i", $mensagem, $m)) {
            return 'falta a tabela ' . $m[1];
        }
        if (preg_match("/Unknown column '([^']+)'/i", $mensagem, $m)) {
            return 'falta a coluna ' . $m[1];
        }
        if (preg_match('/no such table:?\s*([A-Za-z0-9_]+)/i', $mensagem, $m)) {
            return 'falta a tabela ' . $m[1];
        }
        return null;
    }

    /**
     * Payload seguro para o log: mascara senha/token/CSRF e limita textos.
     * Nunca grava o conteudo de campos sensiveis.
     */
    public static function payload(array $dados): array
    {
        $seguro = [];
        foreach ($dados as $campo => $valor) {
            if (preg_match('/senha|password|token|csrf|secret/i', (string) $campo)) {
                $seguro[$campo] = '***';
                continue;
            }
            if (is_string($valor)) {
                $seguro[$campo] = mb_substr($valor, 0, 120);
            } elseif (is_scalar($valor) || $valor === null) {
                $seguro[$campo] = $valor;
            } else {
                $seguro[$campo] = gettype($valor);
            }
        }
        return $seguro;
    }

    /** Pilha curta (5 primeiros quadros) para o log nao ficar enorme. */
    private static function traceResumida(Throwable $e): array
    {
        $linhas = [];
        foreach (array_slice($e->getTrace(), 0, 5) as $quadro) {
            $linhas[] = ($quadro['class'] ?? '') . ($quadro['type'] ?? '') . ($quadro['function'] ?? '')
                . (isset($quadro['file']) ? ' @ ' . basename((string) $quadro['file']) . ':' . ($quadro['line'] ?? '?') : '');
        }
        return $linhas;
    }
}
