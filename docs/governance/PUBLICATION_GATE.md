# Publication Gate

## Status: PASS — file-based release gate

### Passed
- [x] SQL artifacts preserved without source-code edits
- [x] Physical schema inventory included
- [x] 17 analytical tables + `sysdiagrams` documented
- [x] Current Pillar 2 no-show totals reconciled to 18,076
- [x] Current Pillar 3 prior-authorization rejection rates reconciled to 7.96% / 8.02%
- [x] Public narrative excludes confidential Board-Safe material
- [x] No raw patient-level data included
- [x] Repository registry and validation documentation included
- [x] Causal/statistical wording hardened in public narrative

### Explicit boundary
This is a **file-based publication gate**. The supplied SQL was not independently executed in this environment because the source SQL Server database/runtime is not part of the uploaded evidence package. Therefore this release does not claim fresh SQL runtime certification.

The original SQL remains the analytical source artifact and is not modified.
