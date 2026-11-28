<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Audit\AuditLogger;
use App\Core\Controller;
use App\Models\InvestmentType;
use App\Support\FinanceInput;
use App\Support\Slug;
use Throwable;

class InvestmentTypeController extends Controller
{
    private function userId(): int { return (int) Auth::user()->id; }

    public function index(): void
    {
        $model = new InvestmentType();
        $edit = !empty($_GET['edit']) && ctype_digit((string) $_GET['edit'])
            ? $model->findForUser((int) $_GET['edit'], $this->userId())
            : null;
        $this->view('investments/types', [
            'title' => 'Tipos de investimento',
            'types' => $model->forUser($this->userId()),
            'editType' => $edit,
            'benchmarks' => InvestmentType::BENCHMARKS,
            'referenceRates' => InvestmentType::REFERENCE_RATES,
        ]);
    }

    public function store(): void
    {
        try {
            $id = (new InvestmentType())->create($this->userId(), $this->input($_POST));
            AuditLogger::log('create', 'investment_type', $id);
            $this->flash('success', 'Tipo de investimento criado.');
        } catch (Throwable $e) {
            $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível criar o tipo de investimento.');
        }
        $this->redirect('/investimentos/tipos');
    }

    public function update(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Tipo de investimento', true);
            $model = new InvestmentType();
            if (!$model->findForUser($id, $this->userId())) throw new \RuntimeException();
            $model->update($id, $this->userId(), $this->input($_POST, $id));
            AuditLogger::log('update', 'investment_type', $id);
            $this->flash('success', 'Tipo de investimento atualizado.');
        } catch (Throwable $e) {
            $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível atualizar o tipo de investimento.');
        }
        $this->redirect('/investimentos/tipos');
    }

    public function toggle(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Tipo de investimento', true);
            $model = new InvestmentType();
            $type = $model->findForUser($id, $this->userId());
            if (!$type) throw new \RuntimeException();
            $model->update($id, $this->userId(), [
                'name' => $type->name, 'slug' => $type->slug, 'benchmark' => $type->benchmark,
                'default_rate' => $type->default_rate, 'default_rate_period' => $type->default_rate_period,
                'status' => $type->status === 'active' ? 'inactive' : 'active',
            ]);
            AuditLogger::log('status', 'investment_type', $id);
            $this->flash('success', 'Status atualizado.');
        } catch (Throwable $e) {
            $this->flash('error', 'Não foi possível atualizar o status.');
        }
        $this->redirect('/investimentos/tipos');
    }

    public function destroy(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Tipo de investimento', true);
            if (!(new InvestmentType())->delete($id, $this->userId())) throw new \RuntimeException();
            AuditLogger::log('delete', 'investment_type', $id);
            $this->flash('success', 'Tipo de investimento removido.');
        } catch (Throwable $e) {
            $this->flash('error', 'Não foi possível remover o tipo (ele pode estar em uso).');
        }
        $this->redirect('/investimentos/tipos');
    }

    private function input(array $input, ?int $ignorarId = null): array
    {
        $nome = FinanceInput::text($input['name'] ?? null, 'Nome', 80);
        $model = new InvestmentType();
        $existentes = $model->slugsForUser($this->userId());
        $atual = $ignorarId ? $model->findForUser($ignorarId, $this->userId()) : null;
        if ($atual) $existentes = array_values(array_diff($existentes, [$atual->slug]));
        $slugInformado = trim((string) ($input['slug'] ?? ''));
        $slug = $slugInformado !== '' ? Slug::make($slugInformado) : Slug::make($nome);
        if ($atual && $slugInformado === '') $slug = $atual->slug;
        $slug = Slug::unique($slug, $existentes);

        return [
            'name' => trim($nome),
            'slug' => $slug,
            'benchmark' => FinanceInput::enum($input['benchmark'] ?? 'none', 'Índice', array_keys(InvestmentType::BENCHMARKS), 'none'),
            'default_rate' => $this->nullableDecimal($input['default_rate'] ?? null),
            'default_rate_period' => FinanceInput::enum($input['default_rate_period'] ?? 'annual', 'Periodicidade', ['annual', 'monthly'], 'annual'),
            'status' => FinanceInput::enum($input['status'] ?? 'active', 'Status', ['active', 'inactive'], 'active'),
        ];
    }

    private function nullableDecimal(mixed $value): ?float
    {
        $raw = trim((string) ($value ?? ''));
        if ($raw === '') return null;
        $raw = str_replace(',', '.', $raw);
        if (!is_numeric($raw)) throw new \InvalidArgumentException('Taxa inválida.');
        return round((float) $raw, 6);
    }

    private function flash(string $type, string $message): void { $_SESSION['flash'] = ['type' => $type, 'message' => $message]; }
}
