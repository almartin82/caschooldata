# Calculate assessment trends over time

Computes year-over-year changes in assessment metrics.

## Usage

``` r
calc_assess_trend(data, metric = "pct_met_and_above")
```

## Arguments

- data:

  Tidy assessment data with multiple years

- metric:

  Performance metric to analyze (default: "pct_met_and_above")

## Value

Data with additional columns for year-over-year changes

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Calculate 5-year trend
multi_year <- fetch_assess_multi(2019:2023, tidy = TRUE) %>%
  id_assess_aggs() %>%
  filter(agg_level == "T",
         grade == "11",
         subject == "ELA")

# Add trend calculations
trend <- calc_assess_trend(multi_year, "pct_met_and_above")

# View change from 2019 to 2023
trend %>%
  filter(end_year %in% c(2019, 2023)) %>%
  select(end_year, metric_value, change, pct_change)
} # }
```
