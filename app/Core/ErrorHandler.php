<?php

namespace App\Core;

/**
 * Tratamento central de erros da aplicacao.
 *
 * Responsabilidades:
 *  - registrar TUDO no log (excecoes, warnings, notices e erros fatais),
 *    com request id, rota, metodo, IP, usuario e pilha resumida;
 *  - escolher a pagina certa: 503 quando o problema e estrutura do banco
 *    (ex.: migration 0004 nao aplicada), 503 quando o banco esta fora do
 *    ar e 500 para o resto - sempre com um codigo de referencia visivel;
 *  - nunca gravar senha, token CSRF ou segredo no log.
 */
class ErrorHandler
{
    /** Evita recursao/dupla renderizacao da pagina de erro. */
    private static bool $renderizando = false;

    /** Campos que nunca podem ir para o log. */
    private const CAMPOS_SENSIVEIS = '/pass|senha|token|csrf|secret|authorization|cookie/i';

    public static function register(): void
    {
        $debug = ($_ENV['APP_DEBUG'] ?? 'false') === 'true';
        error_reporting(E_ALL);
        ini_set('display_errors', $debug ? '1' : '0');
        ini_set('log_errors', '1');

        set_error_handler([self::class, 'handleError']);
        set_exception_handler([self::class, 'handleUncaught']);
        register_shutdown_function([self::class, 'handleShutdown']);
    }

    /* ------------------------------------------------------------------
     * Handlers
     * ---------------------------------------------------------------- */

    public static function handleError(int $errno, string $errstr, string $errfile = '', int $errline = 0): bool
    {
        if ((error_reporting() & $errno) === 0) {
            return false;
        }

        $fatais = [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR, E_USER_ERROR, E_RECOVERABLE_ERROR];
        $contexto = [
            'errno' => $errno,
            'file'  => $errfile . ':' . $errline,
        ];

        if (in_array($errno, $fatais, true)) {
            Logger::critical('Erro PHP fatal: ' . $errstr, $contexto);
        } else {
            Logger::warning('Erro PHP: ' . $errstr, $contexto);
        }

        // Deixa o PHP seguir o fluxo normal (warnings nao interrompem)
        return false;
    }

    public static function handleUncaught(\Throwable $e): void
    {
        self::render($e);
    }

    /**
     * Captura erros fatais (parse error, memoria, timeout) que nao passam
     * pelo set_exception_handler e registra no log.
     */
    public static function handleShutdown(): void
    {
        $erro = error_get_last();
        if ($erro === null) {
            return;
        }
        $fatais = [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR, E_USER_ERROR];
        if (!in_array($erro['type'], $fatais, true)) {
            return;
        }

        Logger::critical('Erro fatal encerrou a requisicao: ' . $erro['message'], [
            'file'      => $erro['file'] . ':' . $erro['line'],
            'memoria'   => self::memoria(),
            'post_keys' => array_keys($_POST),
        ]);

        if (self::$renderizando || headers_sent()) {
            return;
        }

        self::$renderizando = true;
        $ref = Logger::requestId();
        ErrorPage::render(
            500,
            'Erro interno',
            'A requisicao foi interrompida por um erro no servidor. O ocorrido foi registrado no log.',
            'Informe o código abaixo ao suporte ou consulte /_logs.php.',
            ['fatal' => $erro['message'], 'file' => $erro['file'] . ':' . $erro['line']],
            [],
            $ref
        );
    }

    /* ------------------------------------------------------------------
     * Roteamento da excecao para a pagina correta
     * ---------------------------------------------------------------- */

    public static function render(\Throwable $e): void
    {
        if (self::$renderizando) {
            // Ja estamos montando uma pagina de erro: apenas registra.
            Logger::exception($e, 'Excecao durante a renderizacao da pagina de erro');
            return;
        }
        self::$renderizando = true;

        $ref = Logger::exception($e, 'Erro nao tratado', [
            'post'    => self::postSeguro(),
            'get'     => self::limitar($_GET),
            'memoria' => self::memoria(),
        ]);

        $mensagem = self::mensagemTecnica($e);

        // 1) Falha de conexao com o banco => servico indisponivel
        if (self::ehFalhaDeConexao($e)) {
            ErrorPage::render(
                503,
                'Banco de dados indisponível',
                'Não foi possível falar com o banco de dados agora. Tente novamente em alguns instantes.',
                'Se o problema continuar, confira as credenciais do .env em /_atualizar.php ou /_diagnostico.php.',
                [],
                ['Abrir diagnóstico' => '/_diagnostico.php', 'Ir para o login' => '/login'],
                $ref
            );
        }

        // 2) Erro de estrutura (coluna/tabela inexistente) => schema atrasado
        if (self::ehErroDeEstrutura($e)) {
            $faltando = Schema::missingLabel();
            if ($faltando !== '') {
                ErrorPage::outdatedSchema($faltando, $ref);
            }
            ErrorPage::databaseStructure($mensagem, $ref);
        }

        // 3) Qualquer outra coisa => 500 com codigo de referencia
        ErrorPage::serverError($e, $ref);
    }

    /* ------------------------------------------------------------------
     * Classificacao
     * ---------------------------------------------------------------- */

    /** Percorre a cadeia de excecoes juntando mensagens e codigos SQL. */
    private static function mensagemTecnica(\Throwable $e): string
    {
        $partes = [];
        for ($atual = $e; $atual !== null; $atual = $atual->getPrevious()) {
            $partes[] = $atual->getMessage();
            if ($atual instanceof \PDOException) {
                $partes[] = 'SQLSTATE ' . $atual->getCode();
                if (!empty($atual->errorInfo[2])) {
                    $partes[] = (string) $atual->errorInfo[2];
                }
            }
        }
        $texto = trim(implode(' | ', array_filter($partes)));
        return mb_substr($texto, 0, 300);
    }

    private static function ehFalhaDeConexao(\Throwable $e): bool
    {
        if ($e instanceof DatabaseException && $e->getPrevious() === null) {
            return true;
        }
        $texto = self::mensagemTecnica($e);
        return (bool) preg_match(
            '/SQLSTATE\[HY000\] \[(2002|2003|2005|1044|1045|1049)\]|Connection refused|Unknown database|Access denied for user|getaddrinfo|No such host|server has gone away/i',
            $texto
        );
    }

    private static function ehErroDeEstrutura(\Throwable $e): bool
    {
        $texto = self::mensagemTecnica($e);
        return (bool) preg_match(
            '/Unknown column|doesn.t exist|no such table|Unknown table|42S22|42S02|1054|1146|Column not found/i',
            $texto
        );
    }

    /* ------------------------------------------------------------------
     * Utilidades
     * ---------------------------------------------------------------- */

    /** POST sem senhas/tokens, com valores truncados. */
    private static function postSeguro(): array
    {
        if (empty($_POST)) {
            return [];
        }
        $saida = [];
        foreach ($_POST as $campo => $valor) {
            if (preg_match(self::CAMPOS_SENSIVEIS, (string) $campo)) {
                $saida[$campo] = '***';
                continue;
            }
            $saida[$campo] = is_array($valor) ? '[array]' : mb_substr((string) $valor, 0, 120);
        }
        return $saida;
    }

    private static function limitar(array $dados): array
    {
        $saida = [];
        foreach ($dados as $chave => $valor) {
            if (preg_match(self::CAMPOS_SENSIVEIS, (string) $chave)) {
                $saida[$chave] = '***';
                continue;
            }
            $saida[$chave] = is_array($valor) ? '[array]' : mb_substr((string) $valor, 0, 120);
        }
        return $saida;
    }

    private static function memoria(): string
    {
        return round(memory_get_peak_usage(true) / 1048576, 1) . ' MB';
    }
}
