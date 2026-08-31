<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Audit\AuditLogger;
use App\Core\Controller;
use App\Models\Account;
use App\Models\Investment;
use App\Services\InvestmentService;
use App\Support\FinanceInput;
use Throwable;

class InvestmentController extends Controller
{
    private function userId(): int { return (int) Auth::user()->id; }

    public function index(): void
    {
        $model = new Investment();
        $order = ($_GET['order'] ?? 'absolute') === 'percentage' ? 'percentage' : 'absolute';
        $this->view('investments/index', [
            'title' => 'Investimentos', 'investments' => $model->forUser($this->userId()),
            'totals' => $model->totals($this->userId()), 'ranking' => $model->ranked($this->userId(), $order), 'order' => $order,
        ]);
    }

    public function create(): void
    {
        $this->view('investments/form', ['title' => 'Novo investimento', 'accounts' => (new Account())->forUser($this->userId(), true)]);
    }

    public function store(): void
    {
        try {
            $id = (new InvestmentService())->create($this->userId(), $_POST);
            AuditLogger::log('create', 'investment', $id);
            $this->flash('success', 'Investimento aplicado e saldo da conta atualizado.');
        } catch (Throwable $e) { $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível cadastrar o investimento.'); }
        $this->redirect('/investimentos');
    }

    public function returnForm(string $id): void
    {
        $investment = (new Investment())->findForUser(FinanceInput::intId($id, 'Investimento', true), $this->userId());
        if (!$investment) { $this->flash('error', 'Investimento não encontrado.'); $this->redirect('/investimentos'); }
        $this->view('investments/return', ['title' => 'Registrar rendimento', 'investment' => $investment]);
    }

    public function addReturn(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Investimento', true);
            (new InvestmentService())->addReturn($this->userId(), $id, $_POST);
            AuditLogger::log('create', 'investment_return', $id, ['month' => $_POST['reference_month'] ?? null, 'year' => $_POST['reference_year'] ?? null]);
            $this->flash('success', 'Rendimento registrado.');
        } catch (Throwable $e) { $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível registrar o rendimento.'); }
        $this->redirect('/investimentos');
    }

    public function history(string $id): void
    {
        $id = FinanceInput::intId($id, 'Investimento', true); $model = new Investment();
        $investment = $model->findForUser($id, $this->userId());
        if (!$investment) { $this->flash('error', 'Investimento não encontrado.'); $this->redirect('/investimentos'); }
        $this->view('investments/history', ['title' => 'Histórico de rendimentos', 'investment' => $investment, 'returns' => $model->returnsForUser($id, $this->userId())]);
    }

    private function flash(string $type, string $message): void { $_SESSION['flash'] = ['type' => $type, 'message' => $message]; }
}
