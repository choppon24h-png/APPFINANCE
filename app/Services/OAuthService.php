<?php
namespace App\Services;

/**
 * OAuth 2.0 Authorization Code + PKCE + OpenID Connect, em PHP puro.
 *
 * Sem composer: toda a comunicacao HTTP usa cURL com verificacao de
 * certificado ligada e timeout curto. Nenhum token e gravado em log.
 */
class OAuthService
{
    private const TIMEOUT = 10;

    /** Provedores suportados e seus endpoints OIDC. */
    private static function provider(string $provider): ?array
    {
        $tenant = $_ENV['MICROSOFT_TENANT'] ?? 'common';
        $tenant = $tenant !== '' ? rawurlencode($tenant) : 'common';

        return match ($provider) {
            'google' => [
                'label'        => 'Google',
                'client_id'    => trim((string) ($_ENV['GOOGLE_CLIENT_ID'] ?? '')),
                'client_secret'=> trim((string) ($_ENV['GOOGLE_CLIENT_SECRET'] ?? '')),
                'authorize'    => 'https://accounts.google.com/o/oauth2/v2/auth',
                'token'        => 'https://oauth2.googleapis.com/token',
                'userinfo'     => 'https://openidconnect.googleapis.com/v1/userinfo',
            ],
            'microsoft' => [
                'label'        => 'Microsoft',
                'client_id'    => trim((string) ($_ENV['MICROSOFT_CLIENT_ID'] ?? '')),
                'client_secret'=> trim((string) ($_ENV['MICROSOFT_CLIENT_SECRET'] ?? '')),
                'authorize'    => "https://login.microsoftonline.com/{$tenant}/oauth2/v2.0/authorize",
                'token'        => "https://login.microsoftonline.com/{$tenant}/oauth2/v2.0/token",
                'userinfo'     => 'https://graph.microsoft.com/oidc/userinfo',
            ],
            default => null,
        };
    }

    public static function isValidProvider(string $provider): bool
    {
        return self::provider($provider) !== null;
    }

    /**
     * Provedores prontos para uso (com CLIENT_ID e CLIENT_SECRET preenchidos).
     * O botao na tela de login so aparece para estes.
     */
    public static function availableProviders(): array
    {
        $disponiveis = [];
        foreach (['google', 'microsoft'] as $slug) {
            $cfg = self::provider($slug);
            if ($cfg && $cfg['client_id'] !== '' && $cfg['client_secret'] !== '') {
                $disponiveis[$slug] = $cfg['label'];
            }
        }
        return $disponiveis;
    }

    public static function isAvailable(string $provider): bool
    {
        return array_key_exists($provider, self::availableProviders());
    }

    /**
     * O provedor tem CLIENT_ID e CLIENT_SECRET no .env?
     * Usado para mostrar os botoes mesmo antes da configuracao (modo "em ativacao").
     */
    public static function isConfigured(string $provider): bool
    {
        return self::isAvailable($provider);
    }

    public static function label(string $provider): string
    {
        return self::provider($provider)['label'] ?? ucfirst($provider);
    }

    public static function redirectUri(string $provider): string
    {
        $base = rtrim((string) ($_ENV['APP_URL'] ?? ''), '/');

        if ($base === '' || str_contains($base, 'localhost') && !empty($_SERVER['HTTP_HOST']) && !str_contains($_SERVER['HTTP_HOST'], 'localhost')) {
            $base = self::baseUrlFromRequest();
        }

        return $base . '/auth/' . $provider . '/callback';
    }

    private static function baseUrlFromRequest(): string
    {
        $https  = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
            || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
        $scheme = $https ? 'https' : 'http';
        $host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
        return $scheme . '://' . $host;
    }

    /**
     * Monta a URL de autorizacao e guarda state + code_verifier na sessao.
     */
    public static function authorizeUrl(string $provider): string
    {
        $cfg = self::provider($provider);
        if (!$cfg || $cfg['client_id'] === '') {
            throw new OAuthException('oauth_credenciais');
        }

        $state    = bin2hex(random_bytes(24));
        $verifier = self::base64Url(random_bytes(48));
        $challenge = self::base64Url(hash('sha256', $verifier, true));

        $_SESSION['oauth'][$provider] = [
            'state'    => $state,
            'verifier' => $verifier,
            'created'  => time(),
        ];

        $params = [
            'client_id'             => $cfg['client_id'],
            'redirect_uri'          => self::redirectUri($provider),
            'response_type'         => 'code',
            'scope'                 => 'openid email profile',
            'state'                 => $state,
            'code_challenge'        => $challenge,
            'code_challenge_method' => 'S256',
            'prompt'                => 'select_account',
        ];

        return $cfg['authorize'] . '?' . http_build_query($params);
    }

    /**
     * Valida o state, troca o code por token e devolve o perfil normalizado.
     *
     * @return array{provider:string,sub:string,email:string,name:string,avatar:?string,email_verified:bool}
     */
    public static function handleCallback(string $provider, string $code, string $state): array
    {
        $cfg = self::provider($provider);
        if (!$cfg) {
            throw new OAuthException('oauth_credenciais');
        }

        $sessao = $_SESSION['oauth'][$provider] ?? null;
        unset($_SESSION['oauth'][$provider]);

        if (!$sessao || empty($sessao['state']) || !hash_equals((string) $sessao['state'], $state)) {
            throw new OAuthException('oauth_state');
        }

        // Janela de 10 minutos para concluir o fluxo
        if (time() - (int) ($sessao['created'] ?? 0) > 600) {
            throw new OAuthException('oauth_state');
        }

        if ($code === '') {
            throw new OAuthException('oauth_cancelado');
        }

        $token = self::requestToken($cfg, $provider, $code, (string) $sessao['verifier']);
        $info  = self::requestUserInfo($cfg, (string) ($token['access_token'] ?? ''));

        $email = mb_strtolower(trim((string) ($info['email'] ?? $info['preferred_username'] ?? '')));
        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new OAuthException('oauth_email');
        }

        $verificado = true;
        if ($provider === 'google') {
            $verificado = filter_var($info['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);
        } elseif (array_key_exists('email_verified', $info)) {
            $verificado = filter_var($info['email_verified'], FILTER_VALIDATE_BOOLEAN);
        }

        if (!$verificado) {
            throw new OAuthException('oauth_email');
        }

        $sub = (string) ($info['sub'] ?? $info['oid'] ?? '');
        if ($sub === '') {
            throw new OAuthException('oauth_credenciais');
        }

        return [
            'provider'       => $provider,
            'sub'            => $sub,
            'email'          => $email,
            'name'           => trim((string) ($info['name'] ?? $info['given_name'] ?? 'Usuário SOMASE')),
            'avatar'         => $info['picture'] ?? null,
            'email_verified' => true,
        ];
    }

    private static function requestToken(array $cfg, string $provider, string $code, string $verifier): array
    {
        $body = http_build_query([
            'client_id'     => $cfg['client_id'],
            'client_secret' => $cfg['client_secret'],
            'code'          => $code,
            'code_verifier' => $verifier,
            'grant_type'    => 'authorization_code',
            'redirect_uri'  => self::redirectUri($provider),
        ]);

        $resposta = self::http($cfg['token'], [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded', 'Accept: application/json'],
        ]);

        $dados = json_decode($resposta, true);
        if (!is_array($dados) || empty($dados['access_token'])) {
            throw new OAuthException('oauth_credenciais');
        }

        return $dados;
    }

    private static function requestUserInfo(array $cfg, string $accessToken): array
    {
        if ($accessToken === '') {
            throw new OAuthException('oauth_credenciais');
        }

        $resposta = self::http($cfg['userinfo'], [
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $accessToken,
                'Accept: application/json',
            ],
        ]);

        $dados = json_decode($resposta, true);
        if (!is_array($dados)) {
            throw new OAuthException('oauth_credenciais');
        }

        return $dados;
    }

    private static function http(string $url, array $options): string
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, $options + [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_CONNECTTIMEOUT => self::TIMEOUT,
            CURLOPT_TIMEOUT        => self::TIMEOUT,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_USERAGENT      => 'SOMASE/1.0 (+https://finance.minasbyte.com)',
        ]);

        $resposta = curl_exec($ch);
        $status   = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $erro     = curl_error($ch);
        curl_close($ch);

        if ($resposta === false || $status >= 400) {
            throw new OAuthException('oauth_credenciais');
        }

        return (string) $resposta;
    }

    private static function base64Url(string $binario): string
    {
        return rtrim(strtr(base64_encode($binario), '+/', '-_'), '=');
    }
}
