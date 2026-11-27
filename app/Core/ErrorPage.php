<?php
namespace App\Core;

/**
 * Paginas de erro no visual SOMASE.
 *
 * Nao depende de banco, sessao ou .env: pode ser usada quando a
 * aplicacao ainda nao esta completamente inicializada (ex.: .env
 * ausente na HostGator). O CSS e inline de proposito.
 */
class ErrorPage
{
    /**
     * Renderiza a pagina e encerra a requisicao.
     */
    public static function render(int $status, string $title, string $message, string $hint = '', array $debug = [], array $actions = []): void
    {
        if (!headers_sent()) {
            http_response_code($status);
            header('Content-Type: text/html; charset=utf-8');
        }

        $code    = (int) $status;
        $title   = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');
        $message = htmlspecialchars($message, ENT_QUOTES, 'UTF-8');
        $hint    = htmlspecialchars($hint, ENT_QUOTES, 'UTF-8');
        $ano     = date('Y');
        $debugHtml = '';

        if ($debug && ($_ENV['APP_DEBUG'] ?? 'false') === 'true') {
            $debugHtml = '<pre class="err-debug">' . htmlspecialchars(print_r($debug, true), ENT_QUOTES, 'UTF-8') . '</pre>';
        }

        $actions = $actions ?: ['Ir para o login' => '/login', 'Abrir o sistema' => '/dashboard'];
        $actionsHtml = '';
        foreach ($actions as $rotulo => $url) {
            $classe = $actionsHtml === '' ? 'button' : 'button ghost';
            $actionsHtml .= '<a class="' . $classe . '" href="' . htmlspecialchars($url, ENT_QUOTES, 'UTF-8') . '">'
                . htmlspecialchars($rotulo, ENT_QUOTES, 'UTF-8') . '</a>';
        }

        echo <<<HTML
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#07101f">
<meta name="robots" content="noindex, nofollow">
<title>{$code} · {$title} · SOMASE</title>
<link rel="icon" href="/favicon.ico" sizes="any">
<style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body {
        margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 28px 18px;
        font-family: Inter, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
        color: #e8eef9; background:
            radial-gradient(900px 500px at 15% 0%, rgba(31,111,224,.28), transparent 60%),
            radial-gradient(700px 420px at 90% 100%, rgba(67,193,58,.16), transparent 62%),
            #07101f;
    }
    .card {
        width: 100%; max-width: 560px; padding: 34px 30px 30px; border-radius: 22px;
        background: linear-gradient(180deg, rgba(18,37,74,.92), rgba(9,20,40,.96));
        border: 1px solid #1f3560; box-shadow: 0 30px 80px rgba(0,0,0,.45);
    }
    .brand { display: block; width: min(230px, 70%); margin-bottom: 22px; }
    .code { font-size: 12px; font-weight: 800; letter-spacing: .22em; text-transform: uppercase; color: #3b8bff; }
    h1 { margin: 8px 0 10px; font-size: 26px; line-height: 1.2; letter-spacing: -.02em; }
    p { margin: 0 0 8px; color: #a9bcd8; font-size: 14px; line-height: 1.6; }
    .hint { margin-top: 16px; padding: 12px 14px; border-radius: 12px; background: rgba(59,139,255,.1); border: 1px solid rgba(59,139,255,.28); color: #cfe0ff; font-size: 13px; }
    .actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 22px; }
    a.button {
        display: inline-flex; align-items: center; gap: 8px; padding: 11px 18px; border-radius: 12px;
        text-decoration: none; font-weight: 700; font-size: 13px;
        background: #1f6fe0; color: #fff; box-shadow: 0 12px 26px rgba(31,111,224,.35);
    }
    a.ghost { background: transparent; color: #cfe0ff; border: 1px solid #2b4a7d; box-shadow: none; }
    .err-debug { margin-top: 18px; padding: 14px; border-radius: 12px; background: #050b16; border: 1px solid #1f3560; color: #8ea3c4; font-size: 11px; overflow: auto; }
    footer { margin-top: 24px; font-size: 11px; color: #6d82a6; }
</style>
</head>
<body>
    <main class="card">
        <img class="brand" src="/assets/brand/somase-logo-horizontal-light.png" alt="SOMASE — Controle Financeiro">
        <span class="code">Erro {$code}</span>
        <h1>{$title}</h1>
        <p>{$message}</p>
        {$hint}
        {$debugHtml}
        <div class="actions">
            {$actionsHtml}
        </div>
        <footer>© {$ano} SOMASE · Controle Financeiro</footer>
    </main>
</body>
</html>
HTML;
        exit;
    }

    public static function notFound(): void
    {
        self::render(404, 'Página não encontrada', 'O endereço que você tentou abrir não existe ou foi movido.');
    }

    public static function forbidden(string $message = 'Você não tem permissão para acessar esta área.'): void
    {
        self::render(403, 'Acesso negado', $message, 'Se precisar deste acesso, fale com o administrador da sua conta.');
    }

    public static function unavailable(string $message = 'O sistema está temporariamente indisponível. Tente novamente em alguns minutos.'): void
    {
        self::render(503, 'Serviço indisponível', $message);
    }

    public static function missingEnv(): void
    {
        self::render(
            503,
            'Configuração pendente',
            'O arquivo .env não foi encontrado na raiz do projeto, então o sistema ainda não consegue conectar ao banco de dados.',
            'Envie o arquivo .env (copiado de .env.example) para a mesma pasta de app/, public/ e .htaccess, com DB_* e APP_SECRET preenchidos. Depois recarregue esta página.'
        );
    }

    /**
     * Codigo novo + banco antigo: explica o que fazer em vez de 500.
     */
    public static function outdatedSchema(string $faltando = ''): void
    {
        $detalhe = $faltando !== '' ? ' Pendências: ' . $faltando . '.' : '';

        self::render(
            503,
            'Banco de dados precisa ser atualizado',
            'O sistema já está na versão nova, mas o banco ainda não recebeu a atualização da etapa de acesso.' . $detalhe,
            'Abra /_atualizar.php neste domínio (logado como administrador) e clique em “Aplicar atualização do banco”. O procedimento é seguro e pode ser repetido quantas vezes precisar.',
            [],
            ['Abrir atualizador' => '/_atualizar.php', 'Ir para o login' => '/login']
        );
    }

    public static function serverError(\Throwable $e): void
    {
        self::render(
            500,
            'Erro interno',
            'Algo deu errado ao processar sua solicitação. A equipe já foi notificada pelo log do servidor.',
            '',
            ['exception' => $e->getMessage(), 'file' => $e->getFile() . ':' . $e->getLine()]
        );
    }
}
