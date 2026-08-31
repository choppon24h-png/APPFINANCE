<?php
namespace App\Support;

use InvalidArgumentException;

final class FinanceInput
{
    public static function text(mixed $value, string $field, int $max = 180, bool $required = true): ?string
    {
        $value = trim((string) ($value ?? ''));
        if ($value === '') {
            if ($required) {
                throw new InvalidArgumentException("Informe {$field}.");
            }
            return null;
        }
        if (mb_strlen($value) > $max) {
            throw new InvalidArgumentException("{$field} deve ter no máximo {$max} caracteres.");
        }
        return $value;
    }

    public static function amount(mixed $value, string $field = 'Valor'): float
    {
        $raw = trim((string) ($value ?? ''));
        $raw = str_replace(['R$', ' '], '', $raw);
        if (str_contains($raw, ',') && str_contains($raw, '.')) {
            $raw = str_replace('.', '', $raw);
            $raw = str_replace(',', '.', $raw);
        } else {
            $raw = str_replace(',', '.', $raw);
        }
        if ($raw === '' || !is_numeric($raw)) {
            throw new InvalidArgumentException("Informe um {$field} válido.");
        }
        $amount = round((float) $raw, 2);
        if ($amount <= 0 || $amount > 999999999999.99) {
            throw new InvalidArgumentException("{$field} deve ser maior que zero.");
        }
        return $amount;
    }

    public static function nonNegativeAmount(mixed $value, string $field = 'Valor'): float
    {
        $raw = trim((string) ($value ?? ''));
        if ($raw === '') return 0.0;
        $raw = str_replace(['R$', ' '], '', $raw);
        if (str_contains($raw, ',') && str_contains($raw, '.')) {
            $raw = str_replace('.', '', $raw);
            $raw = str_replace(',', '.', $raw);
        } else {
            $raw = str_replace(',', '.', $raw);
        }
        if (!is_numeric($raw) || (float) $raw < 0 || (float) $raw > 999999999999.99) {
            throw new InvalidArgumentException("{$field} deve ser zero ou maior.");
        }
        return round((float) $raw, 2);
    }

    public static function date(mixed $value, string $field, bool $required = true): ?string
    {
        $raw = trim((string) ($value ?? ''));
        if ($raw === '') {
            if ($required) {
                throw new InvalidArgumentException("Informe {$field}.");
            }
            return null;
        }
        $date = \DateTimeImmutable::createFromFormat('!Y-m-d', $raw);
        if (!$date || $date->format('Y-m-d') !== $raw) {
            throw new InvalidArgumentException("{$field} inválida.");
        }
        return $raw;
    }

    public static function intId(mixed $value, string $field, bool $required = false): ?int
    {
        if ($value === null || $value === '') {
            if ($required) {
                throw new InvalidArgumentException("Informe {$field}.");
            }
            return null;
        }
        $id = filter_var($value, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
        if ($id === false) {
            throw new InvalidArgumentException("{$field} inválido.");
        }
        return (int) $id;
    }

    public static function enum(mixed $value, string $field, array $allowed, string $default): string
    {
        $value = (string) ($value ?? $default);
        if (!in_array($value, $allowed, true)) {
            throw new InvalidArgumentException("{$field} inválido.");
        }
        return $value;
    }

    public static function nullableEnum(mixed $value, string $field, array $allowed): ?string
    {
        $value = trim((string) ($value ?? ''));
        if ($value === '') return null;
        return self::enum($value, $field, $allowed, $allowed[0]);
    }
}
