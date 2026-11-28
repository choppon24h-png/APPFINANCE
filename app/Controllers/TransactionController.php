<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Audit\AuditLogger;
use App\Core\Controller;
use App\Core\Logger;
use App\Models\Account;
use App\Models\Category;
use App\Models\CostCenter;
use App\Models\Transaction;
use App\Services\Documents\AttachmentStorage;
use App\Services\FinanceService;
use App\Support\FinanceInput;
use Throwable;

class TransactionController extends Controller
{
    private function userId(): int { return (int) Auth::user()->id; }

    public function index(): void
    {
        $filters = [];
        foreach (['search','type','status','date_from','date_to','center_kind'] as $key) {
            if (!empty($_GET[$key])) $filters[$key] = trim((string) $_GET[$key]);
        }
        foreach (['account_id','category_id','cost_center_id'] as $key) {
            if (!empty($_GET[$key]) && ctype_digit((string) $_GET[$key])) $filters[$key] = (int) $_GET[$key];
        }
        $page = max(1, (int) ($_GET['page'] ?? 1));
        $model = new Transaction();
        $perPage = 20;
        $total = $model->countForUser($this->userId(), $filters);
        $this->view('transactions/index', [
            'title' => 'Lançamentos', 'transactions' => $model->paginateForUser($this->userId(), $filters, $page, $perPage),
            'filters' => $filters, 'page' => $page, 'pages' => max(1, (int) ceil($total / $perPage)),
            'accounts' => (new Account())->forUser($this->userId()),
            'categories' => (new Category())->forUser($this->userId()),
            'costCenters' => (new CostCenter())->forUser($this->userId()),
        ]);
    }

    public function create(): void
    {
        $this->view('transactions/form', $this->formData(null));
    }

    public function store(): void
    {
        try {
            $id = (new FinanceService())->createTransaction($this->userId(), $_POST);
            $this->processAttachment($id);
            AuditLogger::log('create', 'transaction', $id, ['type' => $_POST['type'] ?? null]);
            $this->flash('success', 'Lançamento salvo com sucesso.');
            $this->redirect('/lancamentos');
        } catch (Throwable $e) {
            $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível salvar o lançamento.');
            $this->redirect('/lancamentos/novo');
        }
    }

    public function edit(string $id): void
    {
        $transaction = (new Transaction())->findForUser(FinanceInput::intId($id, 'Lançamento', true), $this->userId());
        if (!$transaction) { $this->flash('error', 'Lançamento não encontrado.'); $this->redirect('/lancamentos'); }
        $this->view('transactions/form', $this->formData($transaction));
    }

    public function update(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Lançamento', true);
            (new FinanceService())->updateTransaction($this->userId(), $id, $_POST);
            $this->processAttachment($id, true);
            AuditLogger::log('update', 'transaction', $id);
            $this->flash('success', 'Lançamento atualizado.');
        } catch (Throwable $e) {
            $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível atualizar o lançamento.');
        }
        $this->redirect('/lancamentos');
    }

    public function destroy(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Lançamento', true);
            $anexo = (new Transaction())->findForUser($id, $this->userId())?->attachment_path;
            if ((new FinanceService())->deleteTransaction($this->userId(), $id)) {
                if ($anexo) (new AttachmentStorage())->delete($anexo);
                AuditLogger::log('delete', 'transaction', $id);
                $this->flash('success', 'Lançamento excluído.');
            } else $this->flash('error', 'Lançamento não encontrado.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível excluir o lançamento.'); }
        $this->redirect('/lancamentos');
    }

    public function duplicate(string $id): void
    {
        try {
            $newId = (new FinanceService())->duplicateTransaction($this->userId(), FinanceInput::intId($id, 'Lançamento', true));
            AuditLogger::log('duplicate', 'transaction', $newId);
            $this->flash('success', 'Lançamento duplicado.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível duplicar o lançamento.'); }
        $this->redirect('/lancamentos');
    }

    public function status(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Lançamento', true);
            (new FinanceService())->updateStatus($this->userId(), $id, (string) ($_POST['status'] ?? ''));
            AuditLogger::log('status', 'transaction', $id, ['status' => $_POST['status'] ?? null]);
            $this->flash('success', 'Status atualizado.');
        } catch (Throwable $e) { $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível atualizar o status.'); }
        $this->redirect('/lancamentos');
    }

    public function transferForm(): void
    {
        $this->view('transactions/transfer', ['title' => 'Transferir entre contas', 'accounts' => (new Account())->forUser($this->userId(), true)]);
    }

    public function transfer(): void
    {
        try {
            $transferId = (new FinanceService())->createTransfer($this->userId(), $_POST);
            AuditLogger::log('create', 'transfer', null, ['transfer_id' => $transferId]);
            $this->flash('success', 'Transferência concluída. Ela não foi contabilizada como receita ou despesa.');
        } catch (Throwable $e) { $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível transferir.'); }
        $this->redirect('/lancamentos');
    }

    private function formData(?object $transaction): array
    {
        return [
            'title' => $transaction ? 'Editar lançamento' : 'Novo lançamento', 'transaction' => $transaction,
            'accounts' => (new Account())->forUser($this->userId(), true),
            'categories' => (new Category())->forUser($this->userId(), null, true),
            'costCenters' => (new CostCenter())->forUser($this->userId(), true),
        ];
    }

    /** Envia/troca/remove o anexo do lancamento (falha nao desfaz o lancamento). */
    private function processAttachment(int $id, bool $isUpdate = false): void
    {
        $model = new Transaction();
        $storage = new AttachmentStorage();
        $atual = $model->findForUser($id, $this->userId());
        if (!$atual) {
            return;
        }
        $path = $atual->attachment_path ?? null;
        if ($isUpdate && !empty($_POST['remove_attachment']) && $path) {
            $storage->delete($path);
            $model->setAttachment($id, $this->userId(), null);
            $path = null;
        }
        if (empty($_FILES['attachment']['name'])) {
            return;
        }
        try {
            $novo = $storage->save($this->userId(), $_FILES['attachment']);
            if ($path) {
                $storage->delete($path);
            }
            $model->setAttachment($id, $this->userId(), $novo);
        } catch (Throwable $e) {
            Logger::warning('lancamento.anexo', ['id' => $id, 'erro' => $e->getMessage()]);
            $this->flash('warning', 'Lançamento salvo, mas o anexo não foi enviado: ' . $e->getMessage());
        }
    }

    private function flash(string $type, string $message): void
    {
        $_SESSION['flash'] = ['type' => $type, 'message' => $message];
    }
}
