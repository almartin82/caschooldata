# Tidy CAASPP assessment data

Converts processed CAASPP assessment data from wide format to tidy
(long) format. Pivots performance metrics into separate rows for easier
analysis.

## Usage

``` r
tidy_assess(processed_data)
```

## Arguments

- processed_data:

  Processed assessment data from process_assess()

## Value

A tibble in tidy format with columns:

- `end_year`: School year end

- `cds_code`: 14-digit CDS identifier

- `county_code`, `district_code`, `school_code`: CDS components

- `agg_level`: Aggregation level (S/D/C/T)

- `grade`: Grade level (03-11 or 13)

- `subject`: Assessment subject (ELA/Math)

- `metric_type`: Type of metric (mean_scale_score, pct_exceeded, etc.)

- `metric_value`: Value of the metric

## Details

### Tidy Format Structure:

The tidy format converts performance metrics from separate columns into
rows, making it easier to:

- Filter and plot by metric type

- Compare metrics across years

- Calculate differences between metrics

- Join with other datasets

### Metric Types:

- `mean_scale_score`: Average scale score for the test

- `pct_exceeded`: Percentage of students who exceeded standard

- `pct_met`: Percentage of students who met standard

- `pct_met_and_above`: Percentage who met or exceeded standard

- `pct_nearly_met`: Percentage who nearly met standard

- `pct_not_met`: Percentage who did not meet standard

- `n_tested`: Number of students tested

- `n_exceeded`: Number of students who exceeded standard

- `n_met`: Number of students who met standard

- `n_met_and_above`: Number who met or exceeded standard

- `n_nearly_met`: Number of students who nearly met standard

- `n_not_met`: Number of students who did not meet standard

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Process and tidy assessment data
raw <- get_raw_assess(2023)
processed <- process_assess(raw$test_data, 2023)
tidy <- tidy_assess(processed)

# Filter to state-level proficiency rates
state_proficiency <- tidy %>%
  filter(agg_level == "T",
         metric_type %in% c("pct_met_and_above", "pct_exceeded"))

# Compare ELA vs Math performance
subject_comparison <- tidy %>%
  filter(agg_level == "T",
         grade == "11",
         metric_type == "pct_met_and_above") %>%
  select(grade, subject, metric_value)
} # }
```
