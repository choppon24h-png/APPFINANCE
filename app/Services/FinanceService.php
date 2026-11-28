<?php
namespace App\Services;

use App\Core\Database;
use App\Models\Account;
use App\Models\AccountMovement;
use App\Models\Category;
use App\Models\CostCenter;
use App\Models\Investment;
use App\Models\Transaction;
use App\Support\FinanceInput;
use DateTimeImmutable;
use InvalidArgumentException;

class FinanceService
{
    private \PDO $pdo;
    private Transaction $transactions;
    private Account $accounts;
    private AccountMovement $accountMovements;
    private Category $categories;
    private CostCenter $costCenters;

    public function __construct()
    {
        $this->pdo = Database::getInstance();
        $this->transactions = new Transaction();
        $this->accounts = new Account();
        $this->accountMovements = new AccountMovement();
        $this->categories = new Category();
        $this->costCenters = new CostCenter();
    }

    public function createTransaction(int $userId, array $input): int
    {
        $data = $this->transactionData($userId, $input);
        $this->assertReferences($userId, $data);
        $this->pdo->beginTransaction();
        try {
            $recurrenceId = null;
            if ($data['frequency'] !== 'none') {
                $stmt = $this->pdo->prepare(
                    'INSERT INTO recurring_transactions
                     (user_id, account_id, category_id, cost_center_id, type, description, amount,
                      frequency, start_date, end_date, next_date, status, payment_method, notes)
                     VALUES (:user_id, :account_id, :category_id, :cost_center_id, :type, :description, :amount,
                      :frequency, :start_date, :end_date, :next_date, \'active\', :payment_method, :notes)'
                );
                $stmt->execute([
                    'user_id' => $userId, 'account_id' => $data['account_id'], 'category_id' => $data['category_id'],
                    'cost_center_id' => $data['cost_center_id'], 'type' => $data['type'], 'description' => $data['description'],
                    'amount' => $data['amount'], 'frequency' => $data['frequency'], 'start_date' => $data['transaction_date'],
                    'end_date' => $data['end_date'], 'next_date' => $this->nextDate($data['transaction_date'], $data['frequency']),
                    'payment_method' => $data['payment_method'], 'notes' => $data['notes'],
                ]);
                $recurrenceId = (int) $this->pdo->lastInsertId();
            }
            $transactionData = [
                'user_id' => $userId, 'account_id' => $data['account_id'], 'category_id' => $data['category_id'],
                'cost_center_id' => $data['cost_center_id'], 'type' => $data['type'], 'description' => $data['description'],
                'amount' => $data['amount'], 'transaction_date' => $data['transaction_date'], 'due_date' => $data['due_date'],
                'payment_date' => $data['payment_date'], 'status' => $data['status'], 'payment_method' => $data['payment_method'],
                'notes' => $data['notes'], 'recurrence_id' => $recurrenceId,
                'recurrence_key' => $recurrenceId ? $recurrenceId . ':' . $data['transaction_date'] : null, 'transfer_id' => null,
                'document_code' => $data['document_code'] ?: null, 'import_ref' => null, 'attachment_path' => null,
            ];
            $transactionId = $this->transactions->create($transactionData);
            $this->applyTransactionMovement($transactionId, $data);
            if ($recurrenceId) {
                $limit = $data['end_date'] ?: (new DateTimeImmutable($data['transaction_date']))->modify('+12 months')->format('Y-m-d');
                $this->generateRecurringInternal($userId, $recurrenceId, $limit);
            }
            $this->pdo->commit();
            return $transactionId;
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    public function updateTransaction(int $userId, int $id, array $input): bool
    {
        $old = $this->transactions->findForUser($id, $userId);
        if (!$old) throw new InvalidArgumentException('Lançamento não encontrado.');
        $data = $this->transactionData($userId, $input, false);
        $this->assertReferences($userId, $data);
        $this->pdo->beginTransaction();
        try {
            $this->accountMovements->removeForTransaction((int) $old->account_id, $id);
            $atualizacao = [
                'account_id' => $data['account_id'], 'category_id' => $data['category_id'], 'cost_center_id' => $data['cost_center_id'],
                'type' => $data['type'], 'description' => $data['description'], 'amount' => $data['amount'],
                'transaction_date' => $data['transaction_date'], 'due_date' => $data['due_date'], 'payment_date' => $data['payment_date'],
                'status' => $data['status'], 'payment_method' => $data['payment_method'], 'notes' => $data['notes'],
            ];
            // So grava document_code quando o campo veio no POST (evita apagar
            // o codigo lido do boleto em uma edicao que nao exibe o campo).
            if (array_key_exists('document_code', $input)) {
                $atualizacao['document_code'] = $data['document_code'] ?: null;
            }
            $ok = $this->transactions->update($id, $userId, $atualizacao);
            $data['recurrence_id'] = $old->recurrence_id;
            $this->applyTransactionMovement($id, $data);
            $this->pdo->commit();
            return $ok;
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    public function deleteTransaction(int $userId, int $id): bool
    {
        $old = $this->transactions->findForUser($id, $userId);
        if (!$old) return false;
        $this->pdo->beginTransaction();
        try {
            $this->accountMovements->removeForTransaction((int) $old->account_id, $id);
            $stmt = $this->pdo->prepare('DELETE FROM transactions WHERE id = :id AND user_id = :user_id');
            $ok = $stmt->execute(['id' => $id, 'user_id' => $userId]);
            $this->pdo->commit();
            return $ok;
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    public function duplicateTransaction(int $userId, int $id): int
    {
        $old = $this->transactions->findForUser($id, $userId);
        if (!$old) throw new InvalidArgumentException('Lançamento não encontrado.');
        return $this->createTransaction($userId, [
            'type' => $old->type, 'description' => $old->description . ' (cópia)', 'amount' => $old->amount,
            'category_id' => $old->category_id, 'cost_center_id' => $old->cost_center_id, 'account_id' => $old->account_id,
            'transaction_date' => date('Y-m-d'), 'due_date' => date('Y-m-d'), 'status' => $old->type === 'income' ? 'received' : 'paid',
            'payment_method' => $old->payment_method, 'notes' => $old->notes, 'frequency' => 'none',
        ]);
    }

    public function updateStatus(int $userId, int $id, string $status): bool
    {
        $old = $this->transactions->findForUser($id, $userId);
        if (!$old) return false;
        $allowed = $old->type === 'income' ? ['expected', 'received', 'late', 'cancelled'] : ['pending', 'paid', 'overdue', 'cancelled'];
        $status = FinanceInput::enum($status, 'Status', $allowed, $allowed[0]);
        $this->pdo->beginTransaction();
        try {
            $this->accountMovements->removeForTransaction((int) $old->account_id, $id);
            $paymentDate = in_array($status, ['paid', 'received'], true) ? date('Y-m-d') : null;
            $stmt = $this->pdo->prepare('UPDATE transactions SET status = :status, payment_date = :payment_date WHERE id = :id AND user_id = :user_id');
            $ok = $stmt->execute(['status' => $status, 'payment_date' => $paymentDate, 'id' => $id, 'user_id' => $userId]);
            $data = ['account_id' => (int) $old->account_id, 'type' => $old->type, 'amount' => (float) $old->amount, 'status' => $status, 'transaction_date' => $old->transaction_date];
            $this->applyTransactionMovement($id, $data);
            $this->pdo->commit();
            return $ok;
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    public function createTransfer(int $userId, array $input): string
    {
        $from = FinanceInput::intId($input['from_account_id'] ?? null, 'Conta de origem', true);
        $to = FinanceInput::intId($input['to_account_id'] ?? null, 'Conta de destino', true);
        if ($from === $to) throw new InvalidArgumentException('Escolha contas diferentes para a transferência.');
        $amount = FinanceInput::amount($input['amount'] ?? null);
        $date = FinanceInput::date($input['transaction_date'] ?? null, 'Data', true);
        $description = FinanceInput::text($input['description'] ?? 'Transferência entre contas', 'Descrição', 180);
        if (!$this->accounts->findForUser($from, $userId) || !$this->accounts->findForUser($to, $userId)) {
            throw new InvalidArgumentException('Conta de origem ou destino inválida.');
        }
        $transferId = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x', random_int(0, 65535), random_int(0, 65535), random_int(0, 65535), random_int(0, 4095) | 0x4000, random_int(0, 16383) | 0x8000, random_int(0, 65535), random_int(0, 65535), random_int(0, 65535));
        $this->pdo->beginTransaction();
        try {
            $fromId = $this->transactions->create([
                'user_id' => $userId, 'account_id' => $from, 'category_id' => null, 'cost_center_id' => null,
                'type' => 'transfer', 'description' => $description, 'amount' => $amount, 'transaction_date' => $date,
                'due_date' => null, 'payment_date' => $date, 'status' => 'paid', 'payment_method' => null,
                'notes' => 'Transferência para conta interna', 'recurrence_id' => null, 'recurrence_key' => null, 'transfer_id' => $transferId,
            ]);
            $toId = $this->transactions->create([
                'user_id' => $userId, 'account_id' => $to, 'category_id' => null, 'cost_center_id' => null,
                'type' => 'transfer', 'description' => $description, 'amount' => $amount, 'transaction_date' => $date,
                'due_date' => null, 'payment_date' => $date, 'status' => 'paid', 'payment_method' => null,
                'notes' => 'Transferência recebida de conta interna', 'recurrence_id' => null, 'recurrence_key' => null, 'transfer_id' => $transferId,
            ]);
            $this->accountMovements->record($from, $fromId, $transferId, 'transfer', -$amount, $date);
            $this->accountMovements->record($to, $toId, $transferId, 'transfer', $amount, $date);
            $this->pdo->commit();
            return $transferId;
        } catch (\Throwable $e) {
            if ($this->pdo->inTransaction()) $this->pdo->rollBack();
            throw $e;
        }
    }

    private function transactionData(int $userId, array $input, bool $withFrequency = true): array
    {
        $type = FinanceInput::enum($input['type'] ?? null, 'Tipo', ['income', 'expense'], 'expense');
        $statusDefault = $type === 'income' ? 'received' : 'paid';
        $status = FinanceInput::enum($input['status'] ?? $statusDefault, 'Status', $type === 'income' ? ['expected','received','late','cancelled'] : ['pending','paid','overdue','cancelled'], $statusDefault);
        $date = FinanceInput::date($input['transaction_date'] ?? date('Y-m-d'), 'Data do lançamento', true);
        $frequency = $withFrequency ? FinanceInput::enum($input['frequency'] ?? 'none', 'Recorrência', ['none','daily','weekly','biweekly','monthly','bimonthly','quarterly','semiannual','annual'], 'none') : 'none';
        $endDate = FinanceInput::date($input['end_date'] ?? null, 'Data final da recorrência', false);
        if ($frequency === 'none') $endDate = null;
        if ($endDate && $endDate < $date) throw new InvalidArgumentException('A data final deve ser igual ou posterior ao início.');
        return [
            'type' => $type, 'status' => $status, 'description' => FinanceInput::text($input['description'] ?? null, 'Descrição', 180),
            'amount' => FinanceInput::amount($input['amount'] ?? null), 'account_id' => FinanceInput::intId($input['account_id'] ?? null, 'Conta', true),
            'category_id' => FinanceInput::intId($input['category_id'] ?? null, 'Categoria'), 'cost_center_id' => FinanceInput::intId($input['cost_center_id'] ?? null, 'Centro de custo'),
            'transaction_date' => $date, 'due_date' => FinanceInput::date($input['due_date'] ?? null, 'Data de vencimento', false),
            'payment_date' => FinanceInput::date($input['payment_date'] ?? null, 'Data de pagamento', false),
            'payment_method' => FinanceInput::nullableEnum($input['payment_method'] ?? null, 'Forma de pagamento', ['pix','debit','credit','boleto','cash','transfer','other']),
            'notes' => FinanceInput::text($input['notes'] ?? null, 'Observação', 2000, false), 'frequency' => $frequency, 'end_date' => $endDate,
            'document_code' => FinanceInput::text($input['document_code'] ?? null, 'Código do documento', 64, false),
        ];
    }

    private function assertReferences(int $userId, array $data): void
    {
        if (!$this->accounts->findForUser((int) $data['account_id'], $userId)) throw new InvalidArgumentException('Conta inválida.');
        if ($data['category_id'] && !$this->categories->findForUser((int) $data['category_id'], $userId)) throw new InvalidArgumentException('Categoria inválida.');
        if ($data['cost_center_id'] && !$this->costCenters->findForUser((int) $data['cost_center_id'], $userId)) throw new InvalidArgumentException('Centro de custo inválido.');
    }

    private function applyTransactionMovement(int $transactionId, array $data): void
    {
        $signed = 0.0;
        if (($data['type'] ?? '') === 'income' && ($data['status'] ?? '') === 'received') $signed = (float) $data['amount'];
        if (($data['type'] ?? '') === 'expense' && ($data['status'] ?? '') === 'paid') $signed = -(float) $data['amount'];
        if ($signed !== 0.0) $this->accountMovements->record((int) $data['account_id'], $transactionId, null, 'transaction', $signed, $data['transaction_date']);
    }

    private function generateRecurringInternal(int $userId, int $recurrenceId, string $through): int
    {
        $stmt = $this->pdo->prepare('SELECT * FROM recurring_transactions WHERE id = :id AND user_id = :user_id AND status = \'active\' LIMIT 1');
        $stmt->execute(['id' => $recurrenceId, 'user_id' => $userId]);
        $recurrence = $stmt->fetch();
        if (!$recurrence) return 0;
        $date = new DateTimeImmutable($recurrence->next_date);
        $throughDate = new DateTimeImmutable($through);
        $endDate = $recurrence->end_date ? new DateTimeImmutable($recurrence->end_date) : null;
        $created = 0;
        $insert = $this->pdo->prepare(
            'INSERT IGNORE INTO transactions
             (user_id, account_id, category_id, cost_center_id, type, description, amount, transaction_date,
              due_date, payment_date, status, payment_method, notes, recurrence_id, recurrence_key, transfer_id)
             VALUES (:user_id, :account_id, :category_id, :cost_center_id, :type, :description, :amount, :transaction_date,
              :due_date, NULL, :status, :payment_method, :notes, :recurrence_id, :recurrence_key, NULL)'
        );
        while ($date <= $throughDate && (!$endDate || $date <= $endDate) && $created < 120) {
            $status = $recurrence->type === 'income' ? 'expected' : 'pending';
            $params = [
                'user_id' => $userId, 'account_id' => $recurrence->account_id, 'category_id' => $recurrence->category_id,
                'cost_center_id' => $recurrence->cost_center_id, 'type' => $recurrence->type, 'description' => $recurrence->description,
                'amount' => $recurrence->amount, 'transaction_date' => $date->format('Y-m-d'), 'due_date' => $date->format('Y-m-d'),
                'status' => $status, 'payment_method' => $recurrence->payment_method, 'notes' => $recurrence->notes,
                'recurrence_id' => $recurrenceId, 'recurrence_key' => $recurrenceId . ':' . $date->format('Y-m-d'),
            ];
            $insert->execute($params);
            if ($insert->rowCount() > 0) $created++;
            $date = new DateTimeImmutable($this->nextDate($date->format('Y-m-d'), $recurrence->frequency));
        }
        $next = $date->format('Y-m-d');
        $nextStmt = $this->pdo->prepare('UPDATE recurring_transactions SET next_date = :next_date WHERE id = :id AND user_id = :user_id');
        $nextStmt->execute(['next_date' => $next, 'id' => $recurrenceId, 'user_id' => $userId]);
        return $created;
    }

    private function nextDate(string $date, string $frequency): string
    {
        $base = new DateTimeImmutable($date);
        if (in_array($frequency, ['monthly', 'bimonthly', 'quarterly', 'semiannual', 'annual'], true)) {
            $months = ['monthly' => 1, 'bimonthly' => 2, 'quarterly' => 3, 'semiannual' => 6, 'annual' => 12][$frequency];
            $target = $base->modify('first day of this month')->modify('+' . $months . ' months');
            $day = min((int) $base->format('d'), (int) $target->format('t'));
            return $target->setDate((int) $target->format('Y'), (int) $target->format('m'), $day)->format('Y-m-d');
        }
        $modifiers = ['daily' => '+1 day', 'weekly' => '+1 week', 'biweekly' => '+2 weeks'];
        return $base->modify($modifiers[$frequency] ?? '+1 day')->format('Y-m-d');
    }
}
