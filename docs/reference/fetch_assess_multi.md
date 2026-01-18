# Fetch CAASPP assessment data for multiple years

Convenience function to download assessment data for multiple years at
once.

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

  Vector of school year ends (e.g., c(2019, 2020, 2021))

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
# Get 2019-2023 assessment data
assess_multi <- fetch_assess_multi(
  years = 2019:2023,
  tidy = TRUE
)

# Calculate 5-year trend
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
