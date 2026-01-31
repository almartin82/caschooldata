# Fetch California CAASPP assessment data

Downloads and processes CAASPP Smarter Balanced assessment data from the
California Department of Education. Includes test results for grades 3-8
and 11 in ELA and Mathematics.

## Usage

``` r
fetch_assess(
  end_year,
  tidy = TRUE,
  subject = c("Both", "ELA", "Math"),
  student_group = c("ALL", "GROUPS"),
  local_data = NULL,
  use_cache = TRUE
)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year). Supports
  2015-2025. Note: 2020 had no statewide testing due to COVID-19.

- tidy:

  If TRUE (default), returns data in long (tidy) format with metric_type
  and metric_value columns. If FALSE, returns wide format with separate
  columns for each metric.

- subject:

  Assessment subject to fetch: "Both" (default), "ELA", or "Math"

- student_group:

  "ALL" (default) for all students aggregate, or "GROUPS" for all
  student group breakdowns (demographics, EL status, etc.)

- local_data:

  Optional local data from
  [`import_local_assess()`](https://almartin82.github.io/caschooldata/reference/import_local_assess.md)
  to use instead of downloading. Use this when you have manually
  downloaded CAASPP files from the portal.

- use_cache:

  If TRUE (default), uses locally cached data when available

## Value

A tibble with assessment data. In tidy format, includes columns:

- `end_year`: School year end (integer)

- `cds_code`: 14-digit CDS identifier

- `county_code`, `district_code`, `school_code`: CDS components

- `agg_level`: Aggregation level (S=School, D=District, C=County,
  T=State)

- `grade`: Grade level (03, 04, 05, 06, 07, 08, 11, or 13 for all
  grades)

- `subject`: Assessment subject (ELA or Math)

- `metric_type`: Type of metric (only in tidy format)

- `metric_value`: Value of the metric (only in tidy format)

## Details

### Available Years:

- 2015-2019: Pre-COVID baseline data

- 2020: No statewide testing (COVID-19)

- 2021: Reduced participation

- 2022-2025: Full post-pandemic data

### Data Source:

California CAASPP Smarter Balanced Assessments Portal:
https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB

## Examples

``` r
if (FALSE) { # \dontrun{
library(caschooldata)
library(dplyr)

# Fetch 2024 assessment data
assess_2024 <- fetch_assess(end_year = 2024, tidy = TRUE)

# State-level 11th grade proficiency
state_11_prof <- assess_2024 %>%
  filter(agg_level == "T",
         grade == "11",
         metric_type == "pct_met_and_above")

# District-level comparison
district_ela <- assess_2024 %>%
  filter(agg_level == "D",
         grade == "11",
         subject == "ELA",
         metric_type == "pct_met_and_above") %>%
  arrange(desc(metric_value))
} # }
```
