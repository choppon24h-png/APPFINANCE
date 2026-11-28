<?php
namespace App\Models;

use App\Core\Model;

class CostCenter extends Model
{
    protected string $table = 'cost_centers';

    public function forUser(int $userId, bool $activeOnly = false): array
    {
        $sql = 'SELECT * FROM cost_centers WHERE (user_id IS NULL OR user_id = :user_id)';
        if ($activeOnly) $sql .= " AND status = 'active'";
        $sql .= " ORDER BY (kind = 'property') DESC, name ASC";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute(['user_id' => $userId]);
        return $stmt->fetchAll();
    }

    public function findForUser(int $id, int $userId): ?object
    {
        $stmt = $this->pdo->prepare('SELECT * FROM cost_centers WHERE id = :id AND (user_id IS NULL OR user_id = :user_id) LIMIT 1');
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $center = $stmt->fetch();
        return $center ?: null;
    }

    public function create(int $userId, array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO cost_centers
                (user_id, name, kind, address, zip_code, street, address_number, complement,
                 neighborhood, city, state, identifiers, code, description, status)
             VALUES
                (:user_id, :name, :kind, :address, :zip_code, :street, :address_number, :complement,
                 :neighborhood, :city, :state, :identifiers, :code, :description, :status)'
        );
        $stmt->execute($this->params($userId, $data));
        return (int) $this->pdo->lastInsertId();
    }

    public function update(int $id, int $userId, array $data): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE cost_centers SET name = :name, kind = :kind, address = :address,
                zip_code = :zip_code, street = :street, address_number = :address_number,
                complement = :complement, neighborhood = :neighborhood, city = :city, state = :state,
                identifiers = :identifiers, code = :code, description = :description, status = :status
             WHERE id = :id AND user_id = :user_id'
        );
        $params = $this->params($userId, $data);
        $params['id'] = $id;
        return $stmt->execute($params);
    }

    private function params(int $userId, array $data): array
    {
        return [
            'user_id' => $userId,
            'name' => $data['name'],
            'kind' => $data['kind'] ?? 'general',
            'address' => $data['address'] ?? null,
            'zip_code' => $data['zip_code'] ?? null,
            'street' => $data['street'] ?? null,
            'address_number' => $data['address_number'] ?? null,
            'complement' => $data['complement'] ?? null,
            'neighborhood' => $data['neighborhood'] ?? null,
            'city' => $data['city'] ?? null,
            'state' => $data['state'] ?? null,
            'identifiers' => $data['identifiers'] ?? null,
            'code' => $data['code'] ?? null,
            'description' => $data['description'] ?? null,
            'status' => $data['status'] ?? 'active',
        ];
    }

    public function delete(int $id, int $userId): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM cost_centers WHERE id = :id AND user_id = :user_id');
        return $stmt->execute(['id' => $id, 'user_id' => $userId]);
    }

    /** Total de despesas do periodo por centro de custo (cartoes de imovel). */
    public function monthlyTotals(int $userId, string $from, string $to): array
    {
        $stmt = $this->pdo->prepare(
            "SELECT cost_center_id, COALESCE(SUM(amount), 0) AS total
             FROM transactions
             WHERE user_id = :u AND type = 'expense' AND status <> 'cancelled'
               AND cost_center_id IS NOT NULL AND transaction_date BETWEEN :i AND :f
             GROUP BY cost_center_id"
        );
        $stmt->execute(['u' => $userId, 'i' => $from, 'f' => $to]);
        $out = [];
        foreach ($stmt->fetchAll() as $row) {
            $out[(int) $row->cost_center_id] = (float) $row->total;
        }
        return $out;
    }

    /** Endereço completo montado a partir dos campos do CEP (usado no cartão). */
    public static function composeAddress(array $data): ?string
    {
        $rua = trim((string) ($data['street'] ?? ''));
        $numero = trim((string) ($data['address_number'] ?? ''));
        $complemento = trim((string) ($data['complement'] ?? ''));
        $bairro = trim((string) ($data['neighborhood'] ?? ''));
        $cidade = trim((string) ($data['city'] ?? ''));
        $uf = strtoupper(trim((string) ($data['state'] ?? '')));

        $linha1 = trim($rua . ($numero !== '' ? ', ' . $numero : '') . ($complemento !== '' ? ' - ' . $complemento : ''));
        $linha2 = trim($bairro . ($bairro !== '' && $cidade !== '' ? ', ' : '') . $cidade . ($uf !== '' ? '/' . $uf : ''));
        $endereco = trim($linha1 . ($linha1 !== '' && $linha2 !== '' ? ' — ' : '') . $linha2);
        return $endereco !== '' ? mb_substr($endereco, 0, 255) : null;
    }

    public function seedDefaults(int $userId): void
    {
        $defaults = [
            ['Pessoal', 'PES'], ['Casa', 'CAS'], ['Empresa', 'EMP'],
            ['Carro', 'CAR'], ['Operacional', 'OPE'],
        ];
        $check = $this->pdo->prepare('SELECT COUNT(*) FROM cost_centers WHERE user_id IS NULL OR user_id = :user_id');
        $check->execute(['user_id' => $userId]);
        if ((int) $check->fetchColumn() > 0) return;
        $stmt = $this->pdo->prepare(
            'INSERT INTO cost_centers (user_id, name, code, status) VALUES (:user_id, :name, :code, \'active\')'
        );
        foreach ($defaults as [$name, $code]) $stmt->execute(compact('userId', 'name', 'code'));
    }
}
