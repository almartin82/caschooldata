# Fetch CAASPP assessment data for multiple years

Convenience function to download assessment data for multiple years at
once. Note: 2020 is automatically excluded (no statewide testing due to
COVID-19).

## Usage

``` r
fetch_assess_multi(
  years,
  tidy = TRUE,
  subject = c("Both", "ELA", "Math"),
  student_group = c("ALL", "GROUPS"),
  local_data_list = NULL,
  use_cache = TRUE
)
```

## Arguments

- years:

  Vector of school year ends (e.g., c(2019, 2021, 2022))

- tidy:

  If TRUE (default), returns tidy format

- subject:

  Assessment subject: "Both" (default), "ELA", or "Math"

- student_group:

  "ALL" (default) or "GROUPS"

- local_data_list:

  Named list of local data for each year

- use_cache:

  If TRUE (default), uses cache when available

## Value

Combined tibble with data for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2019-2024 assessment data (2020 automatically excluded)
assess_multi <- fetch_assess_multi(
  years = 2019:2024,
  tidy = TRUE
)

# Calculate multi-year trend
library(dplyr)

state_trend <- assess_multi %>%
  filter(agg_level == "T",
         grade == "11",
         subject == "ELA",
         metric_type == "pct_met_and_above") %>%
  select(end_year, metric_value) %>%
  mutate(
    change = metric_value - lag(metric_value),
    pct_change = (metric_value / lag(metric_value) - 1) * 100
  )
} # }
```
