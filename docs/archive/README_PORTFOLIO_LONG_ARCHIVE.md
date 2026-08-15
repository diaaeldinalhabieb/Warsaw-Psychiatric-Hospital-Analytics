# PHA-WAW-001 — Warsaw Psychiatric Hospital Analytics Program

## Strategic Healthcare Analytics Case Study

> **From raw healthcare data to decision intelligence.** A question-driven healthcare analytics program that connects clinical outcomes, operational capacity, financial performance, and structural vulnerability.

**Project ID:** PHA-WAW-001  
**Environment:** SQL Server / SSMS → Excel Evidence Architecture  
**Model:** Question → SQL Evidence → Deep Analysis → Statistical Review → Cross-Pillar Synthesis → Executive Recommendation  
**Scope:** 4 integrated pillars / 17 verified physical tables

---

## What this project demonstrates

This is not a dashboard-first project. It is a demonstration of **analytical thinking**.

I start with the decision problem, translate it into measurable dimensions and hypotheses, establish the evidence layer in SQL, move the validated evidence into Excel for deep analysis, stress-test the results mathematically and statistically, then convert the evidence into defensible recommendations.

### My reasoning framework

```text
BUSINESS / CLINICAL PROBLEM
        ↓
ANALYTICAL QUESTION
        ↓
HYPOTHESIS
        ↓
METRICS + DIMENSIONS + GRAIN
        ↓
SQL DQ + DATA PREPARATION
        ↓
SQL EVIDENCE
        ↓
EXCEL DEEP ANALYSIS
        ↓
MATHEMATICAL + STATISTICAL REVIEW
        ↓
TEMPORAL / CAUSAL STRESS TEST
        ↓
CROSS-PILLAR INSIGHT
        ↓
EXECUTIVE DECISION
        ↓
RE-MEASUREMENT
```

The central principle is:

> **Do not start with the data that happens to be available. Start with the decision that needs to be improved.**

---

## SQL first. Excel second.

### SQL — evidence and data-preparation layer

SQL was used first to validate the physical schema, clean and prepare the data, control joins and grain, prevent duplication, create reproducible datasets for each analytical question, preserve temporal integrity, and produce traceable evidence.

### Excel — deep analytical layer

After the SQL evidence layer was established, Excel was used for cohort analysis, segmentation, distributions, comparisons, financial aggregation, anomaly detection, statistical inspection, and recommendation development.

> **SQL prepares and proves the evidence. Excel interrogates the evidence deeply.**

This separation is a core part of the portfolio story: the analytical conclusion is not simply “I made a spreadsheet”; it is that I built a governed evidence pipeline and then investigated the evidence from multiple analytical angles.

---

# Four-pillar architecture

The master roadmap defines four integrated analytical pillars. fileciteturn0file0L75-L101

| Pillar | Analytical focus | Executive decision |
|---|---|---|
| **P1 — Clinical Outcomes & Care Continuity** | adherence, medication response, risk, digital engagement, recovery | clinical strategy |
| **P2 — Operational Efficiency & Capacity Optimization** | access friction, no-show, workforce load, latency, authorization | operations / workforce |
| **P3 — Financial Security & Revenue Cycle Intelligence** | denials, leakage, treatment value, ROCI, audit exposure | finance / revenue cycle |
| **P4 — SDOH, Biomarkers & Structural Vulnerability** | housing, income, isolation, trauma, biology, structural risk | prevention / targeted care |

The real value is in the **connections between pillars**, not in treating them as four independent reports.

---

# Selected analytical findings

## Clinical — crisis and adherence

The patient-level adherence analysis contains **200,000 patients** and **8,428 patients with crisis**, giving an overall crisis rate of **4.214%**.

| Adherence tier | Patients | Crisis cases | Crisis rate |
|---|---:|---:|---:|
| Low <50% | 31,941 | 1,359 | 4.25% |
| Moderate 50–79% | 134,584 | 5,740 | 4.26% |
| High ≥80% | 33,475 | 1,329 | 3.97% |
| **Overall** | **200,000** | **8,428** | **4.214%** |

The important analytical step is not only calculating the rate. It is asking whether the cohort difference survives adjustment for baseline risk and time before any causal claim is made.

## Clinical — digital engagement

The engagement analysis shows a pronounced recovery gradient:

- **High engagement:** 31.08% full remission
- **Moderate engagement:** 1.96%
- **Low / passive engagement:** 0.00%
- High-engagement cost per remission: approximately **11,134 PLN**
- Moderate-engagement cost per remission: approximately **172,967 PLN**

This is a strong value signal, but the correct analytical language is **association / observed separation**, not automatic causality. Baseline severity, treatment mix, motivation, and selection effects still need longitudinal testing.

## Operations — access friction

The operational evidence shows:

- **200,000 appointments**
- **18,076 no-shows**
- **11.08% remote no-show rate**
- approximately **70.4 minutes** average remote transport time
- approximately **21.5 km** average remote distance
- approximately **6,814** remote missed appointments

The decision question is therefore not simply “why are no-shows high?” but:

> **Which friction combination creates the highest preventable capacity loss, and where is telehealth a plausible substitute?**

## Workforce — caseload pressure

The high-caseload cohort contains **708 of 1,000 clinicians (70.8%)**, with approximately:

- **68.58 cases/week** average caseload
- **8.06 / 10** burnout index
- **15.95 days/provider** sick leave
- **17.91%** reassignment rate

The proposed analytical chain is:

`Caseload → Burnout → Sick Leave → Provider Change → Potential Continuity Disruption`

Each arrow remains a hypothesis until the longitudinal evidence supports it.

## Financial — revenue leakage

The financial evidence includes:

- **686.90M PLN** total billed
- **202.83M PLN** direct rejected amount
- **114.54M PLN** indirect lost capacity
- **280.75M PLN** combined leakage
- **157.26M PLN** leakage associated with the severe-wait tier

This turns “administrative friction” into an explicit economic mechanism.

## Acute utilization

The integrated evidence contains:

- **8,428 crisis events**
- **4,228 hospitalizations**
- approximately **33.90% ER claim-rejection rate** in the relevant billed-amount view

The executive question becomes: **where could earlier intervention prevent high-cost acute utilization?**

---

# The integrated story

```text
STRUCTURAL VULNERABILITY
Housing · Income · Isolation · Trauma · Immigration · Biology
                         ↓
ACCESS & OPERATIONAL FRICTION
Distance · Transport · Wait Time · No-Show · Workforce Load · Authorization
                         ↓
CLINICAL CONTINUITY & ENGAGEMENT
Adherence · Medication Changes · Digital Engagement · Notes · Risk
                         ↓
ACUTE UTILIZATION
ER Visits · Hospitalizations · Crisis Recurrence
                         ↓
FINANCIAL CONSEQUENCE
Denials · Partial Payment · Leakage · Audit Exposure · ROCI
                         ↓
EXECUTIVE INTERVENTION
Access redesign · workload control · digital support · payer SLA · prevention
                         ↓
MEASURE AGAIN
```

Pillar 4 is explicitly designed as the **root-cause engine** for anomalies surfaced by the preceding pillars. fileciteturn0file4L4-L17

---

# Analytical governance

The roadmap establishes an evidence-first architecture, a verified physical schema, question-centric data quality, temporal integrity, and protection against fan-out / Cartesian duplication. fileciteturn0file0L19-L35 fileciteturn0file0L38-L53

Every promoted finding passes these gates:

1. **Definition:** correct numerator, denominator, unit, and terminology.
2. **Mathematics:** independent recomputation and reconciliation.
3. **Grain:** explicit patient / appointment / claim / session / provider / period grain.
4. **Statistics:** model and inference matched to the outcome.
5. **Time:** feature time precedes outcome time for predictive claims.
6. **Causality:** association is not written as causation without supporting design.
7. **Traceability:** `Question → SQL → Evidence → Excel → Recommendation`.

The roadmap requires SQL traceability metadata including SQL ID, investigation ID, grain, temporal anchor, join keys, and duplicate-prevention logic. fileciteturn0file0L251-L263

---

# Question-to-evidence structure

Each analytical module follows the same portfolio pattern:

| Step | Output |
|---|---|
| **Question** | What decision are we trying to improve? |
| **Objective** | What must be measured? |
| **Hypothesis** | What mechanism do we expect? |
| **Dimensions** | Which cohorts / variables matter? |
| **SQL DQ** | Is the required evidence structurally fit? |
| **SQL evidence** | What is the reproducible analytical dataset? |
| **Excel deep analysis** | What patterns, anomalies and differences appear? |
| **Statistical review** | How strong and uncertain is the result? |
| **Causal stress test** | What alternative explanations remain? |
| **Insight** | What should management understand? |
| **Action** | What should management change? |
| **Re-measurement** | Did the intervention work? |

The pillar PDFs define the analytical questions, objectives, hypotheses and intended mechanisms; the Excel workbooks provide the observed analytical evidence. fileciteturn0file1L4-L23 fileciteturn0file2L13-L31 fileciteturn0file3L14-L22 fileciteturn0file4L36-L69

---

# SQL repository design

The SQL code will be organized by **analytical question**, not by random table or ad-hoc script.

```text
/sql
├── pillar_1_clinical/
│   ├── ANA-101_adherence_crisis.sql
│   ├── ANA-102_medication_progression.sql
│   ├── ANA-103_nlp_structured_risk.sql
│   └── ANA-104_digital_engagement_outcomes.sql
├── pillar_2_operations/
│   ├── ANA-205_no_show_access.sql
│   ├── ANA-206_workforce_burnout.sql
│   ├── ANA-207_visit_latency.sql
│   └── ANA-208_authorization_leakage.sql
├── pillar_3_finance/
│   ├── ANA-301_authorization_denials.sql
│   ├── ANA-302_value_roci.sql
│   ├── ANA-303_audit_handoffs.sql
│   └── ANA-304_crisis_financial_impact.sql
└── pillar_4_sdoh/
    ├── ANA-401_access_vulnerability.sql
    ├── ANA-402_social_support_engagement.sql
    ├── ANA-403_biomarker_treatment_response.sql
    └── ANA-404_nlp_crisis_prediction.sql
```

The names above define the **repository structure**. The actual SQL content will be integrated and audited question-by-question when the scripts are attached.

---

# Portfolio presentation

## GitHub

The top-level README should be the **landing page**, not the entire analytical archive. It should make a reviewer understand the project and your thinking in a few minutes.

Detailed evidence should live in:

```text
/docs
/excel_evidence
/sql
/audit
/images
```

The extended analytical case study is stored separately in [`docs/MASTER_ANALYTICAL_CASE_STUDY.md`](docs/MASTER_ANALYTICAL_CASE_STUDY.md).

## LinkedIn

Do **not** paste the full README into LinkedIn.

Use a short case-study narrative or carousel:

`Problem → How I thought → SQL evidence → Deep analysis → 1–2 high-value findings → Business implication → GitHub`

The README is the evidence hub. LinkedIn is the attention hook.

---

# Why this project is senior-level

The portfolio signal is not the number of KPIs. It is the reasoning discipline behind them:

- starting from decisions rather than charts;
- defining grain before aggregation;
- using SQL as the reproducible evidence foundation;
- using Excel for deep investigation rather than uncontrolled reporting;
- challenging arithmetic, definitions and statistical interpretation;
- separating observed association from causal claims;
- connecting clinical, operational, financial and social variables;
- translating findings into interventions and measurable outcomes.

> **The strongest portfolio message is not “I analyzed a hospital.” It is “I built a defensible analytical path from question to evidence to decision.”**

---

# Repository roadmap

```text
PHA-WAW-001/
├── README.md
├── /governance
├── /sql
├── /excel_evidence
├── /docs
├── /powerbi
├── /images
└── /audit
```

The next implementation stage is the SQL layer: each script will be mapped to its exact question, objective, metrics, grain, DQ logic, joins, evidence output, and corresponding Excel result. No causal statement will be promoted beyond what the SQL evidence can actually support.

---

## Full analytical case study

For the complete pillar-by-pillar reasoning, findings, evidence classification, statistical review gates, and executive narrative, see [`MASTER_ANALYTICAL_CASE_STUDY.md`](docs/MASTER_ANALYTICAL_CASE_STUDY.md).
