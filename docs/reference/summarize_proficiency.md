# Calculate assessment proficiency summary

Creates a summary table of proficiency metrics for easy comparison.

## Usage

``` r
summarize_proficiency(data, metric = "pct_met_and_above")
```

## Arguments

- data:

  Tidy assessment data

- metric:

  Performance metric to summarize (default: "pct_met_and_above")

## Value

Summary tibble with proficiency rates by entity, grade, and subject

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Summarize state proficiency rates
tidy <- tidy_assess(processed_data) %>%
  id_assess_aggs()

state_summary <- summarize_proficiency(tidy, "pct_met_and_above") %>%
  filter(is_state)

# Compare 11th grade ELA vs Math
comparison <- tidy %>%
  filter(grade == "11",
         agg_level == "T") %>%
  summarize_proficiency("pct_met_and_above") %>%
  select(grade, subject, metric_value)
} # }
```
