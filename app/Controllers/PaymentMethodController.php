<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Audit\AuditLogger;
use App\Core\Controller;
use App\Models\PaymentMethod;
use App\Support\FinanceInput;
use App\Support\Slug;
use Throwable;

class PaymentMethodController extends Controller
{
    private function userId(): int { return (int) Auth::user()->id; }

    public function index(): void
    {
        $model = new PaymentMethod();
        $edit = !empty($_GET['edit']) && ctype_digit((string) $_GET['edit'])
            ? $model->findForUser((int) $_GET['edit'], $this->userId())
            : null;
        $this->view('catalog/payment_methods', [
            'title' => 'Formas de pagamento',
            'methods' => $model->forUser($this->userId()),
            'editMethod' => $edit,
            'kinds' => PaymentMethod::KINDS,
        ]);
    }

    public function store(): void
    {
        try {
            $data = $this->input($_POST);
            $id = (new PaymentMethod())->create($this->userId(), $data);
            AuditLogger::log('create', 'payment_method', $id);
            $this->flash('success', 'Forma de pagamento criada.');
        } catch (Throwable $e) {
            $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível criar a forma de pagamento.');
        }
        $this->redirect('/formas-pagamento');
    }

    public function update(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Forma de pagamento', true);
            $model = new PaymentMethod();
            if (!$model->findForUser($id, $this->userId())) throw new \RuntimeException();
            $model->update($id, $this->userId(), $this->input($_POST, $id));
            AuditLogger::log('update', 'payment_method', $id);
            $this->flash('success', 'Forma de pagamento atualizada.');
        } catch (Throwable $e) {
            $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível atualizar a forma de pagamento.');
        }
        $this->redirect('/formas-pagamento');
    }

    public function toggle(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Forma de pagamento', true);
            $model = new PaymentMethod();
            $method = $model->findForUser($id, $this->userId());
            if (!$method) throw new \RuntimeException();
            $model->update($id, $this->userId(), [
                'name' => $method->name, 'slug' => $method->slug, 'kind' => $method->kind,
                'icon' => $method->icon, 'sort_order' => $method->sort_order,
                'status' => $method->status === 'active' ? 'inactive' : 'active',
            ]);
            AuditLogger::log('status', 'payment_method', $id);
            $this->flash('success', 'Status atualizado.');
        } catch (Throwable $e) {
            $this->flash('error', 'Não foi possível atualizar o status.');
        }
        $this->redirect('/formas-pagamento');
    }

    public function destroy(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Forma de pagamento', true);
            if (!(new PaymentMethod())->delete($id, $this->userId())) throw new \RuntimeException();
            AuditLogger::log('delete', 'payment_method', $id);
            $this->flash('success', 'Forma de pagamento removida.');
        } catch (Throwable $e) {
            $this->flash('error', 'Não foi possível remover a forma de pagamento.');
        }
        $this->redirect('/formas-pagamento');
    }

    private function input(array $input, ?int $ignorarId = null): array
    {
        $nome = FinanceInput::text($input['name'] ?? null, 'Nome', 80);
        $model = new PaymentMethod();
        $existentes = $model->slugsForUser($this->userId());
        $atual = $ignorarId ? $model->findForUser($ignorarId, $this->userId()) : null;
        if ($atual) {
            $existentes = array_values(array_diff($existentes, [$atual->slug]));
        }
        $slugInformado = trim((string) ($input['slug'] ?? ''));
        $slug = $slugInformado !== '' ? Slug::make($slugInformado) : Slug::make($nome);
        // Ao editar, mantem o slug atual se o usuario nao pediu outro.
        if ($atual && $slugInformado === '') $slug = $atual->slug;
        $slug = Slug::unique($slug, $existentes);

        return [
            'name' => mb_strtoupper($nome, 'UTF-8'),
            'slug' => $slug,
            'kind' => FinanceInput::enum($input['kind'] ?? 'other', 'Tipo', array_keys(PaymentMethod::KINDS), 'other'),
            'icon' => FinanceInput::text($input['icon'] ?? null, 'Ícone', 20, false),
            'sort_order' => (int) ($input['sort_order'] ?? 0),
            'status' => FinanceInput::enum($input['status'] ?? 'active', 'Status', ['active', 'inactive'], 'active'),
        ];
    }

    private function flash(string $type, string $message): void { $_SESSION['flash'] = ['type' => $type, 'message' => $message]; }
}
