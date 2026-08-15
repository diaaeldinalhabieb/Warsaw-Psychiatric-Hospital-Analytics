# Metric Definitions

## Current release definitions

### No-show rate
`No-Show Count / Total Scheduled Appointments` within the same cohort.

### Gross rejection rate
`Rejected Claims / Total Claims` within the same authorization/payer cohort.

### Gross rejected PLN
Billed PLN attached to claims flagged as rejected in the supplied analytical output. It is not treated as a finalized write-off.

### Cost per Full Remission
`Total Billed Treatment Cost / Observed Full Remission Count`.

This is a cost-efficiency measure. It is not presented as conventional accounting ROI.

### High Digital & Behavioral Engagement
Definitions are artifact-specific. The repository does not silently merge thresholds used by different SQL investigations. The threshold used by each query/workbook remains the governing definition for that artifact.

## Interpretation rule

A metric may be mathematically correct while still requiring cautious interpretation. Rates and cohort differences are not automatically causal or statistically significant.
