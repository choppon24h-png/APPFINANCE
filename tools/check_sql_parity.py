#!/usr/bin/env python3
"""Confere se a versao PostgreSQL esta em dia com o SQL MySQL.

Regra do projeto: toda alteracao em database/migrations/*.sql ou
database/seeds/*.sql precisa ser acompanhada da versao em
database/postgresql/*.pg.sql. Este verificador falha (exit 1) quando:

  * falta o arquivo .pg.sql correspondente;
  * o arquivo .pg.sql foi gerado a partir de outra versao do MySQL
    (sha256 diferente, gravado no cabecalho do arquivo gerado).

Uso:
    python3 tools/check_sql_parity.py
    python3 tools/check_sql_parity.py --corrigir   # roda o gerador e revalida
"""
from __future__ import annotations

import argparse
import hashlib
import pathlib
import re
import subprocess
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
MYSQL = RAIZ / "database"
PG = MYSQL / "postgresql"


def sha256(caminho: pathlib.Path) -> str:
    return hashlib.sha256(caminho.read_bytes()).hexdigest()[:16]


def origens() -> list[pathlib.Path]:
    return sorted((MYSQL / "migrations").glob("*.sql")) + sorted((MYSQL / "seeds").glob("*.sql"))


def conferir() -> list[str]:
    problemas: list[str] = []
    if not PG.is_dir():
        return ["a pasta database/postgresql/ nao existe"]

    for origem in origens():
        destino = PG / (origem.stem + ".pg.sql")
        relativo = origem.relative_to(RAIZ).as_posix()
        if not destino.is_file():
            problemas.append(f"falta {destino.relative_to(RAIZ).as_posix()} (origem {relativo})")
            continue
        cabecalho = destino.read_text(encoding="utf-8").splitlines()[:8]
        texto = "\n".join(cabecalho)
        achado = re.search(r"sha256:\s*([0-9a-f]{16})", texto)
        if not achado:
            problemas.append(f"{destino.name}: cabecalho sem sha256 (gere novamente)")
        elif achado.group(1) != sha256(origem):
            problemas.append(
                f"{destino.name}: desatualizado — {relativo} mudou depois da geracao"
            )

    for obrigatorio in ("somase_instalacao_completa.pg.sql", "somase_atualizar_banco.pg.sql"):
        if not (PG / obrigatorio).is_file():
            problemas.append(f"falta database/postgresql/{obrigatorio}")

    return problemas


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--corrigir", action="store_true", help="regenera antes de conferir")
    args = ap.parse_args()

    if args.corrigir:
        subprocess.run([sys.executable, str(RAIZ / "tools" / "build_postgres_sql.py")], check=True)

    problemas = conferir()
    if problemas:
        print("PostgreSQL DESATUALIZADO:")
        for problema in problemas:
            print("  - " + problema)
        print("\nRode: python3 tools/build_postgres_sql.py && python3 tools/build_postgres_sql.py --validar")
        return 1

    print(f"OK: {len(origens())} arquivos MySQL com versao PostgreSQL em dia.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
