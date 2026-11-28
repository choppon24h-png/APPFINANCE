<?php
namespace App\Controllers;

use App\Core\Auth;
use App\Core\Audit\AuditLogger;
use App\Core\Controller;
use App\Models\Category;
use App\Models\CostCenter;
use App\Services\CepService;
use App\Support\FinanceInput;
use Throwable;

class CatalogController extends Controller
{
    private function userId(): int { return (int) Auth::user()->id; }

    public function categories(): void
    {
        $model = new Category();
        $edit = !empty($_GET['edit']) && ctype_digit((string) $_GET['edit']) ? $model->findForUser((int) $_GET['edit'], $this->userId()) : null;
        $this->view('catalog/categories', ['title' => 'Categorias', 'categories' => $model->forUser($this->userId()), 'editCategory' => $edit]);
    }

    public function categoryStore(): void
    {
        try {
            $data = $this->categoryInput($_POST);
            $id = (new Category())->create($this->userId(), $data);
            AuditLogger::log('create', 'category', $id);
            $this->flash('success', 'Categoria criada.');
        } catch (Throwable $e) { $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível criar a categoria.'); }
        $this->redirect('/categorias');
    }

    public function categoryUpdate(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Categoria', true);
            $data = $this->categoryInput($_POST);
            if (!(new Category())->update($id, $this->userId(), $data)) throw new \RuntimeException();
            AuditLogger::log('update', 'category', $id);
            $this->flash('success', 'Categoria atualizada.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível atualizar a categoria.'); }
        $this->redirect('/categorias');
    }

    public function categoryToggle(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Categoria', true); $model = new Category(); $category = $model->findForUser($id, $this->userId());
            if (!$category || $category->user_id === null) throw new \InvalidArgumentException();
            $model->update($id, $this->userId(), ['name' => $category->name, 'type' => $category->type, 'icon' => $category->icon, 'color' => $category->color, 'parent_id' => $category->parent_id, 'status' => $category->status === 'active' ? 'inactive' : 'active']);
            AuditLogger::log('status', 'category', $id);
            $this->flash('success', 'Status da categoria atualizado.');
        } catch (Throwable $e) { $this->flash('error', 'Categorias padrão não podem ser alteradas.'); }
        $this->redirect('/categorias');
    }

    public function categoryDelete(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Categoria', true); $model = new Category(); $category = $model->findForUser($id, $this->userId());
            if (!$category || $category->user_id === null || !$model->delete($id, $this->userId())) throw new \RuntimeException();
            AuditLogger::log('delete', 'category', $id); $this->flash('success', 'Categoria removida.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível remover a categoria.'); }
        $this->redirect('/categorias');
    }

    public function costCenters(): void
    {
        $model = new CostCenter();
        $edit = !empty($_GET['edit']) && ctype_digit((string) $_GET['edit']) ? $model->findForUser((int) $_GET['edit'], $this->userId()) : null;
        $tipo = in_array($_GET['tipo'] ?? '', ['general', 'property', 'vehicle', 'company', 'project'], true) ? $_GET['tipo'] : '';
        $todos = $model->forUser($this->userId());
        $centros = $tipo === '' ? $todos : array_values(array_filter($todos, static fn($c) => ($c->kind ?? 'general') === $tipo));
        $this->view('catalog/cost_centers', [
            'title' => 'Imóveis e centros de custo',
            'costCenters' => $centros,
            'allCostCenters' => $todos,
            'tipo' => $tipo,
            'editCenter' => $edit,
            'totais' => $model->monthlyTotals($this->userId(), date('Y-m-01'), date('Y-m-t')),
            'mesReferencia' => date('m/Y'),
        ]);
    }

    public function costCenterStore(): void
    {
        try {
            $data = $this->costCenterInput($_POST); $id = (new CostCenter())->create($this->userId(), $data);
            AuditLogger::log('create', 'cost_center', $id, ['kind' => $data['kind']]);
            $this->flash('success', $data['kind'] === 'property' ? 'Imóvel cadastrado.' : 'Centro de custo criado.');
        } catch (Throwable $e) { $this->flash('error', $e instanceof \InvalidArgumentException ? $e->getMessage() : 'Não foi possível criar o centro de custo.'); }
        $this->redirect('/centros-custo');
    }

    public function costCenterUpdate(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Centro de custo', true);
            $model = new CostCenter();
            $atual = $model->findForUser($id, $this->userId());
            if (!$atual) throw new \RuntimeException();
            $data = $this->costCenterInput($_POST);
            // Preserva status/kind/endereco/identificadores quando o formulario
            // de edicao nao os envia (ex.: edicao rapida pelo cartao).
            if (empty($_POST['status'])) $data['status'] = $atual->status;
            if (empty($_POST['kind'])) $data['kind'] = $atual->kind ?? 'general';
            if (empty($_POST['identifiers'])) $data['identifiers'] = $atual->identifiers ?? null;
            if (empty($_POST['zip_code']) && empty($_POST['street']) && empty($_POST['address'])) {
                foreach (['address', 'zip_code', 'street', 'address_number', 'complement', 'neighborhood', 'city', 'state'] as $campo) {
                    $data[$campo] = $atual->$campo ?? null;
                }
            }
            if (!$model->update($id, $this->userId(), $data)) throw new \RuntimeException();
            AuditLogger::log('update', 'cost_center', $id); $this->flash('success', 'Centro de custo atualizado.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível atualizar o centro de custo.'); }
        $this->redirect('/centros-custo');
    }

    public function costCenterToggle(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Centro de custo', true); $model = new CostCenter(); $center = $model->findForUser($id, $this->userId());
            if (!$center || $center->user_id === null) throw new \InvalidArgumentException();
            $model->update($id, $this->userId(), [
                'name' => $center->name, 'code' => $center->code, 'description' => $center->description,
                'kind' => $center->kind ?? 'general', 'address' => $center->address ?? null,
                'zip_code' => $center->zip_code ?? null, 'street' => $center->street ?? null,
                'address_number' => $center->address_number ?? null, 'complement' => $center->complement ?? null,
                'neighborhood' => $center->neighborhood ?? null, 'city' => $center->city ?? null,
                'state' => $center->state ?? null,
                'identifiers' => $center->identifiers ?? null,
                'status' => $center->status === 'active' ? 'inactive' : 'active',
            ]);
            AuditLogger::log('status', 'cost_center', $id); $this->flash('success', 'Status atualizado.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível atualizar o centro de custo.'); }
        $this->redirect('/centros-custo');
    }

    public function costCenterDelete(string $id): void
    {
        try {
            $id = FinanceInput::intId($id, 'Centro de custo', true); $model = new CostCenter(); $center = $model->findForUser($id, $this->userId());
            if (!$center || $center->user_id === null || !$model->delete($id, $this->userId())) throw new \RuntimeException();
            AuditLogger::log('delete', 'cost_center', $id); $this->flash('success', 'Centro de custo removido.');
        } catch (Throwable $e) { $this->flash('error', 'Não foi possível remover o centro de custo.'); }
        $this->redirect('/centros-custo');
    }

    private function categoryInput(array $input): array
    {
        return [
            'name' => FinanceInput::text($input['name'] ?? null, 'Nome', 120),
            'type' => FinanceInput::enum($input['type'] ?? null, 'Tipo', ['income','expense'], 'expense'),
            'icon' => FinanceInput::text($input['icon'] ?? 'tag', 'Ícone', 40, false) ?: 'tag',
            'color' => FinanceInput::text($input['color'] ?? '#2563eb', 'Cor', 20, false) ?: '#2563eb',
            'parent_id' => FinanceInput::intId($input['parent_id'] ?? null, 'Categoria pai'),
            'status' => FinanceInput::enum($input['status'] ?? 'active', 'Status', ['active','inactive'], 'active'),
        ];
    }

    private function costCenterInput(array $input): array
    {
        $kind = FinanceInput::enum($input['kind'] ?? 'general', 'Tipo', ['general','property','vehicle','company','project'], 'general');
        $comEndereco = in_array($kind, ['property', 'company'], true);
        $cep = CepService::normalize($input['zip_code'] ?? null);
        $endereco = [
            'zip_code' => $cep ? CepService::format($cep) : null,
            'street' => $comEndereco ? FinanceInput::text($input['street'] ?? null, 'Rua', 160, false) : null,
            'address_number' => $comEndereco ? FinanceInput::text($input['address_number'] ?? null, 'Número', 20, false) : null,
            'complement' => $comEndereco ? FinanceInput::text($input['complement'] ?? null, 'Complemento', 80, false) : null,
            'neighborhood' => $comEndereco ? FinanceInput::text($input['neighborhood'] ?? null, 'Bairro', 80, false) : null,
            'city' => $comEndereco ? FinanceInput::text($input['city'] ?? null, 'Cidade', 80, false) : null,
            'state' => $comEndereco ? strtoupper((string) FinanceInput::text($input['state'] ?? null, 'UF', 2, false)) : null,
        ];
        $address = $comEndereco ? CostCenter::composeAddress($endereco) : null;
        if ($address === null) {
            $address = FinanceInput::text($input['address'] ?? null, 'Endereço', 255, false);
        }
        return $endereco + [
            'name' => FinanceInput::text($input['name'] ?? null, 'Nome', 120),
            'kind' => $kind,
            'address' => $address,
            'identifiers' => $comEndereco ? FinanceInput::text($input['identifiers'] ?? null, 'Identificadores', 500, false) : null,
            'code' => FinanceInput::text($input['code'] ?? null, 'Código', 40, false),
            'description' => FinanceInput::text($input['description'] ?? null, 'Descrição', 255, false),
            'status' => FinanceInput::enum($input['status'] ?? 'active', 'Status', ['active','inactive'], 'active'),
        ];
    }

    private function flash(string $type, string $message): void { $_SESSION['flash'] = ['type' => $type, 'message' => $message]; }
}
