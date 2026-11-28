<?php
namespace App\Core;

use PDO;

/**
 * Verifica quais migrations o banco ja recebeu.
 *
 * A checagem usa "sentinels": a tabela ou coluna que cada migration cria.
 * Assim o sistema consegue dizer exatamente o que falta (por exemplo,
 * "0007: tabela payment_methods") em vez de um erro generico de SQL, e o
 * /_atualizar.php sabe quais arquivos precisa aplicar.
 *
 * A migration 0004 continua sendo a unica que bloqueia o acesso inteiro
 * (accessReady); as demais sao checadas para aviso e para o atualizador.
 */
class Schema
{
    /** Cache das migrations pendentes (calculado uma vez por requisicao). */
    private static ?array $pendentes = null;

    /** Cache do mapa de tabelas/colunas lido do information_schema. */
    private static ?array $estado = null;

    /** Motivo da ultima falha ao consultar o schema (para diagnostico). */
    private static ?string $ultimoErro = null;

    /** Aviso ja registrado no log nesta requisicao (evita repetir). */
    private static bool $logado = false;

    /**
     * Cada migration com as estruturas que ela cria.
     * `columns` usa tabela => lista de colunas; `tables` e a lista de tabelas;
     * `seeds` confere se um registro obrigatorio existe.
     */
    private const MIGRATIONS = [
        [
            'file'  => '0004_user_registration.sql',
            'label' => '0004 (acesso, login social e painel)',
            'tables' => ['user_identities', 'auth_attempts'],
            'columns' => [
                'users' => ['birth_date', 'auth_provider', 'avatar_url', 'email_verified_at', 'terms_accepted_at', 'registration_ip'],
            ],
            'seeds' => [
                ['table' => 'permissions', 'column' => 'slug', 'value' => 'access_admin_panel'],
            ],
        ],
        [
            'file'  => '0005_banks.sql',
            'label' => '0005 (catalogo de bancos)',
            'tables' => ['banks'],
            'min_rows' => ['banks' => 100],
        ],
        [
            'file'  => '0006_documents_properties.sql',
            'label' => '0006 (documentos, imoveis e importacao)',
            'columns' => [
                'cost_centers' => ['kind', 'address', 'identifiers'],
                'transactions' => ['document_code', 'import_ref', 'attachment_path'],
            ],
        ],
        [
            'file'  => '0007_cep_payments_investments.sql',
            'label' => '0007 (CEP, formas de pagamento e investimentos)',
            'tables' => ['payment_methods', 'investment_types'],
            'columns' => [
                'cost_centers' => ['zip_code', 'street', 'address_number', 'complement', 'neighborhood', 'city', 'state'],
                'investments'  => ['investment_type_id', 'benchmark_rate', 'rate_period'],
                'accounts'     => ['investment_type_id', 'investment_rate', 'investment_rate_period'],
            ],
        ],
    ];

    /** Nome do arquivo da migration que criou a tabela (para a tela de erro). */
    private const TABLE_MIGRATION = [
        'payment_methods'    => '0007_cep_payments_investments.sql',
        'investment_types'   => '0007_cep_payments_investments.sql',
        'user_identities'    => '0004_user_registration.sql',
        'auth_attempts'      => '0004_user_registration.sql',
        'banks'              => '0005_banks.sql',
    ];

    /** Lista de migrations conhecidas (arquivo + rotulo). */
    public static function migrations(): array
    {
        return array_map(
            static fn (array $m): array => ['file' => $m['file'], 'label' => $m['label']],
            self::MIGRATIONS
        );
    }

    /**
     * Le tabelas e colunas do banco conectado.
     * @return array{tables:array<int,string>,columns:array<string,array<int,string>>}|null
     */
    private static function estado(): ?array
    {
        if (self::$estado !== null) {
            return self::$estado;
        }

        try {
            $pdo = Database::getInstance();
            $banco = (string) $pdo->query('SELECT DATABASE()')->fetchColumn();
            if ($banco === '') {
                $banco = (string) ($_ENV['DB_DATABASE'] ?? '');
            }

            $stmt = $pdo->prepare('SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = :banco');
            $stmt->execute(['banco' => $banco]);
            $tabelas = [];
            $colunas = [];
            foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $linha) {
                $tabela = strtolower((string) $linha['TABLE_NAME']);
                $tabelas[$tabela] = true;
                $colunas[$tabela][] = strtolower((string) $linha['COLUMN_NAME']);
            }

            self::$estado = [
                'tables'  => array_keys($tabelas),
                'columns' => $colunas,
                'pdo'     => $pdo,
            ];
        } catch (\Throwable $e) {
            self::$ultimoErro = get_class($e) . ': ' . $e->getMessage();
            Logger::warning('Nao foi possivel verificar o schema', [
                'excecao' => get_class($e),
                'codigo'  => (string) $e->getCode(),
                'erro'    => $e->getMessage(),
                'arquivo' => $e->getFile() . ':' . $e->getLine(),
            ]);
            return null;
        }

        return self::$estado;
    }

    /** @return array<int,string> pendencias da migration (vazio = aplicada) */
    private static function missingFor(array $migration): array
    {
        $estado = self::estado();
        if ($estado === null) {
            return [];
        }

        $faltando = [];
        foreach ($migration['tables'] ?? [] as $tabela) {
            if (!in_array($tabela, $estado['tables'], true)) {
                $faltando[] = 'tabela ' . $tabela;
            }
        }

        foreach ($migration['columns'] ?? [] as $tabela => $colunas) {
            if (!in_array($tabela, $estado['tables'], true)) {
                $faltando[] = 'tabela ' . $tabela;
                continue;
            }
            $existentes = $estado['columns'][$tabela] ?? [];
            foreach ($colunas as $coluna) {
                if (!in_array(strtolower($coluna), $existentes, true)) {
                    $faltando[] = $tabela . '.' . $coluna;
                }
            }
        }

        foreach ($migration['min_rows'] ?? [] as $tabela => $minimo) {
            if (!in_array($tabela, $estado['tables'], true)) {
                continue; // ja reportada acima
            }
            try {
                $total = (int) $estado['pdo']->query('SELECT COUNT(*) FROM `' . $tabela . '`')->fetchColumn();
                if ($total < $minimo) {
                    $faltando[] = $tabela . ' incompleta (' . $total . ')';
                }
            } catch (\Throwable $e) {
                $faltando[] = $tabela . ' ilegivel';
            }
        }

        foreach ($migration['seeds'] ?? [] as $seed) {
            if (!in_array($seed['table'], $estado['tables'], true)) {
                continue;
            }
            try {
                $stmt = $estado['pdo']->prepare('SELECT COUNT(*) FROM `' . $seed['table'] . '` WHERE `' . $seed['column'] . '` = :valor');
                $stmt->execute(['valor' => $seed['value']]);
                if ((int) $stmt->fetchColumn() === 0) {
                    $faltando[] = 'registro ' . $seed['value'];
                }
            } catch (\Throwable $e) {
                $faltando[] = 'registro ' . $seed['value'];
            }
        }

        return $faltando;
    }

    /**
     * Migrations pendentes, na ordem de execucao.
     * @return array<int,array{file:string,label:string,missing:array<int,string>}>
     */
    public static function pending(): array
    {
        if (self::$pendentes !== null) {
            return self::$pendentes;
        }

        $pendentes = [];
        foreach (self::MIGRATIONS as $migration) {
            $faltando = self::missingFor($migration);
            if ($faltando !== []) {
                $pendentes[] = [
                    'file'    => $migration['file'],
                    'label'   => $migration['label'],
                    'missing' => $faltando,
                ];
            }
        }

        self::$pendentes = $pendentes;

        if ($pendentes !== [] && !self::$logado) {
            self::$logado = true;
            Logger::warning('schema.migration_pendente', [
                'pendencias' => array_map(
                    static fn (array $p): array => ['migration' => $p['file'], 'faltando' => array_slice($p['missing'], 0, 8)],
                    $pendentes
                ),
            ]);
        }

        return self::$pendentes;
    }

    /** Arquivos das migrations pendentes. @return array<int,string> */
    public static function pendingFiles(): array
    {
        return array_map(static fn (array $p): string => $p['file'], self::pending());
    }

    /**
     * Texto curto das pendencias, usado nas telas de erro e no aviso do topo.
     * Ex.: "0007 (CEP...): tabela payment_methods, tabela investment_types".
     */
    public static function missingLabel(int $limite = 6): string
    {
        $partes = [];
        foreach (self::pending() as $pendente) {
            $itens = array_slice($pendente['missing'], 0, $limite);
            $partes[] = $pendente['label'] . ': ' . implode(', ', $itens);
        }
        return implode(' | ', $partes);
    }

    /** Ha alguma migration pendente? */
    public static function hasPending(): bool
    {
        return self::pending() !== [];
    }

    /** Nome da migration que criou a tabela citada no erro, se conhecida. */
    public static function migrationForTable(?string $tabela): ?string
    {
        if ($tabela === null || $tabela === '') {
            return null;
        }
        return self::TABLE_MIGRATION[strtolower($tabela)] ?? null;
    }

    /** Migration 0004 aplicada? (unica que bloqueia o acesso) */
    public static function missingAccess(): array
    {
        foreach (self::MIGRATIONS as $migration) {
            if ($migration['file'] === '0004_user_registration.sql') {
                return self::missingFor($migration);
            }
        }
        return [];
    }

    /** Motivo (classe + mensagem) da falha ao consultar o schema, se houve. */
    public static function lastError(): string
    {
        self::estado();
        return (string) (self::$ultimoErro ?? '');
    }

    public static function accessReady(): bool
    {
        return self::missingAccess() === [];
    }
}
