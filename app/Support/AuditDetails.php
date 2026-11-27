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
                $internos = [];
                foreach ($valor as $k => $v) {
                    if ($v === '' || $v === null) {
                        continue;
                    }
                    $internos[] = $k . '=' . (is_array($v) ? json_encode($v, JSON_UNESCAPED_UNICODE) : $v);
                }
                $valor = $internos ? implode(', ', $internos) : '';
            } elseif (is_bool($valor)) {
                $valor = $valor ? 'sim' : 'não';
            }

            if ($valor === null || $valor === '') {
                continue;
            }

            $partes[] = $chave . ': ' . $valor;
        }

        return $partes ? mb_substr(implode(' · ', $partes), 0, $limite) : '—';
    }
}
