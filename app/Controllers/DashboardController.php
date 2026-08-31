<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Models\Account;
use App\Models\Category;
use App\Models\CostCenter;
use App\Models\Investment;
use App\Models\Transaction;
use DateTimeImmutable;

class DashboardController extends Controller
{
    public function index(): void
    {
        $user = Auth::user();
        $userId = (int) $user->id;
        (new Category())->seedDefaults($userId);
        (new CostCenter())->seedDefaults($userId);

        $months = (int) ($_GET['period'] ?? 12);
        if (!in_array($months, [6, 12, 24], true)) $months = 12;
        $current = new DateTimeImmutable('first day of this month');
        $fromDate = $current->modify('-' . ($months - 1) . ' months');
        $from = $fromDate->format('Y-m-d');
        $to = $current->modify('+1 month')->modify('-1 day')->format('Y-m-d');
        $today = (new DateTimeImmutable('today'))->format('Y-m-d');
        $nextMonth = (new DateTimeImmutable('today'))->modify('+30 days')->format('Y-m-d');

        $transactions = new Transaction();
        $investments = new Investment();
        $summary = $transactions->summary($userId, $from, $to);
        $investTotals = $investments->totals($userId);

        $this->view('dashboard/index', [
            'title' => 'Visão geral',
            'summary' => $summary,
            'investTotals' => $investTotals,
            'totalBalance' => (new Account())->totalBalance($userId),
            'evolution' => $transactions->monthlyEvolution($userId, $from, $to),
            'expenseRanking' => $transactions->ranking($userId, 'expense', $from, $to),
            'incomeRanking' => $transactions->ranking($userId, 'income', $from, $to),
            'bestInvestments' => $investments->ranked($userId, $_GET['investment_order'] ?? 'absolute'),
            'upcoming' => $transactions->upcoming($userId, $today, $nextMonth),
            'overdueCount' => $transactions->overdueCount($userId),
            'period' => $months,
            'monthLabel' => $current->format('m/Y'),
        ]);
    }
}
