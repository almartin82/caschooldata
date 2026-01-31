# Get raw CAASPP assessment data

Downloads raw CAASPP Smarter Balanced assessment research files from the
ETS CAASPP portal. Data includes test results for grades 3-8 and 11 in
ELA and Mathematics.

## Usage

``` r
get_raw_assess(
  end_year,
  subject = c("Both", "ELA", "Math"),
  student_group = c("ALL", "GROUPS")
)
```

## Arguments

- end_year:

  School year end (e.g., 2023 for 2022-23 school year). Supports
  2015-2025.

- subject:

  Assessment subject: "ELA", "Math", or "Both" (default).

- student_group:

  "ALL" (default) for all students, or "GROUPS" for all student group
  breakdowns.

## Value

List containing:

- `test_data`: Data frame with assessment results

- `entities`: Data frame with entity names and codes

- `year`: School year

- `source_url`: URL where data was downloaded

## Details

### Available Years:

- 2015-2019: Pre-COVID baseline data

- 2020: No statewide testing (COVID-19)

- 2021: Limited data due to pandemic

- 2022-2025: Full post-pandemic data

### File Format:

Statewide research files in caret-delimited format. Files include:

- All counties, districts, and schools

- Grade-level aggregations (3, 4, 5, 6, 7, 8, 11)

- Performance levels (Exceeded, Met, Nearly Met, Not Met)

- Mean scale scores

- Student group breakdowns (if student_group = "GROUPS")

### Data Source:

CAASPP Research Files Portal (ETS):
https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB

## See also

[`process_assess`](https://almartin82.github.io/caschooldata/reference/process_assess.md)
for processing raw data
[`fetch_assess`](https://almartin82.github.io/caschooldata/reference/fetch_assess.md)
for the complete fetch pipeline

## Examples

``` r
if (FALSE) { # \dontrun{
# Download 2024 CAASPP data (both ELA and Math)
raw_2024 <- get_raw_assess(2024)

# Download only ELA results
raw_2024_ela <- get_raw_assess(2024, subject = "ELA")

# Download with student group breakdowns
raw_2024_groups <- get_raw_assess(2024, student_group = "GROUPS")

# Access test results and entity names
test_data <- raw_2024$test_data
entities <- raw_2024$entities
} # }
```
