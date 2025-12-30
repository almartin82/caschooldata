# Fetch California enrollment data

Downloads and processes enrollment data from the California Department
of Education DataQuest data files. Data is based on Census Day
enrollment (first Wednesday in October).

## Usage

``` r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - e.g., 2024 for
  the 2023-24 school year. Currently supports 2024-2025 (Census Day
  files).

- tidy:

  If TRUE (default), returns data in long (tidy) format with grade and
  subgroup columns. If FALSE, returns wide format with grade columns.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from CDE.

## Value

A tibble with enrollment data. In tidy format, includes columns:

- `end_year`: School year end (integer)

- `cds_code`: 14-digit CDS identifier

- `county_code`: 2-digit county code

- `district_code`: 5-digit district code

- `school_code`: 7-digit school code

- `agg_level`: Aggregation level (T=State, C=County, D=District,
  S=School)

- `county_name`, `district_name`, `school_name`: Entity names

- `charter_status`: Charter indicator (Y/N/All)

- `grade_level`: Grade (TK, K, 01-12, or TOTAL)

- `reporting_category`: CDE demographic category code

- `subgroup`: Human-readable subgroup name

- `n_students`: Enrollment count

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get wide format (one column per grade)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Force fresh download (ignore cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)

# Filter to school-level total enrollment
library(dplyr)
schools <- enr_2024 %>%
  filter(agg_level == "S", reporting_category == "TA", grade_level == "TOTAL")
} # }
```
