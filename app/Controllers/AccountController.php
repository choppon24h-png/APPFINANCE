<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Audit\AuditLogger;
use App\Core\Controller;
use App\Core\Diagnostics;
use App\Core\Logger;
use App\Models\Account;
use App\Models\InvestmentType;
use App\Support\FinanceInput;
use Throwable;

class AccountController extends Controller
{
    private function userId(): int { return (int) Auth::user()->id; }

    public function index(): void
    {
        $contas = (new Account())->forUser($this->userId());
        Logger::debug('conta.listagem', ['user_id' => $this->userId(), 'total' => count($contas)]);
        $this->view('accounts/index', ['title' => 'Contas', 'accounts' => $contas]);
    }

    public function create(): void
    {
        $this->view('accounts/form', [
            'title' => 'Nova conta', 'account' => null,
            'investmentTypes' => (new InvestmentType())->forUser($this->userId(), true),
        ]);
    }

    public function store(): void
    {
        $codigo = Diagnostics::inicio('conta.cadastro', [
            'user_id' => $this->userId(), 'payload' => Diagnostics::payload($_POST),
        ]);
        try {
            $data = $this->input($_POST, true);
            $id = (new Account())->create($this->userId(), $data);
            AuditLogger::log('create', 'account', $id, ['account_type' => $data['account_type']]);
            $total = count((new Account())->forUser($this->userId()));
            Diagnostics::sucesso('conta.cadastro', $codigo, [
                'user_id' => $this->userId(), 'account_id' => $id, 'contas_do_usuario' => $total,
            ]);
            $this->flash('success', 'Conta cadastrada.');
        } catch (Throwable $e) {
            Diagnostics::falha('conta.cadastro', $codigo, $e, [
                'user_id' => $this->userId(), 'payload' => Diagnostics::payload($_POST),
            ]);
            $this->flash('error', Diagnostics::mensagem($e, $codigo, 'Não foi possível cadastrar a conta.'));
        }
        $this->redirect('/contas');
    }

    public function edit(string $id): void
    {
        $account = (new Account())->findForUser(FinanceInput::intId($id, 'Conta', true), $this->userId());
        if (!$account) { $this->flash('error', 'Conta não encontrada.'); $this->redirect('/contas'); }
        $this->view('accounts/form', [
            'title' => 'Editar conta', 'account' => $account,
            'investmentTypes' => (new InvestmentType())->forUser($this->userId(), true),
        ]);
    }

    public function update(string $id): void
    {
        $codigo = Diagnostics::inicio('conta.atualizacao', ['user_id' => $this->userId(), 'payload' => Diagnostics::payload($_POST)]);
        try {
            $id = FinanceInput::intId($id, 'Conta', true);
            (new Account())->update($id, $this->userId(), $this->input($_POST, false));
            AuditLogger::log('update', 'account', $id);
            Diagnostics::sucesso('conta.atualizacao', $codigo, ['user_id' => $this->userId(), 'account_id' => $id]);
            $this->flash('success', 'Conta atualizada.');
        } catch (Throwable $e) {
            Diagnostics::falha('conta.atualizacao', $codigo, $e, ['user_id' => $this->userId(), 'account_id' => $id]);
            $this->flash('error', Diagnostics::mensagem($e, $codigo, 'Não foi possível atualizar a conta.'));
        }
        $this->redirect('/contas');
    }

    public function toggle(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Conta', true);
            $account = (new Account())->findForUser($id, $this->userId());
            if (!$account) throw new \InvalidArgumentException('Conta não encontrada.');
            (new Account())->update($id, $this->userId(), [
                'name' => $account->name, 'bank_name' => $account->bank_name, 'account_type' => $account->account_type,
                'agency' => $account->agency, 'account_number' => $account->account_number,
                'bank_code' => $account->bank_code ?? null,
                'investment_type_id' => $account->investment_type_id ?? null,
                'investment_rate' => $account->investment_rate ?? null,
                'investment_rate_period' => $account->investment_rate_period ?? 'annual',
                'status' => $account->status === 'active' ? 'inactive' : 'active', 'notes' => $account->notes,
            ]);
            AuditLogger::log('status', 'account', $id);
            $this->flash('success', 'Status da conta atualizado.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível atualizar a conta.'); }
        $this->redirect('/contas');
    }

    public function destroy(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Conta', true);
            if (!(new Account())->delete($id, $this->userId())) throw new \RuntimeException();
            AuditLogger::log('delete', 'account', $id);
            $this->flash('success', 'Conta removida.');
        } catch (Throwable $e) { $this->flash('error', 'A conta pode estar vinculada a lançamentos ou não existe.'); }
        $this->redirect('/contas');
    }

    private function input(array $input, bool $withInitial): array
    {
        $data = [
            'name' => FinanceInput::text($input['name'] ?? null, 'Nome da conta', 120),
            'bank_name' => FinanceInput::text($input['bank_name'] ?? null, 'Banco', 120, false),
            'bank_code' => $this->bankCode($input['bank_code'] ?? null, $input['bank_name'] ?? null),
            'account_type' => FinanceInput::enum($input['account_type'] ?? 'checking', 'Tipo de conta', ['checking','savings','investment','cash','other'], 'checking'),
            'agency' => FinanceInput::text($input['agency'] ?? null, 'Agência', 40, false),
            'account_number' => FinanceInput::text($input['account_number'] ?? null, 'Número da conta', 80, false),
            'status' => FinanceInput::enum($input['status'] ?? 'active', 'Status', ['active','inactive'], 'active'),
            'notes' => FinanceInput::text($input['notes'] ?? null, 'Observações', 2000, false),
            'investment_type_id' => null,
            'investment_rate' => null,
            'investment_rate_period' => 'annual',
        ];
        if ($data['account_type'] === 'investment') {
            $tipoId = FinanceInput::intId($input['investment_type_id'] ?? null, 'Tipo de investimento');
            if ($tipoId) {
                if (!(new InvestmentType())->findForUser($tipoId, $this->userId())) {
                    throw new \InvalidArgumentException('Tipo de investimento inválido.');
                }
                $data['investment_type_id'] = $tipoId;
            }
            $data['investment_rate'] = $this->nullableDecimal($input['investment_rate'] ?? null);
            $data['investment_rate_period'] = FinanceInput::enum($input['investment_rate_period'] ?? 'annual', 'Periodicidade', ['annual','monthly'], 'annual');
        }
        if ($withInitial) {
            $data['initial_balance'] = FinanceInput::nonNegativeAmount($input['initial_balance'] ?? 0, 'Saldo inicial');
            $data['initial_date'] = FinanceInput::date($input['initial_date'] ?? date('Y-m-d'), 'Data do saldo inicial', true);
        }
        return $data;
    }

    private function nullableDecimal(mixed $value): ?float
    {
        $raw = trim((string) ($value ?? ''));
        if ($raw === '') return null;
        $raw = str_replace(',', '.', $raw);
        if (!is_numeric($raw)) throw new \InvalidArgumentException('Taxa inválida.');
        return round((float) $raw, 6);
    }

    /**
     * Codigo COMPE da instituicao. Aceita apenas 3 digitos; quando o campo
     * vem vazio (texto livre), tenta descobrir pelo nome digitado.
     */
    private function bankCode(mixed $codigo, mixed $nome): ?string
    {
        $digitos = preg_replace('/\D/', '', (string) $codigo);
        if ($digitos !== '' && strlen($digitos) <= 3) {
            return str_pad($digitos, 3, '0', STR_PAD_LEFT);
        }

        $nome = trim((string) $nome);
        if ($nome === '') {
            return null;
        }

        try {
            $achado = (new \App\Models\Bank())->search($nome, 1);
            return $achado !== [] ? (string) ($achado[0]->compe ?? '') ?: null : null;
        } catch (Throwable $e) {
            return null;
        }
    }

    private function flash(string $type, string $message): void { $_SESSION['flash'] = ['type' => $type, 'message' => $message]; }
}
