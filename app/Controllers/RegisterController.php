<?php
namespace App\Controllers;

use App\Core\Audit\AuditLogger;
use App\Core\Auth;
use App\Core\Controller;
use App\Core\Database;
use App\Core\Flash;
use App\Core\Schema;
use App\Services\AuthAttemptService;

class RegisterController extends Controller
{
    /** /cadastro */
    public function show(): void
    {
        if (Auth::check()) {
            $this->redirect('/dashboard');
        }

        if (!$this->registrationOpen()) {
            $this->redirect('/login');
        }

        $this->view('auth/register', [
            'title'            => 'Criar conta',
            'errors'           => [],
            'old'              => [],
            'providers'        => \App\Services\OAuthService::availableProviders(),
            'minAge'           => $this->minAge(),
            'registrationOpen' => true,
            'csrf'             => $this->csrfToken(),
        ], 'auth');
    }

    /** POST /cadastro */
    public function store(): void
    {
        if (!$this->registrationOpen()) {
            $this->redirect('/login');
        }

        // Banco sem a migration 0004: mensagem clara em vez de erro 500
        if (!Schema::accessReady()) {
            \App\Core\Logger::error('Cadastro bloqueado: schema de acesso incompleto', [
                'faltando' => Schema::missingAccess(),
            ]);
            $this->renderForm([], [
                'form' => 'O cadastro está temporariamente indisponível porque o banco de dados precisa ser atualizado. Fale com o administrador.',
            ]);
            return;
        }

        $old = [
            'name'       => $this->normalizeName((string) ($_POST['name'] ?? '')),
            'email'      => mb_strtolower(trim((string) ($_POST['email'] ?? ''))),
            'birth_date' => trim((string) ($_POST['birth_date'] ?? '')),
        ];

        $errors = [];

        // Honeypot: bots preenchem campos escondidos
        if (trim((string) ($_POST['website'] ?? '')) !== '') {
            $this->renderForm($old, ['form' => 'Não foi possível concluir o cadastro. Tente novamente.']);
            return;
        }

        if (!AuthAttemptService::canRegister()) {
            $this->renderForm($old, ['form' => 'Muitos cadastros a partir deste dispositivo. Tente novamente em 1 hora.']);
            return;
        }

        // ---------- nome ----------
        if ($old['name'] === '') {
            $errors['name'] = 'Informe seu nome completo.';
        } elseif (mb_strlen($old['name']) < 3 || mb_strlen($old['name']) > 120) {
            $errors['name'] = 'O nome deve ter entre 3 e 120 caracteres.';
        } elseif (count(preg_split('/\s+/', $old['name'])) < 2) {
            $errors['name'] = 'Informe nome e sobrenome.';
        } elseif (!preg_match("/^[\p{L}\s'’\-]+$/u", $old['name'])) {
            $errors['name'] = 'Use apenas letras, espaços, hífen e apóstrofo.';
        }

        // ---------- e-mail ----------
        if ($old['email'] === '') {
            $errors['email'] = 'Informe seu e-mail.';
        } elseif (mb_strlen($old['email']) > 255) {
            $errors['email'] = 'O e-mail é muito longo.';
        } elseif (!filter_var($old['email'], FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'Informe um e-mail válido.';
        } else {
            $stmt = Database::getInstance()->prepare("SELECT id FROM users WHERE email = :email LIMIT 1");
            $stmt->execute(['email' => $old['email']]);
            if ($stmt->fetch()) {
                $errors['email'] = 'Este e-mail já está cadastrado. Faça login.';
            }
        }

        // ---------- data de nascimento ----------
        $idade = $this->ageFrom($old['birth_date']);
        if ($old['birth_date'] === '') {
            $errors['birth_date'] = 'Informe sua data de nascimento.';
        } elseif ($idade === null) {
            $errors['birth_date'] = 'Informe uma data de nascimento válida.';
        } elseif ($idade < 0) {
            $errors['birth_date'] = 'A data de nascimento não pode estar no futuro.';
        } elseif ((int) substr($old['birth_date'], 0, 4) < 1900) {
            $errors['birth_date'] = 'Informe um ano de nascimento a partir de 1900.';
        } elseif ($idade < $this->minAge()) {
            $errors['birth_date'] = 'É necessário ter pelo menos ' . $this->minAge() . ' anos para se cadastrar.';
        }

        // ---------- senha ----------
        $senha    = (string) ($_POST['password'] ?? '');
        $confirma = (string) ($_POST['password_confirm'] ?? '');

        if ($senha === '') {
            $errors['password'] = 'Crie uma senha.';
        } else {
            $problema = $this->passwordProblem($senha);
            if ($problema !== null) {
                $errors['password'] = $problema;
            }
        }

        if ($confirma === '') {
            $errors['password_confirm'] = 'Confirme a senha.';
        } elseif ($senha !== $confirma) {
            $errors['password_confirm'] = 'As senhas não conferem.';
        }

        // ---------- termos ----------
        if (empty($_POST['terms'])) {
            $errors['terms'] = 'É necessário aceitar os Termos de Uso e a Política de Privacidade.';
        }

        if ($errors) {
            $this->renderForm($old, $errors);
            return;
        }

        $pdo = Database::getInstance();

        try {
            $stmt = $pdo->prepare("SELECT id FROM roles WHERE slug = 'user' LIMIT 1");
            $stmt->execute();
            $roleId = (int) ($stmt->fetchColumn() ?: 3);

            $stmt = $pdo->prepare("
                INSERT INTO users (name, email, password, role_id, status, birth_date, auth_provider,
                                   email_verified_at, terms_accepted_at, registration_ip, created_at, updated_at)
                VALUES (:name, :email, :password, :role_id, 'active', :birth_date, 'local',
                        NULL, NOW(), :ip, NOW(), NOW())
            ");
            $stmt->execute([
                'name'       => $old['name'],
                'email'      => $old['email'],
                'password'   => password_hash($senha, PASSWORD_DEFAULT),
                'role_id'    => $roleId,
                'birth_date' => $old['birth_date'],
                'ip'         => AuthAttemptService::ip(),
            ]);

            $userId = (int) $pdo->lastInsertId();

            AuthAttemptService::record(AuthAttemptService::ACTION_REGISTER, true, $old['email']);
            AuditLogger::log('register', 'user', $userId, ['provider' => 'local']);

            $user = Auth::findUser($userId);
            if ($user) {
                Auth::loginUser($user);
            }

            Flash::success('Bem-vindo(a) ao SOMASE!');
            $this->redirect('/dashboard');
        } catch (\Throwable $e) {
            // Log completo (request id, SQLSTATE, pilha) para rastrear em /_logs.php
            $ref = \App\Core\Logger::exception($e, 'Falha ao cadastrar usuario', [
                'email' => $old['email'],
                'etapa' => 'insert users',
            ]);
            AuthAttemptService::record(AuthAttemptService::ACTION_REGISTER, false, $old['email']);

            $estrutura = (bool) preg_match('/Unknown column|doesn.t exist|42S22|42S02|1054|1146/i', $e->getMessage());
            if ($estrutura && !\App\Core\Schema::accessReady()) {
                $this->renderForm($old, [
                    'form' => 'O cadastro está temporariamente indisponível porque o banco de dados precisa ser atualizado. Fale com o administrador.',
                ]);
                return;
            }

            $this->renderForm($old, [
                'form' => 'Não foi possível concluir o cadastro agora. Tente novamente em instantes. Código do erro: ' . $ref . '.',
            ]);
        }
    }

    /** /cadastro/completar — apenas para usuarios criados por Google/Microsoft */
    public function completeForm(): void
    {
        if (!Auth::check()) {
            $this->redirect('/login');
        }

        $user = Auth::user();

        if (!empty($user->birth_date) && !empty($user->terms_accepted_at)) {
            $this->redirect('/dashboard');
        }

        $this->view('auth/complete', [
            'title'   => 'Complete seu cadastro',
            'user'    => $user,
            'errors'  => [],
            'old'     => ['birth_date' => ''],
            'minAge'  => $this->minAge(),
            'csrf'    => $this->csrfToken(),
        ], 'auth');
    }

    /** POST /cadastro/completar */
    public function completeStore(): void
    {
        if (!Auth::check()) {
            $this->redirect('/login');
        }

        $user   = Auth::user();
        $old    = ['birth_date' => trim((string) ($_POST['birth_date'] ?? ''))];
        $errors = [];
        $idade  = $this->ageFrom($old['birth_date']);

        if ($old['birth_date'] === '') {
            $errors['birth_date'] = 'Informe sua data de nascimento.';
        } elseif ($idade === null) {
            $errors['birth_date'] = 'Informe uma data de nascimento válida.';
        } elseif ($idade < 0) {
            $errors['birth_date'] = 'A data de nascimento não pode estar no futuro.';
        } elseif ((int) substr($old['birth_date'], 0, 4) < 1900) {
            $errors['birth_date'] = 'Informe um ano de nascimento a partir de 1900.';
        } elseif ($idade < $this->minAge()) {
            $errors['birth_date'] = 'É necessário ter pelo menos ' . $this->minAge() . ' anos para usar o sistema.';
        }

        if (empty($_POST['terms'])) {
            $errors['terms'] = 'É necessário aceitar os Termos de Uso e a Política de Privacidade.';
        }

        if ($errors) {
            $this->view('auth/complete', [
                'title'  => 'Complete seu cadastro',
                'user'   => $user,
                'errors' => $errors,
                'old'    => $old,
                'minAge' => $this->minAge(),
                'csrf'   => $this->csrfToken(),
            ], 'auth');
            return;
        }

        $stmt = Database::getInstance()->prepare("
            UPDATE users
            SET birth_date = :birth_date,
                terms_accepted_at = COALESCE(terms_accepted_at, NOW()),
                updated_at = NOW()
            WHERE id = :id
        ");
        $stmt->execute(['birth_date' => $old['birth_date'], 'id' => (int) $user->id]);

        Auth::refreshSession();
        AuditLogger::log('complete_profile', 'user', (int) $user->id);
        Flash::success('Cadastro completo! Bem-vindo(a) ao SOMASE.');

        $this->redirect('/dashboard');
    }

    /* ------------------------------------------------------------------ */

    private function renderForm(array $old, array $errors): void
    {
        $this->view('auth/register', [
            'title'            => 'Criar conta',
            'errors'           => $errors,
            'old'              => $old,
            'providers'        => \App\Services\OAuthService::availableProviders(),
            'minAge'           => $this->minAge(),
            'registrationOpen' => true,
            'csrf'             => $this->csrfToken(),
        ], 'auth');
    }

    private function registrationOpen(): bool
    {
        return ($_ENV['REGISTRATION_ENABLED'] ?? 'true') !== 'false';
    }

    private function minAge(): int
    {
        return max(1, (int) ($_ENV['REGISTRATION_MIN_AGE'] ?? 18));
    }

    private function normalizeName(string $name): string
    {
        $name = trim(preg_replace('/\s+/u', ' ', $name) ?? '');
        return mb_substr($name, 0, 120);
    }

    /**
     * Idade em anos ou null se a data for invalida.
     * Negativo quando a data esta no futuro.
     */
    private function ageFrom(string $date): ?int
    {
        if (!preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $date, $m)) {
            return null;
        }
        if (!checkdate((int) $m[2], (int) $m[3], (int) $m[1])) {
            return null;
        }

        $nascimento = \DateTimeImmutable::createFromFormat('Y-m-d', $date);
        if (!$nascimento) {
            return null;
        }

        $hoje = new \DateTimeImmutable('today');
        if ($nascimento > $hoje) {
            return -1;
        }

        return $nascimento->diff($hoje)->y;
    }

    private function passwordProblem(string $senha): ?string
    {
        if (mb_strlen($senha) < 8) {
            return 'A senha deve ter pelo menos 8 caracteres.';
        }
        if (!preg_match('/[A-Z]/', $senha)) {
            return 'A senha precisa de pelo menos uma letra maiúscula.';
        }
        if (!preg_match('/[a-z]/', $senha)) {
            return 'A senha precisa de pelo menos uma letra minúscula.';
        }
        if (!preg_match('/[0-9]/', $senha)) {
            return 'A senha precisa de pelo menos um número.';
        }
        if (!preg_match('/[^A-Za-z0-9]/', $senha)) {
            return 'A senha precisa de pelo menos um símbolo.';
        }
        return null;
    }
}
