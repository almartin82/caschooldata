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
  the 2023-24 school year. Supports 1982-2025:

  - 2024-2025: Modern Census Day files with full demographic breakdowns

  - 2008-2023: Historical files with race/gender data and entity names

  - 1994-2007: Historical files with race/gender data (no entity names)

  - 1982-1993: Historical files with letter-based race codes

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

- `grade_level`: Grade (TK, K, 01-12, or TOTAL). Note: TK is NA for
  1982-2023.

- `reporting_category`: CDE demographic category code

- `subgroup`: Human-readable subgroup name

- `n_students`: Enrollment count

## Details

Historical data differs from modern (2024+) data in several ways:

- Transitional Kindergarten (TK) data is not available (grade_tk is NA)

- Charter status is not available (charter_status is "All")

- District and county aggregates are computed from school-level data

- Student group categories (SG\_\*) are not available

- For 1994-2007: Entity names are not available (use CDS code to look
  up)

- For 1982-1993: Race categories use different coding (mapped to modern
  codes)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get historical data (2019-20 school year)
enr_2020 <- fetch_enr(2020)

# Get data from the 1990s
enr_1995 <- fetch_enr(1995)

# Get wide format (one column per grade)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Force fresh download (ignore cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)

# Filter to school-level total enrollment
library(dplyr)
schools <- enr_2024 |>
  filter(agg_level == "S", reporting_category == "TA", grade_level == "TOTAL")
} # }
```
