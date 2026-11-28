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

echo "== Smoke test =="
php tests/SmokeTest.php | tail -2
