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

  School year end (e.g., 2023 for 2022-23 school year). Supports
  2015-2024. Note: 2020 data may be limited due to COVID-19.

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

- 2020: Limited data (COVID-19 disruptions)

- 2021: Reduced participation

- 2022-2024: Full post-pandemic data

### Data Source:

California CAASPP Smarter Balanced Assessments Portal:
https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB

### Manual Download Required:

The CAASPP portal does not provide publicly documented direct download
URLs. Users must:

1.  Visit the CAASPP Research Files portal

2.  Download statewide research files (caret-delimited format)

3.  Use
    [`import_local_assess()`](https://almartin82.github.io/caschooldata/reference/import_local_assess.md)
    to load the files

4.  This function will then process the data

See `vignette("assessment")` for detailed examples.

## Examples

``` r
if (FALSE) { # \dontrun{
library(caschooldata)
library(dplyr)

# After manually downloading CAASPP files:
local_files <- import_local_assess(
  test_data_path = "~/Downloads/sb_ca_2023_allstudents_csv.txt",
  entities_path = "~/Downloads/entities_2023.txt",
  end_year = 2023
)

# Fetch processed assessment data
assess_2023 <- fetch_assess(
  end_year = 2023,
  local_data = local_files,
  tidy = TRUE
)

# State-level 11th grade proficiency
state_11_prof <- assess_2023 %>%
  filter(agg_level == "T",
         grade == "11",
         metric_type == "pct_met_and_above")

# District-level comparison
district_ela <- assess_2023 %>%
  filter(agg_level == "D",
         grade == "11",
         subject == "ELA",
         metric_type == "pct_met_and_above") %>%
  arrange(desc(metric_value))
} # }
```
