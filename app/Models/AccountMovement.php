<?php
namespace App\Models;

use App\Core\Model;

class AccountMovement extends Model
{
    protected string $table = 'account_movements';

    public function record(int $accountId, ?int $transactionId, ?string $transferId, string $type, float $amount, string $date): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO account_movements (account_id, transaction_id, transfer_id, movement_type, amount, balance_after, movement_date)
             SELECT :account_id, :transaction_id, :transfer_id, :movement_type, :amount,
                    current_balance + :amount_for_balance, :movement_date
             FROM accounts WHERE id = :account_id_for_select'
        );
        $stmt->execute([
            'account_id' => $accountId, 'transaction_id' => $transactionId, 'transfer_id' => $transferId,
            'movement_type' => $type, 'amount' => number_format($amount, 2, '.', ''),
            'amount_for_balance' => number_format($amount, 2, '.', ''), 'movement_date' => $date,
            'account_id_for_select' => $accountId,
        ]);
        $update = $this->pdo->prepare('UPDATE accounts SET current_balance = current_balance + :amount WHERE id = :account_id');
        $update->execute(['amount' => number_format($amount, 2, '.', ''), 'account_id' => $accountId]);
    }

    public function removeForTransaction(int $accountId, int $transactionId): void
    {
        $stmt = $this->pdo->prepare('SELECT COALESCE(SUM(amount), 0) FROM account_movements WHERE account_id = :account_id AND transaction_id = :transaction_id');
        $stmt->execute(['account_id' => $accountId, 'transaction_id' => $transactionId]);
        $amount = (float) $stmt->fetchColumn();
        $delete = $this->pdo->prepare('DELETE FROM account_movements WHERE account_id = :account_id AND transaction_id = :transaction_id');
        $delete->execute(['account_id' => $accountId, 'transaction_id' => $transactionId]);
        if ($amount !== 0.0) {
            $update = $this->pdo->prepare('UPDATE accounts SET current_balance = current_balance - :amount WHERE id = :account_id');
            $update->execute(['amount' => number_format($amount, 2, '.', ''), 'account_id' => $accountId]);
        }
    }

    public function removeForTransfer(string $transferId): void
    {
        $stmt = $this->pdo->prepare('SELECT account_id, SUM(amount) AS amount FROM account_movements WHERE transfer_id = :transfer_id GROUP BY account_id');
        $stmt->execute(['transfer_id' => $transferId]);
        $movements = $stmt->fetchAll();
        foreach ($movements as $movement) {
            $update = $this->pdo->prepare('UPDATE accounts SET current_balance = current_balance - :amount WHERE id = :account_id');
            $update->execute(['amount' => number_format((float) $movement->amount, 2, '.', ''), 'account_id' => $movement->account_id]);
        }
        $delete = $this->pdo->prepare('DELETE FROM account_movements WHERE transfer_id = :transfer_id');
        $delete->execute(['transfer_id' => $transferId]);
    }
}
