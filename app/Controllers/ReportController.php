<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Models\Account;
use App\Models\Category;
use App\Models\CostCenter;
use App\Models\Transaction;
use DateTimeImmutable;

class ReportController extends Controller
{
    private function userId(): int { return (int) Auth::user()->id; }

    public function index(): void
    {
        $filters = $this->filters();
        $model = new Transaction();
        $summary = $model->summary($this->userId(), $filters['date_from'], $filters['date_to']);
        $this->view('reports/index', [
            'title' => 'Relatórios', 'filters' => $filters, 'summary' => $summary,
            'transactions' => $model->paginateForUser($this->userId(), $filters, 1, 100),
            'expenseRanking' => $model->ranking($this->userId(), 'expense', $filters['date_from'], $filters['date_to'], 10),
            'incomeRanking' => $model->ranking($this->userId(), 'income', $filters['date_from'], $filters['date_to'], 10),
            'accounts' => (new Account())->forUser($this->userId()),
            'categories' => (new Category())->forUser($this->userId()),
            'costCenters' => (new CostCenter())->forUser($this->userId()),
        ]);
    }

    public function csv(): void
    {
        $filters = $this->filters();
        $items = (new Transaction())->allForUser($this->userId(), $filters);
        $filename = 'appfinance-relatorio-' . date('Y-m-d') . '.csv';
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="' . $filename . '"');
        $out = fopen('php://output', 'w');
        fprintf($out, "\xEF\xBB\xBF");
        fputcsv($out, ['Data', 'Descrição', 'Tipo', 'Categoria', 'Centro de custo', 'Conta', 'Valor', 'Status'], ';');
        foreach ($items as $item) fputcsv($out, [date('d/m/Y', strtotime($item->transaction_date)), $item->description, $item->type, $item->category_name ?? '', $item->cost_center_name ?? '', $item->account_name, number_format((float) $item->amount, 2, ',', '.'), $item->status], ';');
        fclose($out); exit;
    }

    private function filters(): array
    {
        $current = new DateTimeImmutable('first day of this month');
        $from = (string) ($_GET['date_from'] ?? $current->format('Y-m-d'));
        $to = (string) ($_GET['date_to'] ?? $current->modify('+1 month')->modify('-1 day')->format('Y-m-d'));
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $from)) $from = $current->format('Y-m-d');
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $to)) $to = $current->modify('+1 month')->modify('-1 day')->format('Y-m-d');
        $filters = ['date_from' => $from, 'date_to' => $to];
        foreach (['type','status','search'] as $key) if (!empty($_GET[$key])) $filters[$key] = trim((string) $_GET[$key]);
        foreach (['account_id','category_id','cost_center_id'] as $key) if (!empty($_GET[$key]) && ctype_digit((string) $_GET[$key])) $filters[$key] = (int) $_GET[$key];
        return $filters;
    }
}
