<?php
namespace App\Services;

use App\Core\Database;
use App\Models\Account;
use App\Models\AccountMovement;
use App\Models\Investment;
use App\Models\InvestmentType;
use App\Support\FinanceInput;
use InvalidArgumentException;

class InvestmentService
{
    private \PDO $pdo;
    private Investment $investments;
    private Account $accounts;
    private AccountMovement $movements;

    public function __construct()
    {
        $this->pdo = Database::getInstance();
        $this->investments = new Investment();
        $this->accounts = new Account();
        $this->movements = new AccountMovement();
    }

    public function create(int $userId, array $input): int
    {
        $accountId = FinanceInput::intId($input['account_id'] ?? null, 'Conta', true);
        if (!$this->accounts->findForUser($accountId, $userId)) throw new InvalidArgumentException('Conta inválida.');
        $applicationDate = FinanceInput::date($input['application_date'] ?? date('Y-m-d'), 'Data da aplicação', true);
        $amount = FinanceInput::amount($input['amount_invested'] ?? null, 'Valor aplicado');
        $tipo = $this->investmentType($userId, $input);
        $data = [
            'user_id' => $userId, 'account_id' => $accountId,
            'institution' => FinanceInput::text($input['institution'] ?? null, 'Instituição', 120),
            'investment_type' => $tipo['name'],
            'investment_type_id' => $tipo['id'],
            'name' => FinanceInput::text($input['name'] ?? null, 'Nome do investimento', 150), 'amount_invested' => $amount,
            'application_date' => $applicationDate, 'interest_rate' => $this->nullableDecimal($input['interest_rate'] ?? null),
            'rate_type' => FinanceInput::text($input['rate_type'] ?? null, 'Tipo de rentabilidade', 40, false),
            'benchmark' => FinanceInput::text($input['benchmark'] ?? null, 'Benchmark', 80, false),
            'benchmark_rate' => $this->nullableDecimal($input['benchmark_rate'] ?? null),
            'rate_period' => FinanceInput::enum($input['rate_period'] ?? 'annual', 'Periodicidade da taxa', ['annual', 'monthly'], 'annual'),
            'liquidity' => FinanceInput::text($input['liquidity'] ?? null, 'Liquidez', 80, false),
            'maturity_date' => FinanceInput::date($input['maturity_date'] ?? null, 'Data de vencimento', false),
            'status' => FinanceInput::enum($input['status'] ?? 'active', 'Status', ['active','inactive','matured'], 'active'),
            'notes' => FinanceInput::text($input['notes'] ?? null, 'Observações', 2000, false),
        ];
        $this->pdo->beginTransaction();
        try {
            $id = $this->investments->create($data);
            $this->investments->addMovement(['investment_id' => $id, 'type' => 'application', 'amount' => $amount, 'movement_date' => $applicationDate, 'rate' => $data['interest_rate'], 'notes' => 'Aplicação inicial']);
            $this->movements->record($accountId, null, null, 'investment', -$amount, $applicationDate);
            $this->pdo->commit();
            return $id;
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    public function update(int $userId, int $investmentId, array $input): bool
    {
        $investment = $this->investments->findForUser($investmentId, $userId);
        if (!$investment) throw new InvalidArgumentException('Investimento não encontrado.');
        $accountId = FinanceInput::intId($input['account_id'] ?? $investment->account_id, 'Conta', true);
        if (!$this->accounts->findForUser($accountId, $userId)) throw new InvalidArgumentException('Conta inválida.');
        $tipo = $this->investmentType($userId, $input, $investment);
        $data = [
            'account_id' => $accountId,
            'institution' => FinanceInput::text($input['institution'] ?? $investment->institution, 'Instituição', 120),
            'investment_type' => $tipo['name'],
            'investment_type_id' => $tipo['id'],
            'name' => FinanceInput::text($input['name'] ?? $investment->name, 'Nome do investimento', 150),
            'interest_rate' => $this->nullableDecimal($input['interest_rate'] ?? null),
            'rate_type' => FinanceInput::text($input['rate_type'] ?? null, 'Tipo de rentabilidade', 40, false),
            'benchmark' => FinanceInput::text($input['benchmark'] ?? null, 'Benchmark', 80, false),
            'benchmark_rate' => $this->nullableDecimal($input['benchmark_rate'] ?? null),
            'rate_period' => FinanceInput::enum($input['rate_period'] ?? 'annual', 'Periodicidade da taxa', ['annual', 'monthly'], 'annual'),
            'liquidity' => FinanceInput::text($input['liquidity'] ?? null, 'Liquidez', 80, false),
            'maturity_date' => FinanceInput::date($input['maturity_date'] ?? null, 'Data de vencimento', false),
            'status' => FinanceInput::enum($input['status'] ?? 'active', 'Status', ['active','inactive','matured'], 'active'),
            'notes' => FinanceInput::text($input['notes'] ?? null, 'Observações', 2000, false),
        ];
        return $this->investments->update($investmentId, $userId, $data);
    }

    public function redeem(int $userId, int $investmentId, array $input): void
    {
        $investment = $this->investments->findForUser($investmentId, $userId);
        if (!$investment) throw new InvalidArgumentException('Investimento não encontrado.');
        $amount = FinanceInput::amount($input['amount'] ?? null, 'Valor do resgate');
        $date = FinanceInput::date($input['movement_date'] ?? date('Y-m-d'), 'Data do resgate', true);
        $stmt = $this->pdo->prepare("SELECT i.amount_invested + COALESCE((SELECT SUM(CASE WHEN type = 'income' OR type = 'adjustment' THEN amount WHEN type = 'redemption' THEN -amount ELSE 0 END) FROM investment_movements WHERE investment_id = i.id), 0) + COALESCE((SELECT SUM(return_amount) FROM investment_returns WHERE investment_id = i.id), 0) FROM investments i WHERE i.id = :id AND i.user_id = :user_id");
        $stmt->execute(['id' => $investmentId, 'user_id' => $userId]);
        $currentValue = (float) $stmt->fetchColumn();
        if ($amount > $currentValue + 0.009) throw new InvalidArgumentException('O resgate não pode ser maior que o patrimônio atual.');
        $this->pdo->beginTransaction();
        try {
            $this->investments->addMovement(['investment_id' => $investmentId, 'type' => 'redemption', 'amount' => $amount, 'movement_date' => $date, 'rate' => null, 'notes' => FinanceInput::text($input['notes'] ?? null, 'Observações', 255, false)]);
            $this->movements->record((int) $investment->account_id, null, null, 'investment', $amount, $date);
            $this->pdo->commit();
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    public function addReturn(int $userId, int $investmentId, array $input): void
    {
        $investment = $this->investments->findForUser($investmentId, $userId);
        if (!$investment) throw new InvalidArgumentException('Investimento não encontrado.');
        $month = (int) ($input['reference_month'] ?? date('n')); $year = (int) ($input['reference_year'] ?? date('Y'));
        if ($month < 1 || $month > 12 || $year < 2000 || $year > 2200) throw new InvalidArgumentException('Período inválido.');
        $initial = FinanceInput::amount($input['initial_value'] ?? $investment->amount_invested, 'Valor inicial');
        $returnAmount = FinanceInput::amount($input['return_amount'] ?? null, 'Rendimento');
        $percentage = $initial > 0 ? round(($returnAmount / $initial) * 100, 6) : 0;
        $final = round($initial + $returnAmount, 2);
        $this->investments->addReturn([
            'investment_id' => $investmentId, 'reference_month' => $month, 'reference_year' => $year,
            'initial_value' => $initial, 'return_amount' => $returnAmount, 'return_percentage' => $percentage, 'final_value' => $final,
        ]);
    }

    /**
     * Resolve o tipo de investimento escolhido no catálogo. Quando o campo
     * investment_type_id vem vazio, aceita o texto livre antigo.
     *
     * @return array{id:?int,name:string}
     */
    private function investmentType(int $userId, array $input, ?object $atual = null): array
    {
        $id = FinanceInput::intId($input['investment_type_id'] ?? null, 'Tipo de investimento');
        if ($id !== null) {
            $tipo = (new InvestmentType())->findForUser($id, $userId);
            if (!$tipo) throw new InvalidArgumentException('Tipo de investimento inválido.');
            return ['id' => (int) $tipo->id, 'name' => $tipo->name];
        }
        $texto = trim((string) ($input['investment_type'] ?? ''));
        if ($texto !== '') {
            return ['id' => null, 'name' => mb_substr($texto, 0, 80)];
        }
        if ($atual) {
            return ['id' => $atual->investment_type_id ?? null, 'name' => $atual->investment_type];
        }
        return ['id' => null, 'name' => 'Outros'];
    }

    private function nullableDecimal(mixed $value): ?float
    {
        if ($value === null || trim((string) $value) === '') return null;
        $raw = str_replace(',', '.', trim((string) $value));
        if (!is_numeric($raw)) throw new InvalidArgumentException('Taxa inválida.');
        return round((float) $raw, 6);
    }
}
