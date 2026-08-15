# PHA-WAW-001 — Warsaw Psychiatric Hospital Analytics Program

> **From analytical question to decision intelligence.**  
> A governed, question-driven healthcare analytics project built to demonstrate how I think as a data analyst—not just what I can calculate.

| | |
|---|---|
| **Project ID** | `PHA-WAW-001` |
| **Focus** | Healthcare Analytics / Clinical Intelligence / Operations / Revenue Cycle / SDOH |
| **Core stack** | SQL Server / SSMS → Excel |
| **Architecture** | 4 analytical pillars / 17 analytical tables + 1 database-support object |
| **Portfolio focus** | Analytical thinking, evidence governance, deep investigation, cross-pillar reasoning |
| **Repository** | SQL evidence + deep-analysis workbooks + supporting documentation |

---

## 1. The analytical idea

The project starts with a decision problem, not with a chart.

The goal is to show a complete reasoning chain:

```text
BUSINESS / CLINICAL PROBLEM
          ↓
ANALYTICAL QUESTION
          ↓
HYPOTHESIS
          ↓
METRICS + DIMENSIONS + GRAIN
          ↓
SQL: DATA QUALITY + CLEANING + PREPARATION
          ↓
SQL: REPRODUCIBLE EVIDENCE
          ↓
EXCEL: DEEP ANALYSIS
          ↓
MATHEMATICAL + STATISTICAL + DESCRIPTIVE REVIEW
          ↓
TEMPORAL / CAUSAL STRESS TEST
          ↓
CROSS-PILLAR SYNTHESIS
          ↓
INSIGHT
          ↓
EXECUTIVE ACTION
          ↓
RE-MEASUREMENT
```

The central rule is:

> **Do not start with the data that happens to be available. Start with the decision that needs to be improved.**

That principle drives how questions, metrics, joins, cohorts, evidence, and recommendations are designed.

---

## 2. Why SQL comes first

### SQL is the evidence foundation

SQL was used first to:

- work from the verified physical schema;
- clean and prepare the data;
- validate types, ranges, nulls, and categorical values;
- define the correct analytical grain;
- control joins and prevent fan-out;
- pre-aggregate 1:N relationships where required;
- construct reproducible question-specific metrics;
- create evidence datasets that can be independently traced back to the analytical question.

A typical evidence path is:

```text
SOURCE TABLES
    ↓
DQ CONTROLS
    ↓
TYPE / RANGE / CATEGORY NORMALIZATION
    ↓
SAFE-GRAIN PRE-AGGREGATION
    ↓
CONTROLLED JOINS
    ↓
QUESTION-SPECIFIC METRICS
    ↓
REPRODUCIBLE EVIDENCE DATASET
```

### Excel is the deep-investigation layer

After the SQL evidence layer was established, Excel was used for:

- cohort analysis;
- segmentation;
- distributions and rates;
- cross-tabulation;
- anomaly and outlier inspection;
- financial exposure analysis;
- comparative analysis;
- synthesis and recommendation development.

> **SQL prepares and protects the evidence. Excel interrogates the evidence deeply.**

This separation is deliberate: the workbook is not the source of truth; it is the investigation layer built on top of a governed SQL evidence foundation.

---

## 3. Analytical governance

The project follows an evidence-first operating model.

### Evidence before narrative
No major insight should exist without reproducible evidence.

### Confidence starts at zero
Clinical, operational, and financial assumptions remain untrusted until supported by data.

### Physical schema is authoritative
Executable SQL is bounded by the verified physical schema rather than invented tables, fields, or relationships.

### Question-centric data quality
DQ is evaluated against the fields and assumptions required for the specific analytical question.

### Grain governance
The unit of analysis is explicit before aggregation or interpretation.

### Temporal governance
Longitudinal analysis must preserve chronology and avoid future-data leakage.

### Causal hardening
The project explicitly rejects these shortcuts:

```text
Distribution ≠ Causality
Sequence   ≠ Progression
Recurrence ≠ Severity
Cluster    ≠ Vulnerability
```

The result is a workflow designed to make the evidence harder to fool and the final recommendation easier to defend.

---

## 4. The four-pillar analytical architecture

The hospital problem space was decomposed into four connected analytical domains.

| Pillar | Core question | Executive lens |
|---|---|---|
| **1. Clinical Outcomes & Care Continuity** | What separates deterioration, response, engagement, and recovery? | Clinical strategy |
| **2. Operational Efficiency & Capacity Optimization** | Where does access, workforce pressure, and scheduling create friction? | Operations / capacity |
| **3. Financial Security & Revenue Cycle Intelligence** | Where does operational or clinical friction become financial loss? | Finance / revenue cycle |
| **4. SDOH, Biomarkers & Structural Vulnerability** | What structural, social, biological, and behavioral factors help explain the observed patterns? | Prevention / targeted care |

The pillars are intentionally connected:

```text
P4 — STRUCTURAL / BIOLOGICAL VULNERABILITY
                    ↓
P2 — ACCESS / CAPACITY / OPERATIONAL FRICTION
                    ↓
P1 — CLINICAL TRAJECTORY / CONTINUITY
                    ↓
P3 — FINANCIAL / REVENUE CONSEQUENCES
                    ↓
EXECUTIVE INTERVENTION
                    ↓
RE-MEASUREMENT
```

---

## 5. The questions I investigated

### Pillar 1 — Clinical Outcomes & Care Continuity

- **ANA-201 / ANA-202:** medication adherence, crisis recurrence, treatment changes, adverse effects, and interim progression.
- **ANA-203:** narrative clinical-note sentiment versus structured risk assessment.
- **ANA-204:** digital engagement and homework adherence versus outcome trajectory.

The analytical emphasis is not simply “which cohort performs better?”, but:

> **What is the strength of the signal, what alternative explanations exist, and what level of causal confidence is justified?**

### Pillar 2 — Operational Efficiency & Capacity

- **ANA-205:** distance, transport time, wait time, income, employment, district, and no-show behavior.
- **ANA-206:** workload, experience, burnout, sick leave, provider reassignment, and continuity.
- **ANA-207:** intra-facility latency and peak operational dwell time.
- **ANA-208:** authorization friction, cancellations/no-shows, and operational financial leakage.

### Pillar 3 — Financial Security & Revenue Cycle

- **ANA-301:** prior-authorization latency and claim-denial cascades.
- **ANA-302:** treatment cost-efficacy and value-based ROCI.
- **ANA-303:** provider handoffs, clinical documentation gaps, and audit vulnerability.
- **ANA-304:** acute-crisis financial exposure and payer/SLA implications.

### Pillar 4 — SDOH, Biomarkers & Structural Vulnerability

- **ANA-401:** housing instability, low income, transit friction, capacity loss, and financial leakage.
- **ANA-402:** caregiver/family/peer support as a buffer against engagement failure.
- **ANA-403:** trauma, inflammatory stress, sleep disruption, treatment resistance, and medication switching.
- **ANA-404:** immigration-related vulnerability, narrative/structured-risk discordance, and acute-crisis prediction signals.

---

## 6. Selected evidence signals

The project produced a set of high-value signals that become meaningful when interpreted together.

| Signal | Evidence | Analytical reading |
|---|---:|---|
| Overall crisis rate | **4.214%** | Macro baseline for crisis-event prevalence |
| Remote no-show rate | **11.08%** | Strong operational signal requiring cohort-level investigation |
| Remote missed appointments | **6,814** | Direct capacity-loss signal |
| Severe scheduling-delay share | **54.26%** | Material access/throughput pressure |
| Clinicians above high-caseload threshold | **70.8%** | Workforce stress signal |
| Total billed revenue in operational analysis | **686.90M PLN** | Scale of the financial system under investigation |
| Combined leakage in the operational workbook | **280.75M PLN** | Evidence of material revenue/capacity exposure |
| High-engagement full remission signal | **31.08%** | Strong association worth further longitudinal testing |

### A note on interpretation

These figures are **evidence signals, not automatic causal claims**.

For example:

- a lower-crisis cohort does not prove adherence caused the difference;
- a remission gradient does not, by itself, prove digital engagement caused recovery;
- provider reassignment concurrent with financial exposure does not prove a handoff caused an audit outcome.

That distinction is intentional and central to the analytical quality of the project.

---

## 7. The deeper cross-pillar questions

The real value appears when the pillars are combined.

### Access → Clinical
Does access friction increase non-attendance and weaken continuity?

### Workforce → Clinical
Does clinician overload increase reassignment and disrupt longitudinal recovery?

### Clinical → Financial
Where does deterioration or acute utilization become avoidable high-cost exposure?

### SDOH → Operations
Are high-friction patients systematically concentrated in specific structural-risk cohorts?

### SDOH → Clinical
Does social support buffer disengagement or improve resilience?

### Clinical + Operations → Finance
Where does an operational or clinical failure become measurable financial leakage?

These are the questions that move the project beyond four disconnected analyses into a single decision-intelligence architecture.

---

## 8. AI / NLP readiness

AI is treated here as an **analytical extension**, not as a decorative claim.

The project already creates structured evidence suitable for future NLP/AI layers, particularly around:

- clinical-note sentiment;
- self-harm mentions;
- hallucination mentions;
- structured-versus-narrative risk discordance;
- vulnerable-cohort surveillance.

The architecture also identifies future-state uses such as:

- real-time NLP surveillance for early deterioration signals;
- automated documentation-quality checks before claim submission.

### Important distinction

The repository should **not** claim that a production AI model was trained or deployed unless such a model and its evaluation artifacts are actually included.

The stronger portfolio message is:

> **The analytical design creates a governed foundation on which AI/NLP capabilities can be added without bypassing data-quality, temporal, or causal controls.**

---

## 9. Why this is a senior-level analytics portfolio project

### Analytical thinking
The project begins with decision-oriented questions and decomposes them into measurable hypotheses.

### Data discipline
The evidence layer is built with explicit grain, joins, DQ controls, and reproducibility.

### Metric discipline
Rates, denominators, financial totals, and cohort definitions are treated as analytical objects—not as formatting details.

### Statistical skepticism
Observed differences are challenged rather than automatically promoted to conclusions.

### Causal discipline
The project separates what is observed from what is associated and from what still requires causal validation.

### Cross-domain reasoning
Clinical, operational, financial, and structural variables are connected into a single analytical system.

### Decision orientation
The final deliverable is not a chart library. It is a set of decision pathways and intervention hypotheses that can be re-measured.

---

## 10. Repository structure

```text
PHA-WAW-001/
│
├── README.md
│
├── sql/
│   ├── 01_clinical_outcomes/
│   ├── 02_operational_efficiency/
│   ├── 03_financial_security/
│   └── 04_sdoh_biomarkers/
│
├── analysis/
│   ├── Pillar_1_Clinical_Outcomes_Care_Continuity.xlsx
│   ├── Pillar_2_Operational_Efficiency_and_Capacity.xlsx
│   ├── Pillar_3_Financial_Security_and_ROCI.xlsx
│   └── Pillar_4_SDOH_Biomarker_Synthesis.xlsx
│
└── docs/
    ├── source_blueprints/
    ├── MASTER_ANALYTICAL_CASE_STUDY.md
    ├── SQL_COVERAGE_MAP.md
    └── INDEX.md
```

### Where to look

- **[SQL evidence](sql/)** — reproducible analytical queries organized by pillar.
- **[Deep-analysis workbooks](analysis/)** — Excel investigation outputs.
- **[Master case study](docs/MASTER_ANALYTICAL_CASE_STUDY.md)** — full analytical narrative and detailed findings.
- **[SQL coverage map](docs/SQL_COVERAGE_MAP.md)** — question-to-script traceability.
- **[Source blueprints](docs/source_blueprints/)** — strategic roadmap and pillar architectures.

---

## 11. Analytical quality gates

Before a finding becomes an executive statement, it passes through a common review framework:

| Gate | Question |
|---|---|
| **Definition** | Is the business/clinical question explicit? |
| **Grain** | Is the unit of analysis unambiguous? |
| **DQ** | Were missing, invalid, range, and category issues examined? |
| **Join integrity** | Can 1:N relationships inflate the result? |
| **Mathematics** | Are numerators, denominators, ratios, and weighted rates correct? |
| **Statistics** | Is the observed pattern meaningfully different or merely large-volume? |
| **Description** | Does the narrative match the underlying evidence? |
| **Temporal validity** | Is the time order appropriate? |
| **Causal validity** | Does the evidence justify a causal statement? |
| **Decision value** | What should change because of the finding? |

---

## 12. Portfolio takeaway

This project is designed to demonstrate one capability above all:

> **I can take a complex, cross-functional healthcare problem and build a defensible analytical path from question → evidence → interpretation → decision.**

The README is the navigation layer.

The **SQL proves how the evidence was built**.

The **Excel workbooks show how the evidence was interrogated**.

The **case study shows how the findings were synthesized**.

The **cross-pillar architecture shows how isolated metrics become decision intelligence**.

---

### Extended documentation

For the full investigation narrative, methodology, evidence classification, KPI design, and detailed module-by-module discussion, see:

**[MASTER_ANALYTICAL_CASE_STUDY.md](docs/MASTER_ANALYTICAL_CASE_STUDY.md)**
