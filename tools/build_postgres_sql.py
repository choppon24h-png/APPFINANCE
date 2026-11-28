#!/usr/bin/env python3
"""Converte o SQL MySQL do SOMASE para PostgreSQL.

POR QUE ESTA PASTA EXISTE
-------------------------
Toda alteracao de banco entra primeiro em database/migrations/*.sql (MySQL,
usado em producao na HostGator). Este script gera a mesma estrutura em
PostgreSQL dentro de database/postgresql/, para que uma migracao futura de
banco nao exija reescrever o DDL na mao.

REGRA OBRIGATORIA
-----------------
Nunca edite database/postgresql/*.pg.sql manualmente: rode

    python3 tools/build_postgres_sql.py

E valide com

    python3 tools/check_sql_parity.py     # falha se o PG estiver atrasado

Uso:
    python3 tools/build_postgres_sql.py            # gera todos os arquivos
    python3 tools/build_postgres_sql.py --validar  # gera e testa no PostgreSQL
"""
from __future__ import annotations

import argparse
import hashlib
import pathlib
import re
import subprocess
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
ORIGEM_MIGRATIONS = RAIZ / "database" / "migrations"
ORIGEM_SEEDS = RAIZ / "database" / "seeds"
DESTINO = RAIZ / "database" / "postgresql"

TIPOS = [
    (r"bigint", "bigint"),
    (r"int", "integer"),
    (r"smallint", "smallint"),
    (r"tinyint", "smallint"),          # flags 0/1 continuam aceitando inteiros
    (r"mediumint", "integer"),
    (r"decimal", "numeric"),
    (r"numeric", "numeric"),
    (r"double", "double precision"),
    (r"float", "real"),
    (r"varchar", "varchar"),
    (r"char", "char"),
    (r"longtext", "text"),
    (r"mediumtext", "text"),
    (r"tinytext", "text"),
    (r"text", "text"),
    (r"json", "jsonb"),
    (r"datetime", "timestamp"),
    (r"timestamp", "timestamp"),
    (r"date", "date"),
    (r"time", "time"),
    (r"blob", "bytea"),
    (r"longblob", "bytea"),
    (r"binary", "bytea"),
    (r"varbinary", "bytea"),
    (r"bit", "smallint"),
]


# --------------------------------------------------------------------------
# utilidades de texto
# --------------------------------------------------------------------------
def dividir_statements(sql: str) -> list[str]:
    """Divide o arquivo em comandos, respeitando aspas e comentarios."""
    comandos: list[str] = []
    atual: list[str] = []
    i = 0
    n = len(sql)
    aspas: str | None = None
    while i < n:
        c = sql[i]
        if aspas:
            atual.append(c)
            if c == "\\" and aspas in ("'", '"') and i + 1 < n:
                atual.append(sql[i + 1])
                i += 2
                continue
            if c == aspas:
                aspas = None
            i += 1
            continue
        if c in ("'", '"', "`"):
            aspas = c
            atual.append(c)
            i += 1
            continue
        if c == "-" and sql.startswith("--", i):
            fim = sql.find("\n", i)
            fim = n if fim == -1 else fim
            i = fim
            continue
        if c == "#":
            fim = sql.find("\n", i)
            fim = n if fim == -1 else fim
            i = fim
            continue
        if c == "/" and sql.startswith("/*", i):
            fim = sql.find("*/", i + 2)
            i = n if fim == -1 else fim + 2
            continue
        if c == ";":
            comandos.append("".join(atual).strip())
            atual = []
            i += 1
            continue
        atual.append(c)
        i += 1
    resto = "".join(atual).strip()
    if resto:
        comandos.append(resto)
    return [c for c in comandos if c]


def converter_literais(texto: str) -> str:
    """Troca escapes do MySQL (\\' \\\\ \\") pelos do PostgreSQL."""
    saida: list[str] = []
    i = 0
    n = len(texto)
    dentro: str | None = None
    while i < n:
        c = texto[i]
        if dentro:
            if c == "\\" and i + 1 < n:
                proximo = texto[i + 1]
                if proximo == "'":
                    saida.append("''")
                elif proximo == '"':
                    saida.append('"')
                elif proximo == "\\":
                    saida.append("\\")
                elif proximo == "n":
                    saida.append("\n")
                elif proximo == "r":
                    saida.append("\r")
                elif proximo == "t":
                    saida.append("\t")
                elif proximo == "0":
                    saida.append("")
                else:
                    saida.append(proximo)
                i += 2
                continue
            if c == dentro:
                dentro = None
            saida.append(c)
            i += 1
            continue
        if c in ("'", '"'):
            dentro = c
            saida.append(c)
            i += 1
            continue
        if c == "`":
            # identificador: vira "nome"
            fim = texto.find("`", i + 1)
            if fim == -1:
                saida.append(c)
                i += 1
                continue
            saida.append('"' + texto[i + 1:fim].lower() + '"')
            i = fim + 1
            continue
        saida.append(c)
        i += 1
    return "".join(saida)


def identificar(sql: str) -> str:
    """Troca `col` por "col" em comandos sem literais problematicos."""
    return re.sub(r"`([A-Za-z0-9_]+)`", lambda m: '"' + m.group(1).lower() + '"', sql)


def sem_comentarios_de_linha(sql: str) -> str:
    linhas = []
    for linha in sql.splitlines():
        if linha.lstrip().startswith("--"):
            continue
        linhas.append(linha)
    return "\n".join(linhas)


def tipo_pg(tipo_mysql: str) -> tuple[str, str | None]:
    """Devolve (tipo PostgreSQL, check opcional) para um tipo MySQL."""
    tipo = tipo_mysql.strip().lower()
    tipo = re.sub(r"\s+unsigned\b", "", tipo)
    tipo = re.sub(r"\s+zerofill\b", "", tipo)
    tipo = re.sub(r"\s+collate \w+", "", tipo)

    enum = re.match(r"enum\s*\((.*)\)$", tipo, re.S)
    if enum:
        valores = re.findall(r"'((?:[^'\\]|\\.)*)'", enum.group(1))
        tamanho = max([len(v) for v in valores] + [10])
        lista = ", ".join("'" + v.replace("'", "''") + "'" for v in valores)
        return f"varchar({max(tamanho, 12)})", f"IN ({lista})"

    conjunto = re.match(r"set\s*\((.*)\)$", tipo, re.S)
    if conjunto:
        valores = re.findall(r"'((?:[^'\\]|\\.)*)'", conjunto.group(1))
        tamanho = max([len(v) for v in valores] + [10])
        lista = ", ".join("'" + v.replace("'", "''") + "'" for v in valores)
        return f"varchar({max(tamanho, 20)})", f"IN ({lista})"

    for prefixo, destino in TIPOS:
        if tipo.startswith(prefixo):
            resto = tipo[len(prefixo):]
            if destino in ("varchar", "char", "numeric", "decimal") and resto.startswith("("):
                return destino + resto, None
            if destino == "numeric" and not resto.startswith("("):
                return "numeric", None
            return destino, None
    return tipo, None


# --------------------------------------------------------------------------
# conversao de CREATE TABLE
# --------------------------------------------------------------------------
def dividir_definicoes(corpo: str) -> list[str]:
    partes: list[str] = []
    atual: list[str] = []
    nivel = 0
    aspas: str | None = None
    i = 0
    while i < len(corpo):
        c = corpo[i]
        if aspas:
            atual.append(c)
            if c == aspas:
                aspas = None
            i += 1
            continue
        if c in ("'", '"', "`"):
            aspas = c
            atual.append(c)
            i += 1
            continue
        if c == "(":
            nivel += 1
        elif c == ")":
            nivel -= 1
        if c == "," and nivel == 0:
            partes.append("".join(atual).strip())
            atual = []
            i += 1
            continue
        atual.append(c)
        i += 1
    if "".join(atual).strip():
        partes.append("".join(atual).strip())
    return partes


def converter_create_table(nome: str, corpo: str) -> tuple[str, list[str], list[tuple[str, list[str]]]]:
    """Devolve (DDL da tabela, indices avulsos, colunas unicas)."""
    colunas: list[str] = []
    restricoes: list[str] = []
    indices: list[str] = []
    unicos: list[tuple[str, list[str]]] = []
    triggers_updated: list[str] = []

    for definicao in dividir_definicoes(corpo):
        baixo = definicao.lower()

        if baixo.startswith("primary key"):
            cols = re.findall(r"`([A-Za-z0-9_]+)`", definicao)
            restricoes.append('PRIMARY KEY (' + ", ".join(f'"{c.lower()}"' for c in cols) + ')')
            unicos.append((nome, [c.lower() for c in cols]))
            continue

        m = re.match(r"unique\s+(?:key|index)\s+`([A-Za-z0-9_]+)`\s*\((.*)\)", definicao, re.I | re.S)
        if m:
            cols = [c.lower() for c in re.findall(r"`([A-Za-z0-9_]+)`", m.group(2))]
            restricoes.append(f'CONSTRAINT "{m.group(1).lower()}" UNIQUE (' + ", ".join(f'"{c}"' for c in cols) + ')')
            unicos.append((nome, cols))
            continue

        m = re.match(r"(?:fulltext\s+)?(?:key|index)\s+`([A-Za-z0-9_]+)`\s*\((.*)\)", definicao, re.I | re.S)
        if m:
            cols = [c.lower() for c in re.findall(r"`([A-Za-z0-9_]+)`", m.group(2))]
            indices.append(
                f'CREATE INDEX IF NOT EXISTS "{m.group(1).lower()}" ON "{nome}" ('
                + ", ".join(f'"{c}"' for c in cols) + ");"
            )
            continue

        m = re.match(r"constraint\s+`([A-Za-z0-9_]+)`\s+foreign key\s*\((.*?)\)\s*references\s+`([A-Za-z0-9_]+)`\s*\((.*?)\)(.*)$",
                     definicao, re.I | re.S)
        if m:
            cols = ", ".join(f'"{c.lower()}"' for c in re.findall(r"`([A-Za-z0-9_]+)`", m.group(2)))
            ref = ", ".join(f'"{c.lower()}"' for c in re.findall(r"`([A-Za-z0-9_]+)`", m.group(4)))
            extra = m.group(5).upper()
            acao = ""
            if "CASCADE" in extra:
                acao = " ON DELETE CASCADE"
            elif "SET NULL" in extra:
                acao = " ON DELETE SET NULL"
            elif "RESTRICT" in extra:
                acao = " ON DELETE RESTRICT"
            restricoes.append(
                f'CONSTRAINT "{m.group(1).lower()}" FOREIGN KEY ({cols}) REFERENCES "{m.group(3).lower()}" ({ref}){acao}'
            )
            continue

        if baixo.startswith("foreign key"):
            cols = ", ".join(f'"{c.lower()}"' for c in re.findall(r"`([A-Za-z0-9_]+)`", definicao.split("references")[0]))
            alvo = re.search(r"references\s+`([A-Za-z0-9_]+)`\s*\((.*?)\)", definicao, re.I | re.S)
            if alvo:
                ref = ", ".join(f'"{c.lower()}"' for c in re.findall(r"`([A-Za-z0-9_]+)`", alvo.group(2)))
                acao = " ON DELETE CASCADE" if "cascade" in baixo else ""
                restricoes.append(f'FOREIGN KEY ({cols}) REFERENCES "{alvo.group(1).lower()}" ({ref}){acao}')
            continue

        if baixo.startswith("check"):
            restricoes.append(identificar(definicao))
            continue

        # coluna
        m = re.match(r"`([A-Za-z0-9_]+)`\s+(.*)$", definicao, re.S)
        if not m:
            continue
        coluna = m.group(1).lower()
        resto = m.group(2)

        resto_sem_comment = re.sub(r"comment\s+'(?:[^'\\]|\\.)*'", "", resto, flags=re.I | re.S)
        resto_sem_comment = re.sub(r"comment\s+\"(?:[^\"\\]|\\.)*\"", "", resto_sem_comment, flags=re.I | re.S)
        resto_sem_comment = re.sub(r"\s+after\s+`[A-Za-z0-9_]+`", "", resto_sem_comment, flags=re.I)
        resto_sem_comment = re.sub(r"\s+first\b", "", resto_sem_comment, flags=re.I)

        auto_increment = bool(re.search(r"auto_increment", resto_sem_comment, re.I))
        on_update = bool(re.search(r"on\s+update\s+current_timestamp", resto_sem_comment, re.I))
        resto_sem_comment = re.sub(r"auto_increment", "", resto_sem_comment, flags=re.I)
        resto_sem_comment = re.sub(r"on\s+update\s+current_timestamp(\(\d*\))?", "", resto_sem_comment, flags=re.I)
        resto_sem_comment = resto_sem_comment.strip().rstrip(",").strip()

        m_tipo = re.match(r"([a-zA-Z]+(?:\s*\([^)]*\))?(?:\s+unsigned)?(?:\s+zerofill)?)", resto_sem_comment)
        tipo_mysql = m_tipo.group(1) if m_tipo else "text"
        atributos = resto_sem_comment[len(tipo_mysql):].strip() if m_tipo else ""
        tipo, check = tipo_pg(tipo_mysql)

        nao_nulo = bool(re.search(r"\bnot\s+null\b", atributos, re.I))
        atributos = re.sub(r"\bnot\s+null\b", "", atributos, flags=re.I)
        atributos = re.sub(r"\bunsigned\b", "", atributos, flags=re.I)
        atributos = re.sub(r"\bzerofill\b", "", atributos, flags=re.I)
        atributos = re.sub(r"\bnull\b", "", atributos, flags=re.I)
        atributos = re.sub(r"\bdefault\s+null\b", "", atributos, flags=re.I)
        atributos = converter_literais(atributos).strip().rstrip(",").strip()
        atributos = re.sub(r"\s{2,}", " ", atributos)

        pedacos = [f'"{coluna}"', tipo]
        if auto_increment:
            pedacos.append("GENERATED BY DEFAULT AS IDENTITY")
        if nao_nulo:
            pedacos.append("NOT NULL")
        if atributos:
            pedacos.append(atributos)
        if check:
            pedacos.append(f"CHECK (\"{coluna}\" {check})")
        colunas.append(" ".join(pedacos))

        # UNIQUE escrito na propria coluna (ex.: users.email) tambem serve
        # como alvo do ON CONFLICT
        if re.search(r"\bunique\b", atributos, re.I):
            unicos.append((nome, [coluna]))

        if on_update:
            triggers_updated.append(coluna)

    linhas = colunas + restricoes
    ddl = f'CREATE TABLE IF NOT EXISTS "{nome}" (\n    ' + ",\n    ".join(linhas) + "\n);"

    if triggers_updated:
        for coluna in triggers_updated:
            nome_trigger = f'trg_{nome}_{coluna}'
            ddl += (
                f'\nDROP TRIGGER IF EXISTS "{nome_trigger}" ON "{nome}";'
                f'\nCREATE TRIGGER "{nome_trigger}" BEFORE UPDATE ON "{nome}"'
                f' FOR EACH ROW EXECUTE FUNCTION somase_set_updated_at();'
            )

    return ddl, indices, unicos


# --------------------------------------------------------------------------
# conversao de INSERT / ALTER
# --------------------------------------------------------------------------
def converter_insert(sql: str, unicos: dict[str, list[list[str]]]) -> str:
    texto = converter_literais(sql)
    texto = re.sub(r"\bfrom\s+dual\b", "", texto, flags=re.I)
    texto = re.sub(r"^\s*insert\s+ignore\s+into", "INSERT INTO", texto, flags=re.I)

    tabela = re.search(r'insert\s+into\s+"?([a-z0-9_]+)"?', texto, re.I)
    nome = tabela.group(1).lower() if tabela else ""

    if re.search(r"on\s+duplicate\s+key\s+update", texto, re.I):
        alvo = unicos.get(nome)
        conflito = ""
        if alvo:
            conflito = " (" + ", ".join(f'"{c}"' for c in alvo[0]) + ")"
        atualizacoes = re.search(r"on\s+duplicate\s+key\s+update\s+(.*)$", texto, re.I | re.S)
        sets = []
        if atualizacoes:
            for par in atualizacoes.group(1).split(","):
                if "=" not in par:
                    continue
                col, valor = par.split("=", 1)
                col = col.strip().strip('"').strip("`")
                valor = re.sub(r'values\s*\(\s*[`"]?([a-z0-9_]+)[`"]?\s*\)', r'EXCLUDED."\1"', valor.strip(), flags=re.I)
                sets.append(f'"{col}" = {valor}')
        texto = re.sub(r"on\s+duplicate\s+key\s+update.*$", "", texto, flags=re.I | re.S).rstrip().rstrip(";")
        if sets:
            texto += f"\nON CONFLICT{conflito} DO UPDATE SET " + ", ".join(sets)
        else:
            texto += f"\nON CONFLICT{conflito} DO NOTHING"
        return texto + ";"

    if re.match(r"^\s*insert\s+ignore", sql, re.I):
        return texto.rstrip().rstrip(";") + "\nON CONFLICT DO NOTHING;"

    return texto.rstrip().rstrip(";") + ";"


def converter_alter(sql: str) -> list[str]:
    """ALTER TABLE do MySQL -> comandos idempotentes do PostgreSQL."""
    texto = identificar(converter_literais(sql))
    m = re.match(r'alter\s+table\s+(?:if\s+exists\s+)?"?([a-z0-9_]+)"?\s+(.*)$', texto, re.I | re.S)
    if not m:
        return [texto + ";"]
    tabela = m.group(1).lower()
    corpo = m.group(2).strip()

    saida: list[str] = []
    for acao in dividir_definicoes(corpo):
        baixo = acao.lower().strip()

        m_add_col = re.match(r'add\s+(?:column\s+)?(?:if\s+not\s+exists\s+)?"([a-z0-9_]+)"\s+(.*)$', acao, re.I | re.S)
        if m_add_col and not baixo.startswith("add index") and not baixo.startswith("add key"):
            coluna = m_add_col.group(1)
            resto = re.sub(r"\s+after\s+\"[a-z0-9_]+\"", "", m_add_col.group(2), flags=re.I)
            resto = re.sub(r"\s+comment\s+'(?:[^'\\]|\\.)*'", "", resto, flags=re.I)
            resto = resto.strip().rstrip(",")
            m_tipo = re.match(r"([a-zA-Z]+(?:\s*\([^)]*\))?(?:\s+unsigned)?)", resto)
            tipo_mysql = m_tipo.group(1) if m_tipo else "text"
            atributos = resto[len(tipo_mysql):].strip()
            tipo, check = tipo_pg(tipo_mysql)
            nao_nulo = bool(re.search(r"\bnot\s+null\b", atributos, re.I))
            atributos = re.sub(r"\bnot\s+null\b", "", atributos, flags=re.I)
            atributos = re.sub(r"\bunsigned\b", "", atributos, flags=re.I).strip()
            pedacos = [f'ADD COLUMN IF NOT EXISTS "{coluna}"', tipo]
            if nao_nulo:
                pedacos.append("NOT NULL")
            if atributos:
                pedacos.append(atributos)
            if check:
                pedacos.append(f'CHECK ("{coluna}" {check})')
            saida.append(f'ALTER TABLE "{tabela}" ' + " ".join(pedacos) + ";")
            continue

        m_add_idx = re.match(r'add\s+(?:unique\s+)?(?:index|key)\s+"?([a-z0-9_]+)"?\s*\((.*)\)', acao, re.I | re.S)
        if m_add_idx:
            unico = "UNIQUE " if baixo.startswith("add unique") else ""
            cols = ", ".join(f'"{c.lower()}"' for c in re.findall(r'"([a-z0-9_]+)"', m_add_idx.group(2)))
            saida.append(f'CREATE {unico}INDEX IF NOT EXISTS "{m_add_idx.group(1).lower()}" ON "{tabela}" ({cols});')
            continue

        m_drop = re.match(r'drop\s+column\s+"?([a-z0-9_]+)"?', acao, re.I)
        if m_drop:
            saida.append(f'ALTER TABLE "{tabela}" DROP COLUMN IF EXISTS "{m_drop.group(1).lower()}";')
            continue

        if baixo.startswith("add constraint") or baixo.startswith("drop constraint"):
            saida.append(f'ALTER TABLE "{tabela}" {acao};')
            continue

        saida.append(f'ALTER TABLE "{tabela}" {acao};')
    return saida


# --------------------------------------------------------------------------
# conversao de arquivo completo
# --------------------------------------------------------------------------
def expandir_blocos_condicionais(sql: str) -> str:
    """Troca o padrao MySQL information_schema + PREPARE pelo DDL equivalente.

    As migrations usam:
        SET @has := (SELECT COUNT(*) FROM information_schema...);
        SET @sql := IF(@has = 0, 'ALTER TABLE ...', 'DO 0');
        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    O PostgreSQL nao tem PREPARE de DDL; como o conversor ja gera
    "ADD COLUMN IF NOT EXISTS" e "CREATE INDEX IF NOT EXISTS", basta extrair
    o ALTER de dentro do IF e descartar o resto.
    """
    padrao = re.compile(
        r"SET\s+@sql\s*:=\s*IF\([^,]+,\s*'((?:[^']|'')*)'\s*,\s*'(?:[^']|'')*'\s*\)\s*;"
        r"\s*PREPARE\s+\w+\s+FROM\s+@sql\s*;\s*EXECUTE\s+\w+\s*;\s*DEALLOCATE\s+PREPARE\s+\w+\s*;",
        re.I | re.S,
    )

    def trocar(m: re.Match) -> str:
        return m.group(1).replace("''", "'") + ";"

    sql = padrao.sub(trocar, sql)
    # Sobras (blocos sem PREPARE, por exemplo) nao podem virar SQL invalido.
    sql = re.sub(r"^\s*(PREPARE|EXECUTE|DEALLOCATE)\b[^;]*;\s*$", "", sql, flags=re.I | re.M)
    return sql


def converter_arquivo(caminho: pathlib.Path, unicos: dict[str, list[list[str]]]) -> str:
    sql = caminho.read_text(encoding="utf-8")
    sql = expandir_blocos_condicionais(sql)
    sql = re.sub(r"/\*![\s\S]*?\*/", "", sql)
    comandos = dividir_statements(sql)
    saida: list[str] = []

    for comando in comandos:
        limpo = sem_comentarios_de_linha(comando).strip()
        if not limpo:
            continue
        baixo = limpo.lower()

        if re.match(r"^(set|lock\s+tables|unlock\s+tables|use|start\s+transaction|commit)\b", baixo):
            continue

        if baixo.startswith("create table"):
            m = re.match(r'create\s+table\s+(?:if\s+not\s+exists\s+)?`?([a-z0-9_]+)`?\s*\((.*)\)\s*(engine|default|comment|auto_increment|$).*$',
                         limpo, re.I | re.S)
            if not m:
                continue
            ddl, indices, cols_unicas = converter_create_table(m.group(1).lower(), m.group(2))
            for tabela, cols in cols_unicas:
                unicos.setdefault(tabela, [])
                if cols not in unicos[tabela]:
                    unicos[tabela].append(cols)
            saida.append(ddl)
            saida.extend(indices)
            continue

        if baixo.startswith("alter table"):
            saida.extend(converter_alter(limpo))
            continue

        if baixo.startswith("insert") or baixo.startswith("replace"):
            saida.append(converter_insert(limpo, unicos))
            continue

        if baixo.startswith("create index") or baixo.startswith("create unique index"):
            texto = identificar(converter_literais(limpo))
            texto = re.sub(r"create\s+(unique\s+)?index\s+", r"CREATE \1INDEX IF NOT EXISTS ", texto, flags=re.I)
            saida.append(texto.rstrip().rstrip(";") + ";")
            continue

        if baixo.startswith("drop table"):
            texto = identificar(limpo).rstrip().rstrip(";")
            if "cascade" not in texto.lower():
                texto += " CASCADE"
            saida.append(texto + ";")
            continue

        if baixo.startswith("select"):
            saida.append(identificar(converter_literais(limpo)).rstrip().rstrip(";") + ";")
            continue

        saida.append(identificar(converter_literais(limpo)).rstrip().rstrip(";") + ";")

    return "\n\n".join(saida) + "\n"


def sha256(caminho: pathlib.Path) -> str:
    return hashlib.sha256(caminho.read_bytes()).hexdigest()[:16]


CABECALHO = """-- ============================================================
-- SOMASE — {titulo}
-- GERADO AUTOMATICAMENTE por tools/build_postgres_sql.py
-- Nao edite este arquivo a mao: altere database/migrations e rode
--   python3 tools/build_postgres_sql.py
-- origem: {origem}
-- sha256: {hash}
-- ============================================================
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET client_min_messages = warning;

-- funcao usada pelos gatilhos de updated_at (equivale ao ON UPDATE do MySQL)
CREATE OR REPLACE FUNCTION somase_set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

"""

RODAPE = """
-- ------------------------------------------------------------
-- ajusta as sequences de identity apos cargas com id explicito
-- ------------------------------------------------------------
DO $$
DECLARE
    registro record;
    maior bigint;
BEGIN
    FOR registro IN
        SELECT c.table_name, c.column_name
          FROM information_schema.columns c
         WHERE c.table_schema = current_schema()
           AND c.is_identity = 'YES'
    LOOP
        EXECUTE format('SELECT COALESCE(MAX(%I), 0) FROM %I', registro.column_name, registro.table_name)
           INTO maior;
        IF maior > 0 THEN
            PERFORM setval(
                pg_get_serial_sequence(quote_ident(registro.table_name), registro.column_name),
                maior,
                true
            );
        END IF;
    END LOOP;
END $$;
"""


def gerar() -> list[pathlib.Path]:
    DESTINO.mkdir(parents=True, exist_ok=True)
    unicos: dict[str, list[list[str]]] = {}
    gerados: list[pathlib.Path] = []

    migrations = sorted(ORIGEM_MIGRATIONS.glob("*.sql"))
    seeds = sorted(ORIGEM_SEEDS.glob("*.sql"))

    # Ordem de carga: schema base (0001-0003) -> seeds -> migrations restantes.
    # Isso e necessario porque a 0004 concede a permissao access_admin_panel
    # ao perfil admin, e o perfil so existe depois dos seeds.
    def numero(caminho: pathlib.Path) -> int:
        try:
            return int(caminho.name.split("_")[0])
        except ValueError:
            return 9999

    base = [m for m in migrations if numero(m) <= 3]
    restantes = [m for m in migrations if numero(m) > 3]
    ordem_instalacao = base + seeds + restantes
    ordem_atualizacao = [m for m in base if not m.name.startswith("0001_")] + seeds + restantes

    conversoes: dict[pathlib.Path, str] = {}
    for caminho in migrations + seeds:
        conversoes[caminho] = converter_arquivo(caminho, unicos)

    # arquivos individuais (mesmo nome, extensao .pg.sql)
    for caminho, conteudo in conversoes.items():
        nome_pg = caminho.stem + ".pg.sql"
        cabecalho = CABECALHO.format(
            titulo=f"versao PostgreSQL de {caminho.name}",
            origem=caminho.relative_to(RAIZ).as_posix(),
            hash=sha256(caminho),
        )
        destino = DESTINO / nome_pg
        destino.write_text(cabecalho + conteudo, encoding="utf-8")
        gerados.append(destino)

    # instalacao completa: todas as migrations + seeds
    partes = []
    for caminho in ordem_instalacao:
        partes.append(f"\n-- ===== {caminho.name} =====\n" + conversoes[caminho])
    instalacao = CABECALHO.format(
        titulo="INSTALACAO COMPLETA (PostgreSQL 13+)",
        origem="migrations (schema base) + seeds + migrations restantes",
        hash=",".join(sha256(c) for c in migrations + seeds)[:16],
    )
    instalacao += """
-- COMO USAR
--   1. crie o banco:  createdb somase
--   2. rode:          psql -d somase -f database/postgresql/somase_instalacao_completa.pg.sql
--   3. o script e idempotente: pode rodar de novo sem duplicar dados.
--
-- ATENCAO: para recriar do zero, apague o schema antes:
--   DROP SCHEMA public CASCADE; CREATE SCHEMA public;
""" + "".join(partes) + RODAPE
    destino = DESTINO / "somase_instalacao_completa.pg.sql"
    destino.write_text(instalacao, encoding="utf-8")
    gerados.append(destino)

    # atualizacao incremental: tudo menos a 0001 (base ja existente)
    partes_att = []
    for caminho in ordem_atualizacao:
        partes_att.append(f"\n-- ===== {caminho.name} =====\n" + conversoes[caminho])
    atualizacao = CABECALHO.format(
        titulo="ATUALIZACAO DO BANCO (PostgreSQL 13+)",
        origem="migrations 0002+ e seeds",
        hash=",".join(sha256(c) for c in migrations + seeds if not c.name.startswith("0001_"))[:16],
    )
    atualizacao += """
-- Use quando o banco PostgreSQL ja existe e voce so quer aplicar o que falta.
-- Nao apaga dados: cria tabelas/colunas/indices que estiverem ausentes.
""" + "".join(partes_att) + RODAPE
    destino = DESTINO / "somase_atualizar_banco.pg.sql"
    destino.write_text(atualizacao, encoding="utf-8")
    gerados.append(destino)

    return gerados


def validar() -> int:
    """Roda a instalacao num banco temporario do PostgreSQL local."""
    banco = "somase_pg_teste"
    try:
        subprocess.run(["sudo", "-u", "postgres", "dropdb", "--if-exists", banco],
                       check=False, capture_output=True)
        subprocess.run(["sudo", "-u", "postgres", "createdb", banco], check=True, capture_output=True)
        origem = DESTINO / "somase_instalacao_completa.pg.sql"
        arquivo = pathlib.Path("/tmp/somase_instalacao_completa.pg.sql")
        arquivo.write_text(origem.read_text(encoding="utf-8"), encoding="utf-8")
        arquivo.chmod(0o644)
        for rodada in (1, 2):
            r = subprocess.run(
                ["sudo", "-u", "postgres", "psql", "-v", "ON_ERROR_STOP=1", "-q", "-d", banco, "-f", str(arquivo)],
                capture_output=True, text=True,
            )
            if r.returncode != 0:
                print(f"ERRO na rodada {rodada}:\n{r.stdout}\n{r.stderr}", file=sys.stderr)
                return 1
        consulta = """
            SELECT 'tabelas', COUNT(*) FROM information_schema.tables
             WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
            SELECT 'bancos', COUNT(*) FROM banks;
            SELECT 'roles', COUNT(*) FROM roles;
            SELECT 'categorias', COUNT(*) FROM categories;
            SELECT 'usuarios', COUNT(*) FROM users;
        """
        r = subprocess.run(["sudo", "-u", "postgres", "psql", "-t", "-A", "-F", "=", "-d", banco, "-c", consulta],
                           capture_output=True, text=True)
        print(r.stdout.strip())
        return 0
    finally:
        subprocess.run(["sudo", "-u", "postgres", "dropdb", "--if-exists", banco],
                       check=False, capture_output=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--validar", action="store_true", help="instala num PostgreSQL local para conferir")
    args = ap.parse_args()

    gerados = gerar()
    for caminho in gerados:
        print(f"gerado: {caminho.relative_to(RAIZ)} ({caminho.stat().st_size / 1024:.1f} KB)")

    if args.validar:
        return validar()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
