<?php
namespace App\Support;

/**
 * Converte o JSON gravado em audit_logs.details em texto legivel
 * para as tabelas do painel ("provider: local · email: ...").
 */
class AuditDetails
{
    public static function text(?string $json, int $limite = 110): string
    {
        $json = trim((string) $json);

        if ($json === '') {
            return '—';
        }

        $dados = json_decode($json, true);

        if (!is_array($dados)) {
            return mb_substr($json, 0, $limite);
        }

        $partes = [];
        foreach ($dados as $chave => $valor) {
            if (is_array($valor)) {
                $valor = json_encode($valor, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
            } elseif (is_bool($valor)) {
                $valor = $valor ? 'sim' : 'não';
            } elseif ($valor === null) {
                $valor = '—';
            }

            $partes[] = $chave . ': ' . $valor;
        }

        return mb_substr(implode(' · ', $partes), 0, $limite);
    }
}
