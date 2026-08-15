from pathlib import Path
import csv, re, sys

ROOT = Path(__file__).resolve().parents[1]
required = [
    "README.md",
    ".gitignore",
    "docs/schema/FULL_COLUMN_INVENTORY.xlsx",
    "docs/schema/SCHEMA_CONTRACT.md",
    "docs/governance/ANALYTICAL_GOVERNANCE.md",
    "docs/governance/PUBLICATION_GATE.md",
    "docs/validation/CROSS_ARTIFACT_RECONCILIATION.md",
    "docs/validation/RELEASE_METRIC_AUDIT.csv",
    "docs/registries/FILE_REGISTRY.csv",
    "docs/registries/SQL_CATALOG.csv",
    "docs/registries/METRIC_DEFINITIONS.md",
]
missing=[p for p in required if not (ROOT/p).exists()]
sql=list((ROOT/"sql").rglob("*.sql"))
if missing:
    print("FAIL: missing required artifacts:", *missing, sep="\n- ")
    sys.exit(1)
if len(sql)!=12:
    print(f"FAIL: expected 12 SQL artifacts, found {len(sql)}")
    sys.exit(1)
for p in sql:
    txt=p.read_text(encoding="utf-8-sig")
    if not re.search(r"-- SQL ID:",txt):
        print("FAIL: missing SQL ID:",p); sys.exit(1)
    if not re.search(r"-- Grain Level:",txt):
        print("FAIL: missing Grain Level:",p); sys.exit(1)
print(f"PASS: {len(sql)} SQL artifacts and publication controls validated.")
