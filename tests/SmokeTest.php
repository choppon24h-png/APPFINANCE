<?php
require_once __DIR__ . '/../app/bootstrap.php';

use App\Core\Database;
use App\Models\Account;
use App\Models\Investment;
use App\Models\Transaction;
use App\Services\FinanceService;
use App\Services\InvestmentService;

$pdo = Database::getInstance();
$userId = 1;
$accountIds = [];
$investmentIds = [];
$label = 'Smoke ' . date('YmdHis');

function check(bool $condition, string $message): void
{
    if (!$condition) throw new RuntimeException('FALHA: ' . $message);
    echo "OK: {$message}\n";
}

try {
    $account = new Account();
    $accountIds[] = $account->create($userId, [
        'name' => $label . ' Principal', 'bank_name' => 'Teste Local', 'account_type' => 'checking',
        'agency' => null, 'account_number' => null, 'initial_balance' => 1000.00,
        'initial_date' => date('Y-m-d'), 'status' => 'active', 'notes' => null,
    ]);
    $accountIds[] = $account->create($userId, [
        'name' => $label . ' Reserva', 'bank_name' => 'Teste Local', 'account_type' => 'savings',
        'agency' => null, 'account_number' => null, 'initial_balance' => 100.00,
        'initial_date' => date('Y-m-d'), 'status' => 'active', 'notes' => null,
    ]);

    $finance = new FinanceService();
    $finance->createTransaction($userId, [
        'type' => 'income', 'description' => $label . ' Receita', 'amount' => '2500.00', 'account_id' => $accountIds[0],
        'transaction_date' => date('Y-m-d'), 'due_date' => date('Y-m-d'), 'status' => 'received', 'frequency' => 'none',
    ]);
    $finance->createTransaction($userId, [
        'type' => 'expense', 'description' => $label . ' Despesa', 'amount' => '400.00', 'account_id' => $accountIds[0],
        'transaction_date' => date('Y-m-d'), 'due_date' => date('Y-m-d'), 'status' => 'paid', 'frequency' => 'none',
    ]);
    $finance->createTransaction($userId, [
        'type' => 'expense', 'description' => $label . ' Pendente', 'amount' => '100.00', 'account_id' => $accountIds[0],
        'transaction_date' => date('Y-m-d'), 'due_date' => date('Y-m-d'), 'status' => 'pending', 'frequency' => 'none',
    ]);
    check(abs((float) $account->findForUser($accountIds[0], $userId)->current_balance - 3100.00) < 0.01, 'despesa pendente não reduz saldo disponível');

    $finance->createTransfer($userId, ['from_account_id' => $accountIds[0], 'to_account_id' => $accountIds[1], 'amount' => '500.00', 'transaction_date' => date('Y-m-d'), 'description' => $label . ' Transferência']);
    check(abs((float) $account->findForUser($accountIds[0], $userId)->current_balance - 2600.00) < 0.01, 'conta de origem registra saída da transferência');
    check(abs((float) $account->findForUser($accountIds[1], $userId)->current_balance - 600.00) < 0.01, 'conta de destino registra entrada da transferência');

    $recurringId = $finance->createTransaction($userId, [
        'type' => 'expense', 'description' => $label . ' Recorrência', 'amount' => '75.00', 'account_id' => $accountIds[0],
        'transaction_date' => date('Y-m-d'), 'due_date' => date('Y-m-d'), 'status' => 'pending', 'frequency' => 'monthly',
        'end_date' => date('Y-m-d', strtotime('+2 months')),
    ]);
    $recurringCount = (int) $pdo->query("SELECT COUNT(*) FROM transactions WHERE description = " . $pdo->quote($label . ' Recorrência'))->fetchColumn();
    check($recurringCount >= 3, 'recorrência prepara lançamentos futuros sem duplicação');

    $investmentIds[] = (new InvestmentService())->create($userId, [
        'account_id' => $accountIds[0], 'institution' => 'Teste Local', 'investment_type' => 'CDB', 'name' => $label . ' Investimento',
        'amount_invested' => '300.00', 'application_date' => date('Y-m-d'), 'status' => 'active',
    ]);
    (new InvestmentService())->addReturn($userId, $investmentIds[0], ['reference_month' => date('n'), 'reference_year' => date('Y'), 'initial_value' => '300.00', 'return_amount' => '30.00']);
    $investment = (new Investment())->findForUser($investmentIds[0], $userId);
    check($investment !== null, 'aplicação é vinculada ao usuário correto');
    check(abs((float) $account->findForUser($accountIds[0], $userId)->current_balance - 2300.00) < 0.01, 'aplicação reduz a conta de origem');
    (new InvestmentService())->redeem($userId, $investmentIds[0], ['amount' => '100.00', 'movement_date' => date('Y-m-d'), 'notes' => 'Teste de resgate']);
    check(abs((float) $account->findForUser($accountIds[0], $userId)->current_balance - 2400.00) < 0.01, 'resgate devolve valor à conta de origem');

    $summary = (new Transaction())->summary($userId, date('Y-m-01'), date('Y-m-t'));
    check(abs((float) $summary->income - 2500.00) < 0.01, 'dashboard soma receitas recebidas');
    check(abs((float) $summary->expense - 400.00) < 0.01, 'dashboard soma apenas despesas pagas');
    check((int) $pdo->query("SELECT COUNT(*) FROM transactions WHERE user_id = {$userId} AND type = 'transfer' AND description LIKE " . $pdo->quote($label . '%'))->fetchColumn() === 2, 'transferência cria dois lançamentos internos');
    echo "SMOKE TEST PASSOU\n";
} finally {
    $placeholders = implode(',', array_fill(0, count($accountIds), '?'));
    if ($accountIds) {
        $pdo->prepare("DELETE FROM account_movements WHERE account_id IN ({$placeholders})")->execute($accountIds);
        $pdo->prepare("DELETE FROM transactions WHERE account_id IN ({$placeholders})")->execute($accountIds);
        $pdo->prepare("DELETE FROM investments WHERE account_id IN ({$placeholders})")->execute($accountIds);
        $pdo->prepare("DELETE FROM recurring_transactions WHERE account_id IN ({$placeholders})")->execute($accountIds);
        $pdo->prepare("DELETE FROM accounts WHERE id IN ({$placeholders}) AND user_id = ?")->execute([...$accountIds, $userId]);
    }
}
