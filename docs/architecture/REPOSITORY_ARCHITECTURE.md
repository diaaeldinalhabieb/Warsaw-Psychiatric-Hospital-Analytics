# Repository Architecture

```text
PHA-WAW-001/
├── README.md
├── sql/
│   ├── 01_clinical_outcomes/
│   ├── 02_operational_efficiency/
│   ├── 03_financial_security/
│   └── 04_sdoh_biomarkers/
├── analysis/
│   ├── Pillar_1_Clinical_Outcomes_Care_Continuity.xlsx
│   ├── Pillar_2_Operational_Efficiency_and_Capacity.xlsx
│   ├── Pillar_3_Financial_Security_and_ROCI.xlsx
│   └── Pillar_4_SDOH_Biomarker_Synthesis.xlsx
└── docs/
    ├── schema/
    ├── governance/
    ├── validation/
    ├── registries/
    ├── executive/
    ├── architecture/
    └── source_blueprints/
```

The architecture separates:
- executable analytical evidence;
- downstream investigation workbooks;
- schema/governance;
- validation/reconciliation;
- public executive communication.

Confidential Board material is intentionally excluded from the public repository.
