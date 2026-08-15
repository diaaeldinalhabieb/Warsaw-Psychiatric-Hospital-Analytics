# PHA-WAW-001 — Warsaw Psychiatric Hospital Analytics Program

## Strategic Healthcare Analytics Case Study

> **From raw healthcare data to decision intelligence:** a governed, question-driven analytics program built to connect clinical outcomes, operational capacity, financial performance, and structural vulnerability.

**Project ID:** PHA-WAW-001  
**Environment:** SQL Server / SSMS → Excel Evidence Architecture  
**Analytical Model:** Question → SQL Evidence → Deep Analysis → Statistical Review → Cross-Pillar Synthesis → Executive Recommendation  
**Architecture:** Governed Healthcare Analytics Operating Architecture  
**Scope:** 4 integrated analytical pillars / 17 verified physical tables  

---

## 1. The Project in One Sentence

PHA-WAW-001 is a portfolio-grade healthcare analytics program that demonstrates **how I think as a senior data analyst**: I start with a business/clinical question, translate it into measurable dimensions and hypotheses, use SQL as the evidence and data-preparation layer, move the validated analytical dataset into Excel for deep investigation, stress-test the findings mathematically and statistically, and only then convert the evidence into operational and executive recommendations.

The project is therefore not primarily a dashboard exercise. It is an **analytical reasoning system**.

---

## 2. My Analytical Thinking

The central idea is simple:

> **Do not start with the data that happens to be available. Start with the decision that needs to be improved.**

For every investigation, I use the following reasoning chain:

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
SQL EVIDENCE EXTRACTION
        ↓
EXCEL DEEP ANALYSIS
        ↓
MATHEMATICAL + STATISTICAL + DESCRIPTIVE REVIEW
        ↓
TEMPORAL / CAUSAL STRESS TEST
        ↓
CROSS-PILLAR SYNTHESIS
        ↓
INSIGHT
        ↓
EXECUTIVE DECISION / INTERVENTION
        ↓
RE-MEASUREMENT
```

This ordering matters. It prevents a common analytics failure mode: jumping from a chart to a recommendation without establishing whether the metric is correctly defined, whether the data grain is valid, whether the observed relationship is meaningful, and whether the proposed explanation is actually supported.

---

## 3. Why SQL Comes First and Excel Comes Second

### SQL is the evidence foundation

SQL was used first to:

- inspect the physical schema;
- validate the available tables and fields;
- clean and prepare the analytical data;
- control joins and prevent fan-out / duplicate inflation;
- establish the correct analytical grain;
- create reproducible evidence datasets for each analytical question;
- preserve temporal integrity and prevent future leakage;
- produce question-specific outputs that can be independently traced back to the source.

### Excel is the deep analytical layer

After the SQL evidence layer was established, Excel was used for the **deeper analytical investigation**:

- cohort comparison;
- distributions and segmentation;
- rate and ratio analysis;
- cross-tabulation;
- outlier and anomaly discovery;
- scenario-style comparisons;
- financial aggregation;
- evidence interpretation;
- recommendation development.

The important distinction is:

> **SQL prepares and proves the evidence. Excel interrogates the evidence deeply.**

Excel is therefore not the source of truth. It is the analytical investigation layer built on top of a governed SQL foundation.

---

## 4. Analytical Constitution

The master roadmap defines an evidence-first architecture with five core disciplines:

1. **Evidence First** — no major finding without reproducible evidence.
2. **Default Confidence Zero** — assumptions remain untrusted until supported by data.
3. **Verified Physical Schema** — analysis must remain within the verified executable schema.
4. **Question-Centric Data Quality** — data quality is evaluated against the exact question being answered.
5. **Temporal and Grain Governance** — preserve chronological order, define grain explicitly, and prevent Cartesian duplication.

The roadmap also explicitly separates distribution from causality, sequence from progression, recurrence from severity, and clustering from vulnerability. fileciteturn0file0L19-L35 fileciteturn0file0L38-L53

---

## 5. The Four-Pillar Analytical Architecture

The program organizes the hospital's decision space into four connected analytical pillars. fileciteturn0file0L75-L101

| Pillar | Core Question | Decision Domain |
|---|---|---|
| **P1 — Clinical Outcomes & Care Continuity** | What drives clinical deterioration, stabilization, and recovery? | Clinical strategy |
| **P2 — Operational Efficiency & Capacity Optimization** | Where is capacity being lost and why? | Operations / workforce |
| **P3 — Financial Security & Revenue Cycle Intelligence** | Where is economic value leaking? | Finance / revenue cycle |
| **P4 — SDOH, Biomarkers & Structural Vulnerability** | What structural and biological conditions explain the observed patterns? | Prevention / targeted care |

The analytical value comes from the **connections between pillars**, not from treating them as four unrelated reports.

---

# 6. Pillar 1 — Clinical Outcomes & Care Continuity

Pillar 1 focuses on clinical trajectories, medication response, adverse-event burden, narrative risk, engagement, and longitudinal recovery. fileciteturn0file1L4-L23

## 6.1 ANA-101 — Medication Adherence vs. Crisis Recurrence

**Question:** Does medication adherence level distinguish patients with different crisis burdens?

**Core dimensions:** `Adherence_Rate`, adherence tier, `ER_Visit_Flag`, `Hospitalization_Flag`  
**Primary evidence path:** `Medication_History → Crisis_Events → Patients`

### Observed result

| Adherence tier | Patients | Patients with crisis | Crisis rate |
|---|---:|---:|---:|
| Low <50% | 31,941 | 1,359 | 4.25% |
| Moderate 50–79% | 134,584 | 5,740 | 4.26% |
| High ≥80% | 33,475 | 1,329 | 3.97% |
| **Overall** | **200,000** | **8,428** | **4.214%** |

**Analytical reading:** the high-adherence cohort shows a lower observed crisis rate than the low-adherence cohort. The difference is meaningful enough to justify deeper investigation, but the aggregate table alone does not prove causality.

**Portfolio insight:** the important analytical move was not simply calculating a rate. It was comparing cohorts, checking the correct denominator, translating the difference into an effect-size question, and then asking whether the relationship survives adjustment for baseline risk and time.

---

## 6.2 ANA-102 — Medication Changes, Adverse Effects & Interim Progression

**Question:** Does regimen instability combined with adverse-effect burden relate to interim clinical change?

**Core dimensions:** `Side_Effect_Severity`, `Medication_Change_Flag`, `Interim_Clinical_Score`  
**Evidence path:** `Treatments → Longitudinal_Sessions → Outcomes`  

### Observed result

Among the severe-side-effect cohort, medication change is associated with approximately:

- **−8.78** average net improvement when the regimen was changed;
- **−8.82** when it was not changed;
- **≈ +0.04 points** difference.

The analytical interpretation is **stabilization rather than demonstrated recovery acceleration**. That distinction is important: a small improvement versus deterioration is not the same thing as a positive treatment effect.

---

## 6.3 ANA-103 — Narrative Sentiment vs. Structured Risk

**Question:** Can information contained in clinical notes provide an earlier signal than periodic structured risk assessments?

**Core dimensions:** `Sentiment_Score`, `Self_Harm_Mentions`, `Hallucination_Mentions`, `Suicide_Risk_Score`  
**Evidence path:** `Clinical_Notes → Clinical_Assessments → Patients`

### Analytical reading

The current aggregate evidence does not establish a strong contemporaneous relationship between sentiment tier and structured risk score.

That does **not** make the NLP hypothesis useless. It changes the question:

> Instead of asking whether sentiment and risk score are correlated at the same time, ask whether **a change in narrative risk at time t predicts a change in structured risk or crisis at time t+1**.

The next analytical design should therefore use timestamps and lag structures.

**Status:** high-value hypothesis; longitudinal validation required before calling it predictive.

---

## 6.4 ANA-104 — Digital / Behavioral Engagement vs. Outcome

**Question:** Is stronger digital and behavioral engagement associated with materially different recovery outcomes?

**Core dimensions:** `Homework_Completed`, `App_Usage_Hours`, `Trajectory_Outcome`  
**Evidence path:** `Longitudinal_Sessions → Outcomes`  

### Observed engagement pattern

| Engagement tier | Volume | Full remission | Full remission rate | Avg app usage |
|---|---:|---:|---:|---:|
| High | 112,369 | 34,924 | **31.08%** | 9.17 h |
| Moderate | 61,662 | 1,210 | **1.96%** | 4.72 h |
| Low / Passive | 25,969 | 0 | **0.00%** | 1.60 h |

The result is strategically important because it reveals an exceptionally large **engagement gradient**.

The senior-analyst interpretation is still cautious:

```text
Engagement ↔ Outcome
```

is strongly observed, but

```text
Engagement → Outcome
```

requires longitudinal adjustment for baseline severity, motivation, treatment mix, and selection effects.

---

# 7. Pillar 2 — Operational Efficiency & Capacity Optimization

Pillar 2 examines access friction, non-attendance, workforce load, facility throughput, and authorization latency. fileciteturn0file2L5-L20

## 7.1 ANA-205 — Geography, Access Friction & No-Show

**Question:** How do distance, transport time, wait time and socioeconomic conditions interact to influence attendance?

**Core dimensions:** `Distance_to_Clinic_km`, `Transport_Time_mins`, `Wait_Time_Days`, `Employment_Status`, `Monthly_Income_PLN`, `District`, `Telehealth_Flag`  

### Observed result

The workbook evidence shows:

- **200,000 appointments**;
- **18,076 no-shows**;
- **11.08% remote no-show rate**;
- approximately **70.4 minutes** average remote transport time;
- approximately **21.5 km** average remote distance;
- approximately **6,814** remote missed appointments.

The analytical question is therefore not merely “why are no-shows high?” but:

> **Which friction combination creates the highest preventable capacity loss, and where is telehealth a plausible substitute?**

---

## 7.2 ANA-206 — Workforce Burnout, Sick Leave & Care Continuity

**Question:** How does caseload pressure interact with experience and specialty to influence burnout, sick leave and provider changes?

**Observed high-caseload cohort:**

- **708 / 1,000 clinicians = 70.8%**;
- average caseload ≈ **68.58 cases/week**;
- burnout ≈ **8.06 / 10**;
- sick leave ≈ **15.95 days/provider**;
- reassignment rate ≈ **17.91%**.

**Analytical chain:**

```text
Caseload pressure
      ↓
Burnout / occupational strain
      ↓
Sick leave / staff disruption
      ↓
Provider reassignment
      ↓
Potential continuity disruption
```

This is a hypothesis architecture, not automatic proof of each arrow.

---

## 7.3 ANA-207 — Scheduling Latency vs. Intra-Facility Dwell Time

The roadmap asks two different operational questions that must remain analytically separate:

1. **Scheduling latency** — how long patients wait before the visit.
2. **Intra-facility dwell time** — `Checkout_Timestamp − Checkin_Timestamp` during the visit.

The available evidence strongly supports the first construct:

- **151,842 completed visits**;
- **82,395** in the ≥30-day scheduling-delay tier;
- **54.26%** severe-delay share.

A future SQL evidence set should separately calculate the check-in/check-out dwell measure and the ≥90-minute threshold defined in the pillar blueprint. fileciteturn0file2L52-L67

**Portfolio lesson:** correctly naming the metric is part of analytics. Two time intervals can both be called “delay” while representing completely different operational mechanisms.

---

## 7.4 ANA-208 — Authorization Latency & Financial Leakage

**Question:** How do prior-authorization requirements and approval delays affect cancellations/no-shows, claim rejection, and unrecovered billed revenue?

Observed financial evidence includes:

- **686.90M PLN** total billed;
- **202.83M PLN** direct rejected amount;
- **114.54M PLN** indirect lost-capacity amount;
- **280.75M PLN** combined leakage;
- **157.26M PLN** leakage associated with the severe-wait tier.

The strategic objective is to convert “administrative delay” into a measurable economic mechanism that can inform workflow redesign and payer SLA decisions. fileciteturn0file2L68-L84

---

# 8. Pillar 3 — Financial Security, Value-Based ROCI & Revenue Cycle Intelligence

Pillar 3 explicitly integrates clinical and operational evidence into a value-based financial framework. fileciteturn0file3L5-L22

## 8.1 ANA-301 — Prior Authorization → Denial Cascade

The question is not simply “how many claims were denied?” It is:

> **Where does authorization friction intersect with specialty, scheduling delay, and payer behavior to create recoverability risk?**

The blueprint specifically highlights authorization delay and scheduling latency as interacting risk conditions. fileciteturn0file3L24-L41

---

## 8.2 ANA-302 — Value-Based ROCI

**Question:** What is the financial cost of different treatment/engagement pathways relative to observed clinical outcomes?

Key evidence:

- High engagement: **31.08% full remission**;
- Moderate engagement: **1.96%**;
- Low/passive engagement: **0.00%**;
- Approximate cost per remission: **11,134 PLN** for high engagement versus **172,967 PLN** for moderate engagement.

This creates a powerful portfolio narrative:

> **The most interesting financial question is not “what did the hospital bill?” but “what did the hospital spend per successful clinical outcome?”**

That is the bridge from healthcare reporting to value-based analytics.

The blueprint positions this module specifically as a cost-efficacy / ROCI bridge between financial and clinical performance. fileciteturn0file3L46-L61

---

## 8.3 ANA-303 — Audit Vulnerability, Provider Handoffs & Documentation

The project tests whether provider reassignment, workforce pressure, negative documentation signals and high-billed treatment intersect with appeals, partial payments and fraud-investigation flags.

Current evidence supports **plausibility of the pathway**, but not a simple independent causal effect of provider handoff on audit exposure.

That restraint is intentional. A senior analyst should not turn a compelling story into a causal statement until the data design supports it.

---

## 8.4 ANA-304 — Acute Crisis Financial Hemorrhage

**Observed scale:**

- **8,428 crisis events**;
- **4,228 hospitalizations**;
- approximately **33.90% ER claim-rejection rate** in the relevant billed-amount view.

The analytical value is in translating clinical deterioration into financial language:

```text
Access / continuity failure
        ↓
Acute decompensation
        ↓
ER / hospitalization
        ↓
Higher-cost care
        ↓
Payer and revenue-cycle exposure
```

The strategic goal is to identify where earlier outpatient intervention could prevent expensive acute utilization.

---

# 9. Pillar 4 — SDOH, Biomarkers & Structural Vulnerability

Pillar 4 is the program's **root-cause engine**: it is designed to explain why certain clinical, operational and financial patterns concentrate in specific cohorts. fileciteturn0file4L4-L17

## 9.1 ANA-401 — Housing, Income & Transit Friction

The module combines:

`Housing_Instability + Income + Distance + Transport Time + Wait Time + Attendance`

The analytical objective is to identify **high-friction cohorts**, not to reduce access problems to a single demographic variable. fileciteturn0file4L36-L52

The next SQL stage should explicitly join patient-level SDOH variables to appointment-level access variables so that the full mechanism can be evaluated at the correct grain.

---

## 9.2 ANA-402 — Social Capital as a Buffer

Pillar 4 connects social support to digital engagement and outcomes. The headline evidence includes:

- **25,969 passive-engagement patients**;
- **0% full remission** in that cohort;
- high-engagement pathway at **31.08% full remission**;
- approximately **11,134 PLN** per full remission in the high-engagement group.

The more sophisticated hypothesis is:

```text
Social support
      ↓
Engagement capacity
      ↓
Treatment participation
      ↓
Outcome
```

rather than assuming a direct support → outcome relationship.

---

## 9.3 ANA-403 — Neurobiological Stress, Trauma & Treatment Resistance

The module combines CRP, sleep, genetic risk, wearable stress, trauma history, medication changes and treatment outcomes. The blueprint proposes high-stress markers such as `CRP > 3.0 mg/L` and `Sleep < 5 hours` as candidate risk strata. fileciteturn0file4L74-L92

The current evidence supports the **investigation direction** but does not independently prove that those markers cause treatment resistance.

---

## 9.4 ANA-404 — Immigrant Vulnerability, Narrative Discordance & Crisis Risk

The analytical concept combines:

`Immigration status + social isolation + clinical-note NLP + structured risk + crisis events`

The key question is temporal:

> Does a deterioration in narrative signals occur **before** measurable structured risk escalation or acute crisis?

The blueprint explicitly frames this as a proactive crisis-prediction problem. fileciteturn0file4L93-L111

That requires timestamped longitudinal evidence before the model can be operationalized as a prediction layer.

---

# 10. Cross-Pillar Integration — The Real Story

The project's strongest contribution is the integrated mechanism:

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

This integrated chain is consistent with the master architecture and the explicit cross-pillar dependencies defined in the roadmap and pillar blueprints. fileciteturn0file0L97-L101 fileciteturn0file2L85-L106 fileciteturn0file4L112-L171

---

# 11. The Questions Behind the Numbers

A strong portfolio should make the analytical questions visible before the charts.

| Domain | Example question | Key measures | Decision |
|---|---|---|---|
| Clinical | Which adherence cohorts carry more crisis risk? | adherence, crisis rate, hospitalization | outreach threshold |
| Clinical | Which treatment pathways stabilize vs. improve? | side effects, med change, interim score | regimen review |
| NLP | Does narrative deterioration precede crisis? | sentiment, mentions, lagged risk | early-warning design |
| Digital | Where does engagement separate outcomes? | app use, homework, remission | digital pathway |
| Operations | Where is capacity lost? | no-show, wait, distance | access redesign |
| Workforce | Where does workload become unsafe? | caseload, burnout, sick leave | capacity / staffing |
| Finance | Where is money not recovered? | billed, rejected, leakage | revenue control |
| Value | Which pathway buys more recovery per PLN? | cost/remission, outcome | resource allocation |
| SDOH | Which structural factors amplify friction? | income, housing, isolation, transit | targeted support |
| Biology | Which biological signals modify treatment response? | CRP, sleep, stress | precision pathway |

---

# 12. Statistical & Analytical Review Gates

Every stage is reviewed before the next one begins.

## Gate 1 — Language & definition

- Is the metric named correctly?
- Is the numerator explicit?
- Is the denominator explicit?
- Are “rate”, “share”, “average”, “volume”, and “risk” being used correctly?

## Gate 2 — Mathematical integrity

- Recalculate totals independently.
- Use weighted rates where appropriate.
- Reconcile components to totals.
- Check units and scale (%, PLN, days, patients, visits, claims).

## Gate 3 — Data grain

Every analysis must declare whether its row is a:

`patient | appointment | session | treatment | claim | provider | patient-period`

Mixed-grain joins must be deliberate and protected against duplication.

## Gate 4 — Statistical integrity

Model choice must match the outcome:

- binary outcomes → logistic / related generalized models;
- counts → Poisson / negative-binomial where appropriate;
- time-to-event → survival analysis;
- repeated measures → mixed-effects / clustered approaches;
- continuous outcomes → appropriate linear / generalized models.

## Gate 5 — Temporal integrity

For predictive statements:

```text
feature_time < outcome_time
```

No future leakage.

## Gate 6 — Causal integrity

The vocabulary is deliberate:

| Evidence strength | Language |
|---|---|
| Descriptive | “observed”, “higher”, “lower”, “concentrated” |
| Associational | “associated with”, “correlated with” |
| Predictive | “predicts”, only after temporal/model validation |
| Causal | “caused”, only when the study design supports identification |

## Gate 7 — Reproducibility

Every executive metric should be traceable through:

`Metric_ID → Question_ID → SQL_ID → Grain → Temporal Anchor → Join Keys → DQ → Evidence → Excel Analysis → Recommendation`

This aligns with the roadmap's traceability requirement. fileciteturn0file0L251-L263

---

# 13. Evidence Classification

| Class | Meaning |
|---|---|
| **E1 — Recomputed** | Independently calculated from source workbook aggregates or SQL evidence |
| **E2 — Workbook-supported** | Explicitly reported by the analysis workbook and reconciled to the surrounding evidence |
| **H1 — Analytical hypothesis** | Plausible mechanism defined by the roadmap and tested by the project |
| **H2 — Causal / predictive claim pending validation** | Requires longitudinal, multivariable or quasi-experimental evidence |

Examples of strong current E1/E2 signals include the **4.214% overall crisis rate**, **70.8% high-caseload concentration**, **54.26% severe scheduling-delay share**, **280.75M PLN combined leakage**, and **31.08% high-engagement full-remission rate**.

---

# 14. SQL Evidence Architecture

The next portfolio layer will expose the SQL code used to answer each question.

Recommended structure:

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

The filenames above define the **portfolio organization**, not unverified SQL content. The actual code will be incorporated and audited question-by-question when attached.

---

# 15. Excel Evidence Architecture

Each pillar workbook functions as an analytical investigation pack.

The preferred reading sequence is:

```text
SQL Evidence
   ↓
Workbook Input / Output Table
   ↓
Cohort Definition
   ↓
Metric Construction
   ↓
Comparison
   ↓
Anomaly / Pattern
   ↓
Statistical Check
   ↓
Interpretation
   ↓
Recommendation
```

This makes the workbook more than a spreadsheet: it becomes the **evidence notebook** for the analytical question.

---

# 16. Executive KPI System

The executive layer should stay compact and decision-oriented.

| KPI | Pillar | Role |
|---|---|---|
| Overall crisis rate | P1 | Clinical safety baseline |
| High vs. low adherence crisis delta | P1 | Risk gradient |
| Full-remission rate by engagement tier | P1/P3 | Outcome / value |
| High-caseload concentration | P2 | Workforce risk |
| Burnout index | P2 | Workforce sustainability |
| Provider reassignment rate | P1/P2 | Continuity risk |
| Remote no-show rate | P2/P4 | Access friction |
| Severe wait share | P2 | Operational bottleneck |
| Combined leakage (PLN) | P2/P3 | Financial control |
| Severe-wait leakage share | P2/P3 | Priority recovery target |
| Claim rejection by authorization status | P3 | Payer process effectiveness |
| Cost per successful remission | P3 | Value-based allocation |
| High audit-risk volume | P3 | Compliance exposure |
| Narrative-risk lag to crisis | P1/P4 | Predictive validation |
| Structural vulnerability profile | P4 | Targeted intervention |

---

# 17. Executive Recommendation Logic

Recommendations are not generated directly from averages. They are generated from **measurable mechanisms**.

### Example 1 — Access

```text
High friction cohort
→ high no-show
→ lost capacity
→ possible telehealth diversion
→ measure attendance + outcome after intervention
```

### Example 2 — Workforce

```text
High caseload
→ burnout / sick leave
→ reassignment risk
→ continuity disruption
→ workload threshold + staffing redesign
```

### Example 3 — Revenue Cycle

```text
Authorization latency
→ scheduling friction
→ claim rejection / unrecovered revenue
→ payer SLA + workflow automation
```

### Example 4 — Digital care

```text
Low engagement
→ near-zero remission in observed passive cohort
→ identify engagement barrier
→ caregiver / peer / digital support
→ measure sustained engagement + outcome + cost
```

---

# 18. Why This Is a Senior-Level Portfolio Project

The project demonstrates more than technical execution.

### Analytical thinking

I did not begin with “What can I plot?” I began with:

> **What decision is hidden inside this dataset?**

### Data engineering discipline

The analytical evidence was prepared in SQL before deeper analysis was performed.

### Metric discipline

Rates, counts, averages, leakage, cost-per-outcome and time intervals are treated as distinct analytical objects.

### Statistical skepticism

Large datasets can make tiny differences look impressive. The project therefore distinguishes **magnitude**, **uncertainty**, **statistical significance**, **clinical relevance**, and **causality**.

### Cross-domain reasoning

The strongest insights do not live inside one table. They emerge from the relationship between:

`Clinical + Operations + Finance + SDOH`

### Recommendation discipline

The final question is always:

> **What should management do differently because of this evidence?**

---

# 19. Portfolio Presentation Strategy

## GitHub

The README should function as the **analytical narrative**, not as a copy of every workbook finding.

Recommended GitHub order:

```text
1. Executive problem
2. Analytical thinking
3. SQL → Excel workflow
4. Four-pillar architecture
5. Key findings
6. Cross-pillar story
7. Review / governance gates
8. SQL structure
9. Evidence workbooks
10. Business impact
```

The detailed tables, screenshots and extended statistical output should live in dedicated `/docs`, `/evidence`, and `/excel_evidence` folders.

## LinkedIn

LinkedIn should **not** receive the full README.

The strongest LinkedIn format is a short case-study narrative or carousel built around:

```text
Problem → How I thought → What SQL uncovered → What deep analysis found →
One or two high-value insights → Business implication → GitHub link
```

The README is the evidence hub. LinkedIn is the attention hook.

---

# 20. Recommended Repository Structure

```text
PHA-WAW-001/
├── README.md
├── /governance
│   ├── analytics_constitution.md
│   ├── data_dictionary.md
│   ├── metric_registry.md
│   └── methodology.md
├── /sql
│   ├── pillar_1_clinical/
│   ├── pillar_2_operations/
│   ├── pillar_3_finance/
│   ├── pillar_4_sdoh/
│   └── /shared
├── /excel_evidence
│   ├── pillar_1/
│   ├── pillar_2/
│   ├── pillar_3/
│   └── pillar_4/
├── /docs
│   ├── pillar_1/
│   ├── pillar_2/
│   ├── pillar_3/
│   ├── pillar_4/
│   └── integrated_findings.md
├── /powerbi
├── /images
└── /audit
```

---

# 21. Final Analytical Position

PHA-WAW-001 is best presented as an **end-to-end analytical decision system**, not as a collection of Excel sheets.

Its strongest portfolio message is:

> **I transformed a complex healthcare schema into a sequence of business and clinical questions, built reproducible SQL evidence for each question, performed deep cross-sectional and longitudinal analysis in Excel, stress-tested the mathematics and statistical interpretation, connected four analytical pillars into one causal hypothesis architecture, and translated the evidence into executive actions.**

The resulting framework is:

```text
Question
  ↓
Definition
  ↓
SQL
  ↓
Evidence
  ↓
Deep Analysis
  ↓
Statistical Review
  ↓
Causal Stress Test
  ↓
Cross-Pillar Insight
  ↓
Decision
  ↓
Measure Again
```

That is the part of the project that should command attention from **HR reviewers, data analysts, analytics managers, and hiring teams**: not merely that the project contains healthcare metrics, but that it demonstrates a disciplined way of thinking from question formulation to defensible decision-making.

---

## 22. Methodology Note

The master roadmap defines the verified physical schema and governance lifecycle; the pillar PDFs define the analytical questions, objectives, hypotheses and intended cross-pillar logic; the Excel workbooks provide the observed analytical evidence. fileciteturn0file0L54-L71 fileciteturn0file0L251-L263

The README intentionally distinguishes:

- **what is observed**;
- **what is associated**;
- **what is hypothesized**;
- **what still requires longitudinal or causal validation**.

That distinction is part of the analytical method, not a limitation of the project.
