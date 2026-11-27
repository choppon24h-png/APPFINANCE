<?php

namespace App\Models;

use App\Core\Model;
use PDO;

/**
 * Catalogo de bancos brasileiros (codigo COMPE), carregado pela migration 0005.
 *
 * Usado pelo autocomplete do formulario de conta: a pessoa digita o nome
 * ("nubank", "itau") ou o codigo ("260", "001") e a lista vem do banco.
 */
class Bank extends Model
{
    protected string $table = 'banks';

    /** Bancos mais procurados, exibidos quando o campo esta vazio. */
    private const POPULARES = ['260', '001', '341', '237', '033', '104', '077', '336', '290', '212', '756', '748'];

    /**
     * Busca por nome, nome completo ou codigo COMPE.
     *
     * @return array<int, object>
     */
    public function search(string $termo, int $limite = 12): array
    {
        $termo  = trim($termo);
        $limite = max(1, min(30, $limite));

        if ($termo === '') {
            return $this->populares($limite);
        }

        $digitos = (string) preg_replace('/\D/', '', $termo);
        $codigo  = ($digitos !== '' && strlen($digitos) <= 3 && strlen($digitos) === strlen($termo))
            ? str_pad($digitos, 3, '0', STR_PAD_LEFT)
            : null;

        $like    = '%' . $this->escaparLike($termo) . '%';
        $prefixo = $this->escaparLike($termo) . '%';

        $condicoes = [
            'name LIKE :like1',
            'full_name LIKE :like2',
            'aliases LIKE :like3',
            'ispb LIKE :like4',
        ];
        $params = ['like1' => $like, 'like2' => $like, 'like3' => $like, 'like4' => $like];

        if ($codigo !== null) {
            $condicoes[] = 'compe = :codigo';
            $params['codigo'] = $codigo;
        }

        $sql = 'SELECT compe, ispb, name, full_name, aliases, logo_url
                  FROM banks
                 WHERE active = 1 AND (' . implode(' OR ', $condicoes) . ')
              ORDER BY CASE WHEN compe = :codigoOrdem THEN 0 ELSE 1 END,
                       CASE WHEN name LIKE :prefixo THEN 0 ELSE 1 END,
                       CASE WHEN aliases LIKE :prefixoAlias THEN 0 ELSE 1 END,
                       compe IS NULL, compe, name
                 LIMIT ' . $limite;

        $params['codigoOrdem']  = $codigo ?? '';
        $params['prefixo']      = $prefixo;
        $params['prefixoAlias'] = $prefixo;

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @return array<int, object> */
    private function populares(int $limite): array
    {
        $lista = array_slice(self::POPULARES, 0, $limite);
        $marcas = implode(',', array_fill(0, count($lista), '?'));
        $sql = "SELECT compe, ispb, name, full_name, aliases, logo_url
                  FROM banks
                 WHERE active = 1 AND compe IN ({$marcas})
              ORDER BY FIELD(compe, {$marcas})";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(array_merge($lista, $lista));

        return $stmt->fetchAll();
    }

    /** Busca uma instituicao pelo codigo COMPE (ex.: "260"). */
    public function findByCode(string $codigo): ?object
    {
        $codigo = str_pad((string) preg_replace('/\D/', '', $codigo), 3, '0', STR_PAD_LEFT);
        $stmt = $this->pdo->prepare('SELECT * FROM banks WHERE compe = :c AND active = 1 LIMIT 1');
        $stmt->execute(['c' => $codigo]);
        $banco = $stmt->fetch();

        return $banco ?: null;
    }

    public function total(): int
    {
        return (int) $this->pdo->query('SELECT COUNT(*) FROM banks WHERE active = 1')->fetchColumn();
    }

    /**
     * Nome curto para exibir/selecionar: usa a marca popular quando existe
     * ("Nubank", "Itaú") e, caso contrario, limpa a razao social do BCB
     * ("NU PAGAMENTOS S.A. - INSTITUICAO DE PAGAMENTO" -> "Nu Pagamentos").
     */
    public static function rotulo(object $banco): string
    {
        $apelidos = trim((string) ($banco->aliases ?? ''));
        if ($apelidos !== '') {
            foreach (explode('|', $apelidos) as $apelido) {
                $apelido = trim($apelido);
                if ($apelido !== '') {
                    return $apelido;
                }
            }
        }

        $nome = trim((string) (($banco->full_name ?? '') !== '' ? $banco->full_name : ($banco->name ?? '')));
        $nome = (string) preg_replace('/\s*[-\/]?\s*(S\.?\/?A\.?|S\.A\.S\.?|LTDA\.?|ME|EPP)\b.*$/iu', '', $nome);
        $nome = (string) preg_replace('/\s*[-\/]\s*(IP|SCD|CFI|DTVM|SCFI|CC|BM)\b.*$/iu', '', $nome);
        $nome = trim((string) preg_replace('/\s{2,}/', ' ', $nome), " -.,");
        if ($nome === '') {
            $nome = (string) ($banco->name ?? '');
        }
        $nome = (string) preg_replace('/^BCO\b/u', 'Banco', $nome);

        if (mb_strtoupper($nome, 'UTF-8') === $nome) {
            $nome = mb_convert_case(mb_strtolower($nome, 'UTF-8'), MB_CASE_TITLE, 'UTF-8');
            $nome = (string) preg_replace_callback(
                '/\b(De|Da|Do|Das|Dos|E)\b/u',
                static fn(array $m): string => mb_strtolower($m[1], 'UTF-8'),
                $nome
            );
        }

        return $nome;
    }

    private function escaparLike(string $texto): string
    {
        return str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $texto);
    }
}
