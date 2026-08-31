<?php
namespace App\Services;

use App\Core\Database;
use App\Models\Account;
use App\Models\AccountMovement;
use App\Models\Investment;
use App\Support\FinanceInput;
use DateTimeImmutable;
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
        $data = [
            'user_id' => $userId, 'account_id' => $accountId,
            'institution' => FinanceInput::text($input['institution'] ?? null, 'Instituição', 120),
            'investment_type' => FinanceInput::text($input['investment_type'] ?? 'Outros', 'Tipo de investimento', 80),
            'name' => FinanceInput::text($input['name'] ?? null, 'Nome do investimento', 150), 'amount_invested' => $amount,
            'application_date' => $applicationDate, 'interest_rate' => $this->nullableDecimal($input['interest_rate'] ?? null),
            'rate_type' => FinanceInput::text($input['rate_type'] ?? null, 'Tipo de rentabilidade', 40, false),
            'benchmark' => FinanceInput::text($input['benchmark'] ?? null, 'Benchmark', 80, false),
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

    private function nullableDecimal(mixed $value): ?float
    {
        if ($value === null || trim((string) $value) === '') return null;
        $raw = str_replace(',', '.', trim((string) $value));
        if (!is_numeric($raw)) throw new InvalidArgumentException('Taxa inválida.');
        return round((float) $raw, 6);
    }
}
