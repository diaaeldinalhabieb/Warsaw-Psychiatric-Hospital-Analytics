# Analytical Governance

PHA-WAW-001 follows a closed, evidence-first review model.

1. **Source integrity** — preserve the supplied SQL artifacts; do not mutate tested SQL based on static observations alone.
2. **Schema grounding** — use the supplied physical schema inventory for column/type checks.
3. **Grain control** — every analytical artifact declares an intended grain.
4. **Join control** — review joins for fan-out risk; do not infer an error merely from type differences.
5. **Mathematical review** — validate numerators, denominators, rates, weighted totals, and scenario arithmetic from the supplied analytical outputs.
6. **Cross-artifact reconciliation** — downstream narrative must match the current evidence workbooks.
7. **Statistical discipline** — descriptive evidence is not promoted to statistical significance without an explicit test.
8. **Causal discipline** — association, sequence, and clustering are not treated as causality without a design that supports causal inference.
9. **Publication safety** — no patient-level data or confidential board material is published.
10. **No silent mutation** — any future SQL change requires before/after runtime comparison against the source environment.

### Source-of-truth hierarchy for this release

`Physical schema inventory → supplied SQL artifacts → current analytical workbooks → public narrative`

The SQL is preserved exactly as supplied. The release correction performed in this package is downstream narrative reconciliation, not SQL mutation.
