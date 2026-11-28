#!/usr/bin/env bash
# Validacao rapida antes de commitar: PHP, JS e paridade MySQL/PostgreSQL.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== PHP =="
find app public tests routes -name '*.php' -print0 | xargs -0 -n1 php -l > /dev/null
echo "ok"

echo "== JavaScript =="
for arquivo in public/assets/js/*.js public/sw.js; do node --check "$arquivo"; done
echo "ok"

echo "== SQL MySQL -> PostgreSQL =="
python3 tools/check_sql_parity.py

echo "== Pacote MySQL unico (nao pode apagar dados) =="
if grep -qiE '^[[:space:]]*(DROP[[:space:]]+TABLE|TRUNCATE|DELETE[[:space:]]+FROM)' database/sql/somase_mysql_unico.sql; then
    echo "FALHA: somase_mysql_unico.sql contem DROP/TRUNCATE/DELETE" >&2
    exit 1
fi
if ! grep -q "CREATE TABLE IF NOT EXISTS" database/sql/somase_mysql_unico.sql; then
    echo "FALHA: somase_mysql_unico.sql nao usa CREATE TABLE IF NOT EXISTS" >&2
    exit 1
fi
echo "ok"

echo "== Smoke test =="
php tests/SmokeTest.php | tail -2
