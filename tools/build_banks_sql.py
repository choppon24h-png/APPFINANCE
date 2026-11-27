#!/usr/bin/env python3
"""Gera a migration 0005 (tabela `banks`) a partir da lista oficial de bancos.

Fonte: BrasilAPI /api/banks/v1, que espelha o cadastro de instituicoes do
Banco Central (codigo COMPE/ISPB). O JSON e guardado em
database/data/bancos_brasil.json para o build ser reproduzivel offline.

Uso:
    python3 tools/build_banks_sql.py              # usa o snapshot local
    python3 tools/build_banks_sql.py --baixar     # atualiza o snapshot antes
"""
from __future__ import annotations

import argparse
import json
import pathlib
import urllib.request

RAIZ = pathlib.Path(__file__).resolve().parent.parent
SNAPSHOT = RAIZ / "database" / "data" / "bancos_brasil.json"
DESTINO = RAIZ / "database" / "migrations" / "0005_banks.sql"
URL = "https://brasilapi.com.br/api/banks/v1"


def baixar() -> list[dict]:
    req = urllib.request.Request(URL, headers={"User-Agent": "SOMASE/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        dados = json.loads(resp.read().decode("utf-8"))
    SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
    SNAPSHOT.write_text(json.dumps(dados, ensure_ascii=False, indent=1), encoding="utf-8")
    return dados


def carregar(baixar_antes: bool) -> list[dict]:
    if baixar_antes or not SNAPSHOT.is_file():
        return baixar()
    return json.loads(SNAPSHOT.read_text(encoding="utf-8"))


# Nomes populares/marcas que nao aparecem na razao social do BCB.
# Sem isso, buscar "nubank" nao encontra "NU PAGAMENTOS - IP".
ALIASES: dict[str, list[str]] = {
    "001": ["Banco do Brasil", "BB"],
    "003": ["Banco da Amazônia", "BASA"],
    "004": ["Banco do Nordeste", "BNB"],
    "021": ["Banestes"],
    "033": ["Santander"],
    "036": ["Bradesco BBI"],
    "037": ["Banpará"],
    "041": ["Banrisul"],
    "047": ["Banese"],
    "070": ["BRB", "Banco de Brasília"],
    "077": ["Inter", "Banco Inter", "Intermedium"],
    "085": ["Ailos", "Cecred"],
    "094": ["Finaxis"],
    "097": ["Credisis"],
    "104": ["Caixa", "Caixa Econômica Federal", "CEF", "Caixa Econômica"],
    "121": ["Agibank", "Agi"],
    "136": ["Unicred"],
    "197": ["Stone", "Stone Pagamentos"],
    "208": ["BTG", "BTG Pactual"],
    "212": ["Original", "Banco Original"],
    "237": ["Bradesco", "Next", "Next Bank"],
    "246": ["ABC Brasil"],
    "290": ["PagBank", "PagSeguro"],
    "299": ["Afinz"],
    "318": ["BMG"],
    "323": ["Mercado Pago", "Mercado Livre"],
    "329": ["QI", "Qi Tech"],
    "335": ["Digio"],
    "336": ["C6", "C6 Bank", "C6 Pay"],
    "341": ["Itaú Unibanco", "Itaú", "Itau"],
    "348": ["XP", "XP Investimentos"],
    "362": ["Cielo"],
    "364": ["Efí", "Gerencianet"],
    "365": ["Binance"],
    "379": ["Cooperforte"],
    "380": ["PicPay", "Pic Pay"],
    "382": ["Fidúcia"],
    "383": ["EBANX"],
    "389": ["Mercantil"],
    "403": ["Cora"],
    "404": ["SumUp"],
    "413": ["BV", "Banco BV", "Votorantim"],
    "422": ["Safra"],
    "425": ["Socinal"],
    "450": ["Fits"],
    "461": ["Asaas"],
    "464": ["Sumitomo Mitsui", "SMBC"],
    "477": ["Citibank", "Citi"],
    "479": ["ItaúBank"],
    "505": ["UBS"],
    "529": ["PinBank"],
    "536": ["Neon", "Neon Pagamentos"],
    "546": ["Okto"],
    "552": ["UzziPay"],
    "579": ["Quadra"],
    "600": ["Luso Brasileiro"],
    "610": ["VR"],
    "611": ["Paulista"],
    "612": ["Guanabara"],
    "613": ["Omni"],
    "623": ["Pan", "Banco Pan"],
    "626": ["C6 Consignado"],
    "637": ["Sofisa", "Sofisa Direto"],
    "643": ["Pine"],
    "654": ["Digimais"],
    "655": ["Votorantim"],
    "660": ["PagMe"],
    "665": ["Stark Bank"],
    "668": ["Celcoin"],
    "672": ["Stone"],
    "703": ["GetNet"],
    "707": ["Daycoval"],
    "712": ["Ouribank"],
    "719": ["Master"],
    "745": ["Citibank"],
    "747": ["Rabobank"],
    "748": ["Sicredi"],
    "751": ["Scotiabank"],
    "752": ["BNP Paribas"],
    "754": ["Banco Sistema"],
    "755": ["Bank of America", "BOFA"],
    "756": ["Sicoob"],
    "757": ["KEB Hana"],
    "764": ["Independência"],
    "769": ["99Pay", "99"],
    "773": ["Kiwify"],
    "775": ["ContaAzul"],
    "793": ["MagaluPay", "Magalu"],
    "795": ["Traton"],
    "805": ["Desenvolve MG"],
    "808": ["Rendimento"],
    # "nubank" nao esta na razao social, mas e o nome que todo mundo digita
    "260": ["Nubank", "Nu", "Nu Pagamentos", "NuBank", "Nubank PJ"],
}


def esc(valor) -> str:
    if valor is None:
        return "NULL"
    texto = str(valor).strip()
    if texto == "":
        return "NULL"
    return "'" + texto.replace("\\", "\\\\").replace("'", "''") + "'"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--baixar", action="store_true", help="baixa a lista atual do BCB/BrasilAPI")
    args = ap.parse_args()

    bancos = carregar(args.baixar)
    # apenas instituicoes com codigo COMPE (as demais nao aparecem em boletos)
    com_codigo = [b for b in bancos if b.get("code") is not None]
    com_codigo.sort(key=lambda b: (int(b["code"]), b.get("name") or ""))

    linhas = []
    for b in com_codigo:
        compe = f"{int(b['code']):03d}"
        apelidos = " | ".join(ALIASES.get(compe, [])) or None
        linhas.append(
            "(" + ", ".join([
                esc(compe),
                esc(b.get("ispb")),
                esc(b.get("name")),
                esc(b.get("fullName")),
                esc(apelidos),
                esc(b.get("logo_url")),
            ]) + ")"
        )

    # quebra em blocos para nao estourar max_allowed_packet em hospedagem
    blocos = []
    for i in range(0, len(linhas), 100):
        bloco = linhas[i:i + 100]
        blocos.append(
            "INSERT INTO `banks` (`compe`, `ispb`, `name`, `full_name`, `aliases`, `logo_url`) VALUES\n"
            + ",\n".join(bloco)
            + "\nON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `full_name` = VALUES(`full_name`),"
              " `aliases` = VALUES(`aliases`), `logo_url` = VALUES(`logo_url`), `active` = 1;\n"
        )

    sql = f"""-- ============================================================
-- SOMASE — Catalogo de bancos brasileiros (codigo COMPE)
-- Migration 0005
--
-- Fonte: cadastro de instituicoes do Banco Central (via BrasilAPI).
-- {len(com_codigo)} instituicoes com codigo COMPE.
--
-- O formulario de conta usa esta tabela para autocompletar o banco:
-- digite o nome ou o codigo (ex.: 260, 001, nubank, itau).
--
-- Idempotente: pode ser executada mais de uma vez (ON DUPLICATE KEY).
-- A coluna accounts.bank_code pode falhar com "Duplicate column" em
-- uma segunda execucao — o atualizador do sistema ignora esse erro.
-- ============================================================
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `banks` (
    `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `compe`      CHAR(3)      NULL COMMENT 'Codigo COMPE (3 digitos, ex.: 001)',
    `ispb`       CHAR(8)      NULL COMMENT 'Identificador padrao bancario',
    `name`       VARCHAR(120) NOT NULL COMMENT 'Nome da instituicao (BCB)',
    `full_name`  VARCHAR(160) NULL COMMENT 'Nome completo/fantasia',
    `aliases`    VARCHAR(200) NULL COMMENT 'Marcas/nomes populares (nubank, itau, c6...)',
    `logo_url`   VARCHAR(255) NULL COMMENT 'Logotipo (opcional, CDN publica)',
    `active`     TINYINT(1)   NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_banks_compe` (`compe`),
    UNIQUE KEY `uq_banks_ispb` (`ispb`),
    KEY `idx_banks_name` (`name`),
    KEY `idx_banks_full` (`full_name`),
    KEY `idx_banks_aliases` (`aliases`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Bancos brasileiros com codigo COMPE para autocomplete';

-- ---------- accounts: guardar o codigo do banco escolhido ----------
ALTER TABLE `accounts` ADD COLUMN `bank_code` CHAR(3) NULL AFTER `bank_name`;
ALTER TABLE `accounts` ADD INDEX `idx_accounts_bank` (`bank_code`);

-- ---------- carga inicial ----------
{''.join(blocos)}
-- ---------- verificacao ----------
SELECT COUNT(*) AS bancos_carregados FROM `banks`;
"""

    DESTINO.write_text(sql, encoding="utf-8")
    print(f"OK: {DESTINO} ({len(com_codigo)} bancos, {len(sql) / 1024:.1f} KB)")


if __name__ == "__main__":
    main()
