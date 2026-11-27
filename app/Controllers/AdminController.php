<?php
namespace App\Controllers;

use App\Core\Audit\AuditLogger;
use App\Core\Auth;
use App\Core\Controller;
use App\Core\Database;
use App\Core\Flash;

/**
 * Painel administrativo: visao geral, usuarios e auditoria.
 *
 * Importante: os dados financeiros continuam isolados por user_id.
 * Aqui so ha gestao de CONTAS DE ACESSO — nenhum lancamento e exposto.
 */
class AdminController extends Controller
{
    private const PER_PAGE = 25;

    /* =============================== VISÃO GERAL =============================== */

    public function index(): void
    {
        $pdo = Database::getInstance();

        $total    = (int) $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
        $ativos   = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE status = 'active'")->fetchColumn();
        $inativos = $total - $ativos;
        $novos7   = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)")->fetchColumn();
        $novos30  = (int) $pdo->query("SELECT COUNT(*) FROM users WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)")->fetchColumn();

        $porOrigem = $pdo->query("
            SELECT auth_provider AS origem, COUNT(*) AS total
            FROM users GROUP BY auth_provider ORDER BY total DESC
        ")->fetchAll();

        $porPerfil = $pdo->query("
            SELECT r.name AS perfil, r.slug, COUNT(u.id) AS total
            FROM roles r LEFT JOIN users u ON u.role_id = r.id
            GROUP BY r.id ORDER BY total DESC
        ")->fetchAll();

        $ultimosAcessos = $pdo->query("
            SELECT u.id, u.name, u.email, u.auth_provider, u.last_login_at, r.name AS role_name
            FROM users u JOIN roles r ON r.id = u.role_id
            WHERE u.last_login_at IS NOT NULL
            ORDER BY u.last_login_at DESC LIMIT 6
        ")->fetchAll();

        $ultimosCadastros = $pdo->query("
            SELECT u.id, u.name, u.email, u.auth_provider, u.created_at, u.status
            FROM users u ORDER BY u.created_at DESC LIMIT 6
        ")->fetchAll();

        $ultimasAcoes = $pdo->query("
            SELECT a.*, u.name AS user_name
            FROM audit_logs a LEFT JOIN users u ON u.id = a.user_id
            ORDER BY a.created_at DESC, a.id DESC LIMIT 8
        ")->fetchAll();

        $this->view('admin/index', [
            'title'            => 'Painel administrativo',
            'stats'            => compact('total', 'ativos', 'inativos', 'novos7', 'novos30'),
            'porOrigem'        => $porOrigem,
            'porPerfil'        => $porPerfil,
            'ultimosAcessos'   => $ultimosAcessos,
            'ultimosCadastros' => $ultimosCadastros,
            'ultimasAcoes'     => $ultimasAcoes,
        ]);
    }

    /* ================================= USUÁRIOS ================================ */

    public function users(): void
    {
        $filtros = $this->filters();
        $dados   = $this->queryUsers($filtros, true);

        $this->view('admin/users', [
            'title'    => 'Usuários',
            'usuarios' => $dados['rows'],
            'total'    => $dados['total'],
            'page'     => $dados['page'],
            'pages'    => $dados['pages'],
            'filtros'  => $filtros,
            'roles'    => $this->roles(),
            'resumo'   => $dados['resumo'],
        ]);
    }

    public function usersCsv(): void
    {
        $filtros = $this->filters();
        $dados   = $this->queryUsers($filtros, false, 5000);

        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="somase-usuarios-' . date('Y-m-d') . '.csv"');

        $out = fopen('php://output', 'w');
        fprintf($out, "\xEF\xBB\xBF");
        fputcsv($out, ['ID', 'Nome', 'E-mail', 'Nascimento', 'Idade', 'Origem', 'Perfil', 'Status', 'Cadastro', 'Último acesso'], ';');

        foreach ($dados['rows'] as $u) {
            fputcsv($out, [
                $u->id,
                $u->name,
                $u->email,
                $u->birth_date ? date('d/m/Y', strtotime($u->birth_date)) : '',
                $u->birth_date ? $this->idade($u->birth_date) : '',
                $u->auth_provider,
                $u->role_name,
                $u->status,
                date('d/m/Y H:i', strtotime($u->created_at)),
                $u->last_login_at ? date('d/m/Y H:i', strtotime($u->last_login_at)) : '',
            ], ';');
        }
        fclose($out);

        AuditLogger::log('export_users', 'user', null, ['filtros' => $filtros]);
        exit;
    }

    public function show(int $id): void
    {
        $usuario = $this->findUser($id);
        if (!$usuario) {
            $this->redirect('/admin/usuarios?erro=nao_encontrado');
        }

        $pdo = Database::getInstance();

        $stmt = $pdo->prepare("SELECT * FROM user_identities WHERE user_id = :id ORDER BY provider");
        $stmt->execute(['id' => $id]);
        $identidades = $stmt->fetchAll();

        $stmt = $pdo->prepare("
            SELECT * FROM audit_logs WHERE user_id = :id ORDER BY created_at DESC, id DESC LIMIT 12
        ");
        $stmt->execute(['id' => $id]);
        $acoes = $stmt->fetchAll();

        $stmt = $pdo->prepare("SELECT COUNT(*) FROM auth_attempts WHERE email = :email AND success = 0 AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)");
        $stmt->execute(['email' => $usuario->email]);
        $falhas = (int) $stmt->fetchColumn();

        $this->view('admin/user_show', [
            'title'       => 'Usuário · ' . $usuario->name,
            'usuario'     => $usuario,
            'identidades' => $identidades,
            'acoes'       => $acoes,
            'falhas'      => $falhas,
            'roles'       => $this->roles(),
            'idade'       => $usuario->birth_date ? $this->idade($usuario->birth_date) : null,
        ]);
    }

    public function update(int $id): void
    {
        $usuario = $this->findUser($id);
        if (!$usuario) {
            $this->redirect('/admin/usuarios?erro=nao_encontrado');
        }

        $nome   = trim(preg_replace('/\s+/u', ' ', (string) ($_POST['name'] ?? '')) ?? '');
        $roleId = (int) ($_POST['role_id'] ?? 0);
        $status = ($_POST['status'] ?? 'active') === 'inactive' ? 'inactive' : 'active';
        $eu     = Auth::user();

        $voltar = '/admin/usuarios/' . $id;

        if (mb_strlen($nome) < 3 || $roleId <= 0) {
            Flash::error('Informe um nome válido e um perfil de acesso.');
            $this->redirect($voltar);
        }

        $novoPapel = $this->roleSlug($roleId);

        // Um admin nao pode desativar nem rebaixar a si mesmo
        if ((int) $eu->id === $id) {
            if ($status !== 'active') {
                Flash::error('Você não pode desativar a própria conta.');
                $this->redirect($voltar);
            }
            if ($novoPapel !== ($usuario->role_slug ?? '')) {
                Flash::error('Você não pode alterar o próprio perfil de acesso.');
                $this->redirect($voltar);
            }
        }

        // Somente superadmin mexe em superadmin ou promove a admin/superadmin
        $ehSuper = Auth::isSuperAdmin();
        $papelAtual = $usuario->role_slug ?? 'user';

        if (!$ehSuper && ($papelAtual === 'superadmin' || in_array($novoPapel, ['admin', 'superadmin'], true))) {
            Flash::error('Apenas o superadministrador pode alterar perfis administrativos.');
            $this->redirect($voltar);
        }

        $pdo = Database::getInstance();
        $pdo->prepare("UPDATE users SET name = :name, role_id = :role_id, status = :status, updated_at = NOW() WHERE id = :id")
            ->execute(['name' => $nome, 'role_id' => $roleId, 'status' => $status, 'id' => $id]);

        AuditLogger::log('admin_update_user', 'user', $id, [
            'nome'   => $nome,
            'perfil' => $novoPapel,
            'status' => $status,
        ]);

        Flash::success('Usuário atualizado.');
        $this->redirect('/admin/usuarios/' . $id);
    }

    public function toggle(int $id): void
    {
        $usuario = $this->findUser($id);
        if (!$usuario) {
            $this->redirect('/admin/usuarios?erro=nao_encontrado');
        }

        if ((int) Auth::user()->id === $id) {
            Flash::error('Você não pode desativar a própria conta.');
            $this->redirect('/admin/usuarios/' . $id);
        }

        if (!$this->podeGerenciar($usuario)) {
            Flash::error('Apenas o superadministrador pode alterar este usuário.');
            $this->redirect('/admin/usuarios/' . $id);
        }

        $novo = $usuario->status === 'active' ? 'inactive' : 'active';

        Database::getInstance()
            ->prepare("UPDATE users SET status = :status, updated_at = NOW() WHERE id = :id")
            ->execute(['status' => $novo, 'id' => $id]);

        AuditLogger::log('admin_toggle_user', 'user', $id, ['status' => $novo]);

        Flash::success($novo === 'active' ? 'Usuário ativado.' : 'Usuário desativado.');
        $this->redirect('/admin/usuarios/' . $id);
    }

    /**
     * Redefine a senha para uma senha temporaria exibida UMA unica vez.
     * Nada de e-mail: o administrador repassa pessoalmente.
     */
    public function resetPassword(int $id): void
    {
        $usuario = $this->findUser($id);
        if (!$usuario) {
            $this->redirect('/admin/usuarios?erro=nao_encontrado');
        }

        if (!$this->podeGerenciar($usuario)) {
            Flash::error('Apenas o superadministrador pode redefinir a senha deste usuário.');
            $this->redirect('/admin/usuarios/' . $id);
        }

        $temporaria = $this->senhaTemporaria();

        Database::getInstance()
            ->prepare("UPDATE users SET password = :password, updated_at = NOW() WHERE id = :id")
            ->execute(['password' => password_hash($temporaria, PASSWORD_DEFAULT), 'id' => $id]);

        AuditLogger::log('admin_reset_password', 'user', $id);

        // Exibida uma unica vez (sessao de uso unico, consumida na proxima tela)
        $_SESSION['_senha_temporaria'] = ['user_id' => $id, 'nome' => $usuario->name, 'senha' => $temporaria];

        Flash::success('Senha temporária gerada. Copie e repasse ao usuário — ela não será exibida novamente.');
        $this->redirect('/admin/usuarios/' . $id);
    }

    /* ================================ AUDITORIA =============================== */

    public function audit(): void
    {
        $pdo = Database::getInstance();

        $usuarioId = (int) ($_GET['usuario'] ?? 0);
        $acao      = trim((string) ($_GET['acao'] ?? ''));
        $de        = trim((string) ($_GET['de'] ?? ''));
        $ate       = trim((string) ($_GET['ate'] ?? ''));
        $page      = max(1, (int) ($_GET['page'] ?? 1));

        $where  = [];
        $params = [];

        if ($usuarioId > 0) {
            $where[] = 'a.user_id = :usuario';
            $params['usuario'] = $usuarioId;
        }
        if ($acao !== '') {
            $where[] = 'a.action LIKE :acao';
            $params['acao'] = '%' . $acao . '%';
        }
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $de)) {
            $where[] = 'a.created_at >= :de';
            $params['de'] = $de . ' 00:00:00';
        }
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $ate)) {
            $where[] = 'a.created_at <= :ate';
            $params['ate'] = $ate . ' 23:59:59';
        }

        $sqlWhere = $where ? ' WHERE ' . implode(' AND ', $where) : '';

        $stmt = $pdo->prepare("SELECT COUNT(*) FROM audit_logs a{$sqlWhere}");
        $stmt->execute($params);
        $total = (int) $stmt->fetchColumn();
        $pages = max(1, (int) ceil($total / self::PER_PAGE));
        $page  = min($page, $pages);
        $offset = ($page - 1) * self::PER_PAGE;

        $stmt = $pdo->prepare("
            SELECT a.*, u.name AS user_name, u.email AS user_email
            FROM audit_logs a LEFT JOIN users u ON u.id = a.user_id
            {$sqlWhere}
            ORDER BY a.created_at DESC, a.id DESC
            LIMIT " . self::PER_PAGE . " OFFSET {$offset}
        ");
        $stmt->execute($params);
        $logs = $stmt->fetchAll();

        $acoes = $pdo->query("SELECT DISTINCT action FROM audit_logs ORDER BY action")->fetchAll(\PDO::FETCH_COLUMN);

        $this->view('admin/audit', [
            'title'    => 'Auditoria',
            'logs'     => $logs,
            'acoes'    => $acoes,
            'total'    => $total,
            'page'     => $page,
            'pages'    => $pages,
            'filtros'  => ['usuario' => $usuarioId, 'acao' => $acao, 'de' => $de, 'ate' => $ate],
            'usuarios' => $pdo->query("SELECT id, name, email FROM users ORDER BY name")->fetchAll(),
        ]);
    }

    /* ================================ AUXILIARES ============================== */

    private function filters(): array
    {
        return [
            'q'        => trim((string) ($_GET['q'] ?? '')),
            'status'   => in_array($_GET['status'] ?? '', ['active', 'inactive'], true) ? $_GET['status'] : '',
            'role'     => trim((string) ($_GET['role'] ?? '')),
            'provider' => in_array($_GET['provider'] ?? '', ['local', 'google', 'microsoft'], true) ? $_GET['provider'] : '',
            'de'       => trim((string) ($_GET['de'] ?? '')),
            'ate'      => trim((string) ($_GET['ate'] ?? '')),
            'sort'     => in_array($_GET['sort'] ?? '', ['name', 'created', 'last_login'], true) ? $_GET['sort'] : 'created',
            'dir'      => ($_GET['dir'] ?? 'desc') === 'asc' ? 'asc' : 'desc',
            'page'     => max(1, (int) ($_GET['page'] ?? 1)),
        ];
    }

    private function queryUsers(array $f, bool $paginado = true, int $limite = 0): array
    {
        $pdo    = Database::getInstance();
        $where  = [];
        $params = [];

        if ($f['q'] !== '') {
            // PDO com prepares nativos nao aceita o mesmo parametro duas vezes
            $where[] = '(u.name LIKE :q_nome OR u.email LIKE :q_email)';
            $params['q_nome']  = '%' . $f['q'] . '%';
            $params['q_email'] = '%' . $f['q'] . '%';
        }
        if ($f['status'] !== '') {
            $where[] = 'u.status = :status';
            $params['status'] = $f['status'];
        }
        if ($f['role'] !== '') {
            $where[] = 'r.slug = :role';
            $params['role'] = $f['role'];
        }
        if ($f['provider'] !== '') {
            $where[] = 'u.auth_provider = :provider';
            $params['provider'] = $f['provider'];
        }
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $f['de'])) {
            $where[] = 'u.created_at >= :de';
            $params['de'] = $f['de'] . ' 00:00:00';
        }
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $f['ate'])) {
            $where[] = 'u.created_at <= :ate';
            $params['ate'] = $f['ate'] . ' 23:59:59';
        }

        $sqlWhere = $where ? ' WHERE ' . implode(' AND ', $where) : '';

        $ordem = match ($f['sort']) {
            'name'       => 'u.name',
            'last_login' => 'u.last_login_at',
            default      => 'u.created_at',
        };
        $dir = $f['dir'] === 'asc' ? 'ASC' : 'DESC';

        $stmt = $pdo->prepare("SELECT COUNT(*) FROM users u JOIN roles r ON r.id = u.role_id{$sqlWhere}");
        $stmt->execute($params);
        $total = (int) $stmt->fetchColumn();

        $pages  = max(1, (int) ceil($total / self::PER_PAGE));
        $page   = $paginado ? min(max(1, $f['page']), $pages) : 1;
        $offset = $paginado ? ($page - 1) * self::PER_PAGE : 0;
        $limit  = $paginado ? self::PER_PAGE : max(1, $limite ?: 5000);

        $stmt = $pdo->prepare("
            SELECT u.id, u.name, u.email, u.status, u.birth_date, u.auth_provider, u.avatar_url,
                   u.last_login_at, u.created_at, u.email_verified_at, u.terms_accepted_at,
                   r.name AS role_name, r.slug AS role_slug
            FROM users u JOIN roles r ON r.id = u.role_id
            {$sqlWhere}
            ORDER BY {$ordem} {$dir}, u.id DESC
            LIMIT {$limit} OFFSET {$offset}
        ");
        $stmt->execute($params);

        $resumo = [
            'total'    => $total,
            'ativos'   => (int) $pdo->query("SELECT COUNT(*) FROM users WHERE status = 'active'")->fetchColumn(),
            'inativos' => (int) $pdo->query("SELECT COUNT(*) FROM users WHERE status = 'inactive'")->fetchColumn(),
            'google'   => (int) $pdo->query("SELECT COUNT(*) FROM users WHERE auth_provider = 'google'")->fetchColumn(),
            'microsoft'=> (int) $pdo->query("SELECT COUNT(*) FROM users WHERE auth_provider = 'microsoft'")->fetchColumn(),
        ];

        return [
            'rows'   => $stmt->fetchAll(),
            'total'  => $total,
            'page'   => $page,
            'pages'  => $pages,
            'resumo' => $resumo,
        ];
    }

    private function findUser(int $id): ?object
    {
        $stmt = Database::getInstance()->prepare("
            SELECT u.*, r.name AS role_name, r.slug AS role_slug
            FROM users u JOIN roles r ON r.id = u.role_id
            WHERE u.id = :id LIMIT 1
        ");
        $stmt->execute(['id' => $id]);
        return $stmt->fetch() ?: null;
    }

    private function roles(): array
    {
        return Database::getInstance()->query("SELECT id, slug, name FROM roles ORDER BY id")->fetchAll();
    }

    private function roleSlug(int $roleId): string
    {
        $stmt = Database::getInstance()->prepare("SELECT slug FROM roles WHERE id = :id");
        $stmt->execute(['id' => $roleId]);
        return (string) ($stmt->fetchColumn() ?: 'user');
    }

    /** Regra: so superadmin gerencia contas de superadmin. */
    private function podeGerenciar(object $usuario): bool
    {
        if (Auth::isSuperAdmin()) {
            return true;
        }
        return ($usuario->role_slug ?? 'user') !== 'superadmin';
    }

    private function idade(string $nascimento): int
    {
        try {
            return (new \DateTimeImmutable($nascimento))->diff(new \DateTimeImmutable('today'))->y;
        } catch (\Throwable $e) {
            return 0;
        }
    }

    private function senhaTemporaria(): string
    {
        $minusculas = 'abcdefghijkmnpqrstuvwxyz';
        $maiusculas = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
        $numeros    = '23456789';
        $simbolos   = '@#$%&*!?';

        $senha = $maiusculas[random_int(0, strlen($maiusculas) - 1)]
            . $minusculas[random_int(0, strlen($minusculas) - 1)]
            . $numeros[random_int(0, strlen($numeros) - 1)]
            . $simbolos[random_int(0, strlen($simbolos) - 1)];

        $todos = $minusculas . $maiusculas . $numeros . $simbolos;
        for ($i = 0; $i < 8; $i++) {
            $senha .= $todos[random_int(0, strlen($todos) - 1)];
        }

        return str_shuffle($senha);
    }
}
