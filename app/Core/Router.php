<?php
namespace App\Core;

class Router {
    private static array $routes = [];
    private static array $groupStack = [];

    // Rotas publicas que nao precisam de autenticacao
    private static array $publicRoutes = [
        '/login',
        '/logout',
    ];

    public static function get(string $path, $handler, array $middleware = []): void {
        self::addRoute('GET', $path, $handler, $middleware);
    }

    public static function post(string $path, $handler, array $middleware = []): void {
        self::addRoute('POST', $path, $handler, $middleware);
    }

    private static function addRoute(string $method, string $path, $handler, array $middleware): void {
        self::$routes[] = [
            'method'     => $method,
            'path'       => self::currentPrefix() . $path,
            'handler'    => $handler,
            'middleware' => array_merge(self::currentGroupMiddleware(), $middleware),
        ];
    }

    /**
     * Agrupa rotas sob um prefixo e/ou uma lista de middlewares comuns.
     *
     * Exemplo:
     *   Router::group(['prefix' => '/admin', 'middleware' => [AuthMiddleware::class]], function () {
     *       Router::get('/usuarios', 'UsuariosController@index');
     *   });
     */
    public static function group(array $options, callable $callback): void {
        self::$groupStack[] = $options;
        $callback();
        array_pop(self::$groupStack);
    }

    private static function currentPrefix(): string {
        $prefix = '';
        foreach (self::$groupStack as $group) {
            $prefix .= $group['prefix'] ?? '';
        }
        return $prefix;
    }

    private static function currentGroupMiddleware(): array {
        $middleware = [];
        foreach (self::$groupStack as $group) {
            $middleware = array_merge($middleware, $group['middleware'] ?? []);
        }
        return $middleware;
    }

    /**
     * Define quais rotas podem ser acessadas sem autenticacao.
     * Chame isso nas suas rotas (ex: routes/web.php) se precisar
     * liberar caminhos adicionais.
     */
    public static function publicRoutes(array $paths): void {
        self::$publicRoutes = array_merge(self::$publicRoutes, $paths);
    }

    private static function isPublicRoute(string $uri): bool {
        foreach (self::$publicRoutes as $pub) {
            // Terminado em "*" => prefixo; caso contrario, correspondencia exata
            if (substr($pub, -1) === '*') {
                if (strpos($uri, rtrim($pub, '*')) === 0) {
                    return true;
                }
                continue;
            }
            if ($uri === $pub) {
                return true;
            }
        }
        return false;
    }

    public static function dispatch(): void {
        $method = $_SERVER['REQUEST_METHOD'];
        $uri    = strtok($_SERVER['REQUEST_URI'], '?');

        // Redireciona para login se nao autenticado e a rota nao e publica
        if (!self::isPublicRoute($uri) && !Auth::check()) {
            header('Location: /login');
            exit;
        }

        foreach (self::$routes as $route) {
            $pattern = preg_replace('/\{[^}]+\}/', '([^/]+)', $route['path']);
            $pattern = '#^' . $pattern . '$#';

            if ($route['method'] === $method && preg_match($pattern, $uri, $matches)) {
                array_shift($matches);

                try {
                    if (!empty($route['middleware'])) {
                        Middleware::run($route['middleware']);
                    }

                    if (is_callable($route['handler'])) {
                        call_user_func_array($route['handler'], $matches);
                        return;
                    }

                    [$controllerName, $action] = explode('@', $route['handler']);
                    $class = "App\\Controllers\\{$controllerName}";

                    if (!class_exists($class)) {
                        Logger::error("Controller nao encontrado: {$class}");
                        ErrorPage::render(500, 'Erro interno', 'A página solicitada não pôde ser carregada.');
                        return;
                    }

                    $controller = new $class();
                    call_user_func_array([$controller, $action], $matches);
                } catch (\Throwable $e) {
                    self::handleError($e);
                }
                return;
            }
        }

        ErrorPage::notFound();
    }

    private static function handleError(\Throwable $e): void {
        Logger::error('Erro nao tratado na rota', [
            'exception' => $e->getMessage(),
            'file'      => $e->getFile(),
            'line'      => $e->getLine(),
        ]);

        // Banco fora do ar => 503 (servico indisponivel), nao 500
        if ($e instanceof DatabaseException || $e->getPrevious() instanceof \PDOException) {
            ErrorPage::unavailable('Não foi possível falar com o banco de dados agora. Tente novamente em alguns instantes.');
        }

        ErrorPage::serverError($e);
    }
}
