# California School Data Expansion Research

**Last Updated:** 2026-01-04 **Theme Researched:** Graduation

## Executive Summary

California DOE provides comprehensive graduation rate data through three
main data products: 1. **Adjusted Cohort Graduation Rate (ACGR)** -
4-year graduation rates (2017-2025) 2. **Five-Year Cohort Graduation
Rate (FYCGR)** - 5-year graduation rates (2018-2025) 3. **One-Year
Graduate Counts** - Annual graduate counts (2018-2025)

All files are directly downloadable using httr with proper User-Agent
headers. The WAF blocks curl without headers but httr works fine.

## Data Sources Found

### Source 1: Adjusted Cohort Graduation Rate (ACGR)

- **URL Pattern:**
  `https://www3.cde.ca.gov/demo-downloads/acgr/acgr{YY}.txt`
- **HTTP Status:** 200 (requires User-Agent header via httr; curl
  without headers gets 303 redirect to WAF)
- **Format:** Tab-delimited text (TXT)
- **Years Available:** 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024,
  2025
- **Access Method:** Direct download with httr and User-Agent header
- **File Sizes:** 15-37 MB per year

**URL Variations by Year:** \| Year \| Filename \| \|——\|———-\| \| 2025
\| acgr25.txt \| \| 2024 \| acgr24.txt \| \| 2023 \| acgr23-v2.txt \| \|
2022 \| acgr22-v3.txt \| \| 2021 \| acgr21.txt \| \| 2020 \| acgr20.txt
\| \| 2019 \| acgr19.txt \| \| 2018 \| acgr18.txt \| \| 2017 \|
acgr17.txt \|

### Source 2: Five-Year Cohort Graduation Rate (FYCGR)

- **URL Pattern:**
  `https://www3.cde.ca.gov/demo-downloads/fycgr/fycgr{YY}.txt`
- **HTTP Status:** 200 (same access requirements as ACGR)
- **Format:** Tab-delimited text (TXT)
- **Years Available:** 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025
- **Access Method:** Direct download with httr and User-Agent header
- **File Sizes:** 14-42 MB per year

**URL Variations by Year:** \| Year \| Filename \| \|——\|———-\| \| 2025
\| fycgr25.txt \| \| 2024 \| fycgr24.txt \| \| 2023 \| fycgr23.txt \| \|
2022 \| fycgr22-v2.txt \| \| 2021 \| fycgr21.txt \| \| 2020 \|
fycgr20.txt \| \| 2019 \| fycgr19.txt \| \| 2018 \| fycgr18.txt \|

### Source 3: One-Year Graduate Counts (Excel)

- **URL Pattern:**
  `https://www.cde.ca.gov/ds/ad/documents/graduates{YYYY}.xlsx`
- **HTTP Status:** 200 (no special headers required)
- **Format:** Excel (XLSX)
- **Years Available:** 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025
- **Access Method:** Direct download
- **File Sizes:** ~1.8 MB per year

**URL Examples:** \| Year \| Filename \| \|——\|———-\| \| 2025 \|
graduates2425.xlsx \| \| 2024 \| graduates2324.xlsx \| \| 2019 \|
graduates1819.xlsx \|

## Schema Analysis

### ACGR Column Names (2024)

36 columns total:

| Column Name                                            | Type    | Description                                         |
|--------------------------------------------------------|---------|-----------------------------------------------------|
| AcademicYear                                           | Text    | “2023-24” format                                    |
| AggregateLevel                                         | Code    | T=State, C=County, D=District, S=School             |
| CountyCode                                             | Text    | 2-digit county code                                 |
| DistrictCode                                           | Numeric | 5-digit district code (NA for state/county)         |
| SchoolCode                                             | Text    | 7-digit school code (NA for aggregates)             |
| CountyName                                             | Text    | County name                                         |
| DistrictName                                           | Text    | District name                                       |
| SchoolName                                             | Text    | School name                                         |
| CharterSchool                                          | Code    | All/Y/N                                             |
| DASS                                                   | Code    | Dashboard Alternative School Status (All/Y/N)       |
| ReportingCategory                                      | Code    | Demographic subgroup code                           |
| CohortStudents                                         | Numeric | Cohort size (adjusted)                              |
| Regular HS Diploma Graduates (Count)                   | Numeric | Graduate count                                      |
| Regular HS Diploma Graduates (Rate)                    | Numeric | Graduation rate (%)                                 |
| Met UC/CSU Grad Req’s (Count)                          | Numeric | A-G completion count                                |
| Met UC/CSU Grad Req’s (Rate)                           | Numeric | A-G completion rate                                 |
| Seal of Biliteracy (Count)                             | Numeric | Biliteracy seal count                               |
| Seal of Biliteracy (Rate)                              | Numeric | Biliteracy seal rate                                |
| Golden State Seal Merit Diploma (Count)                | Numeric | Merit diploma count                                 |
| Golden State Seal Merit Diploma (Rate)                 | Numeric | Merit diploma rate                                  |
| Graduates Meeting Local Requirements Exemption (Count) | Numeric | NEW in 2024                                         |
| Graduates Meeting Local Requirements Exemption (Rate)  | Numeric | NEW in 2024                                         |
| CPP Completer (Count)                                  | Numeric | CA Proficiency Program (renamed from CHSPE in 2024) |
| CPP Completer (Rate)                                   | Numeric | CPP rate                                            |
| Adult Ed. HS Diploma (Count)                           | Numeric | Adult ed completion                                 |
| Adult Ed. HS Diploma (Rate)                            | Numeric | Adult ed rate                                       |
| SPED Certificate (Count)                               | Numeric | Special ed certificate                              |
| SPED Certificate (Rate)                                | Numeric | SPED certificate rate                               |
| GED Completer (Count)                                  | Numeric | GED/equivalency count                               |
| GED Completer (Rate)                                   | Numeric | GED rate                                            |
| Other Transfer (Count)                                 | Numeric | Transfer count                                      |
| Other Transfer (Rate)                                  | Numeric | Transfer rate                                       |
| Dropout (Count)                                        | Numeric | Dropout count                                       |
| Dropout (Rate)                                         | Numeric | Dropout rate                                        |
| Still Enrolled (Count)                                 | Numeric | 5th year senior count                               |
| Still Enrolled (Rate)                                  | Numeric | Still enrolled rate                                 |

### Schema Changes Noted

| Year | Change                                                         |
|------|----------------------------------------------------------------|
| 2024 | Added “Graduates Meeting Local Requirements Exemption” columns |
| 2024 | Renamed “CHSPE Completer” to “CPP Completer”                   |
| 2017 | Baseline year - 34 columns                                     |

### Reporting Category Codes

| Code               | Description                     |
|--------------------|---------------------------------|
| **Race/Ethnicity** |                                 |
| RA                 | Asian                           |
| RB                 | African American/Black          |
| RD                 | Two or More Races               |
| RF                 | Filipino                        |
| RH                 | Hispanic/Latino                 |
| RI                 | American Indian/Alaska Native   |
| RP                 | Pacific Islander                |
| RT                 | Not Reported                    |
| RW                 | White                           |
| **Gender**         |                                 |
| GF                 | Female                          |
| GM                 | Male                            |
| GX                 | Non-Binary                      |
| **Student Groups** |                                 |
| SD                 | Students with Disabilities      |
| SE                 | English Learners                |
| SF                 | Foster Youth                    |
| SH                 | Homeless                        |
| SM                 | Migrant                         |
| SS                 | Socioeconomically Disadvantaged |
| **Total**          |                                 |
| TA                 | Total All Students              |

### ID System

- **County Code:** 2-digit (e.g., “19” for Los Angeles County)
- **District Code:** 5-digit numeric
- **School Code:** 7-digit (character to preserve leading zeros)
- **CDS Code:** 14-digit composite (County + District + School)
- Note: State level uses CountyCode=“00”, District/School codes are NA

### Known Data Issues

1.  **Privacy Suppression:** Values suppressed with `*` when cohort size
    \<= 10 students
    - 2023-24: ~59,835 rows have suppressed values (52% of all rows)
    - Suppression applies to all rate columns when any group is
      suppressed
2.  **WAF Blocking:** Direct curl requests blocked by Web Application
    Firewall
    - Solution: Use httr with User-Agent header
    - Example: `httr::GET(url, user_agent("Mozilla/5.0 ..."))`
3.  **File Version Suffixes:** Some years have version suffixes (v2, v3)
    - Must enumerate actual URLs, not assume pattern
4.  **Column Name Typo:** “Golden State Seal Merit Diploma (Rate” is
    missing closing parenthesis

## FYCGR Schema Differences

The Five-Year Cohort file has different columns:

| FYCGR Column                | Notes                                   |
|-----------------------------|-----------------------------------------|
| ReportingYear               | Instead of AcademicYear                 |
| Cohort Students             | Space instead of no space               |
| Non-Graduate Completers     | Combines CHSPE/CPP, Adult Ed, SPED, GED |
| Transfers                   | Year 5 transfers                        |
| Dropouts and Non-Completers | Combined dropout measure                |

Missing from FYCGR (present in ACGR): - Still Enrolled columns -
Detailed outcome breakdowns (CHSPE, Adult Ed, etc.)

## Time Series Heuristics

### State Total Enrollment

| Year    | Cohort Size | Graduates | Rate  |
|---------|-------------|-----------|-------|
| 2016-17 | 493,795     | 408,124   | 82.7% |
| 2023-24 | 506,803     | 438,065   | 86.4% |

**Expected Ranges:** - State cohort: 480,000 - 520,000 students - State
graduation rate: 82% - 88% - YoY change: \< 2 percentage points

### Entity Counts

| Level        | 2016-17 | 2023-24 |
|--------------|---------|---------|
| Districts    | 1,499   | 1,489   |
| Schools (TA) | 5,460   | 2,789   |

Note: School count decreased significantly - likely due to reporting
changes, not actual closures.

### Major Districts (2023-24)

| District              | Cohort | Rate  |
|-----------------------|--------|-------|
| Los Angeles Unified   | 41,955 | 88.5% |
| Kern High             | 11,029 | 86.7% |
| San Diego Unified     | 8,563  | 86.4% |
| Sweetwater Union High | 7,149  | 88.8% |
| Long Beach Unified    | 5,538  | 82.9% |

**Verification Values for Fidelity Tests:** - LA Unified 2023-24: 41,955
cohort, 88.5% rate - San Diego Unified 2023-24: 8,563 cohort, 86.4%
rate - State Total 2023-24: 506,803 cohort, 86.4% rate

## Recommended Implementation

### Priority: HIGH

### Complexity: MEDIUM

### Estimated Files to Create/Modify: 6-8

### Implementation Steps

1.  **Create get_raw_grad.R**
    - `get_raw_grad(end_year, type = c("acgr", "fycgr", "counts"))`
    - Handle URL version suffixes per year
    - Use httr with User-Agent for downloads
    - Support ACGR (2017+), FYCGR (2018+), counts (2018+)
2.  **Create process_grad.R**
    - Standardize column names across years
    - Handle CHSPE -\> CPP rename
    - Handle 2024+ new columns
    - Convert rates to numeric (handle `*` suppression)
3.  **Create tidy_grad.R**
    - Pivot outcomes to long format
    - Create consistent subgroup mapping
    - Add computed columns (4yr vs 5yr indicator)
4.  **Create fetch_grad.R**
    - `fetch_grad(end_year, type = "acgr", tidy = TRUE, use_cache = TRUE)`
    - Parallel to existing fetch_enr() API
    - Support fetching multiple years
5.  **Update utils.R**
    - Add
      [`get_available_grad_years()`](https://almartin82.github.io/caschooldata/reference/get_available_grad_years.md)
      function
    - Add graduation-specific helper functions
6.  **Create tests/testthat/test-graduation.R**
    - URL availability tests
    - Raw data fidelity tests
    - Aggregation tests
    - Data quality tests

### Proposed API

``` r
# Fetch 4-year graduation rates
grad_2024 <- fetch_grad(2024, type = "acgr", tidy = TRUE)

# Fetch 5-year graduation rates
grad_5yr <- fetch_grad(2024, type = "fycgr", tidy = TRUE)

# Fetch one-year graduate counts
counts <- fetch_grad(2024, type = "counts", tidy = TRUE)

# Get multiple years
grad_multi <- fetch_grad_multi(2020:2024, type = "acgr")
```

## Test Requirements

### Raw Data Fidelity Tests Needed

``` r
# 2024: State total matches raw
test_that("2024 state total matches raw ACGR file", {
  skip_if_offline()
  data <- fetch_grad(2024, type = "acgr", tidy = TRUE)
  state_ta <- data |>
    filter(agg_level == "T", reporting_category == "TA",
           charter_school == "All", dass == "All")
  expect_equal(state_ta$cohort_students, 506803)
  expect_equal(state_ta$grad_rate, 86.4, tolerance = 0.1)
})

# 2024: LA Unified district check
test_that("2024 LA Unified matches raw", {
  data <- fetch_grad(2024, type = "acgr", tidy = TRUE)
  lausd <- data |>
    filter(district_name == "Los Angeles Unified",
           reporting_category == "TA",
           charter_school == "All")
  expect_equal(lausd$cohort_students, 41955)
  expect_equal(lausd$grad_rate, 88.5, tolerance = 0.1)
})

# 2017: Earliest year baseline
test_that("2017 state total matches raw", {
  data <- fetch_grad(2017, type = "acgr", tidy = TRUE)
  state_ta <- data |>
    filter(agg_level == "T", reporting_category == "TA",
           charter_school == "All", dass == "All")
  expect_equal(state_ta$cohort_students, 493795)
  expect_equal(state_ta$grad_rate, 82.7, tolerance = 0.1)
})
```

### Data Quality Checks

``` r
# No negative values
test_that("All counts are non-negative", {
  data <- fetch_grad(2024, type = "acgr", tidy = FALSE)
  count_cols <- grep("Count", names(data), value = TRUE)
  for (col in count_cols) {
    vals <- suppressWarnings(as.numeric(data[[col]]))
    expect_true(all(vals >= 0, na.rm = TRUE), info = col)
  }
})

# Rates in valid range
test_that("All rates are 0-100", {
  data <- fetch_grad(2024, type = "acgr", tidy = FALSE)
  rate_cols <- grep("Rate", names(data), value = TRUE)
  for (col in rate_cols) {
    vals <- suppressWarnings(as.numeric(data[[col]]))
    expect_true(all(vals >= 0 & vals <= 100, na.rm = TRUE), info = col)
  }
})

# Cohort >= Graduates
test_that("Cohort size >= graduate count", {
  data <- fetch_grad(2024, type = "acgr", tidy = FALSE)
  cohort <- suppressWarnings(as.numeric(data$CohortStudents))
  grads <- suppressWarnings(as.numeric(data$`Regular HS Diploma Graduates (Count)`))
  valid <- !is.na(cohort) & !is.na(grads)
  expect_true(all(cohort[valid] >= grads[valid]))
})
```

### URL Availability Tests

``` r
test_that("All ACGR URLs return HTTP 200", {
  skip_if_offline()
  years <- 2017:2025
  for (yr in years) {
    url <- build_grad_url(yr, "acgr")
    response <- httr::HEAD(url,
      httr::user_agent("Mozilla/5.0"),
      httr::timeout(30))
    expect_equal(httr::status_code(response), 200,
      info = paste("Year", yr))
  }
})
```

## Package Status Note

**WARNING:** The caschooldata package is currently FAILING R-CMD-check.
The existing enrollment functionality has issues that should be resolved
before adding graduation features. Consider:

1.  Fix existing R-CMD-check failures first
2.  Then add graduation functionality
3.  Or: Add graduation in parallel but expect combined fixes needed

## References

- [Graduate and Dropout Data](https://www.cde.ca.gov/ds/ad/gdtop.asp)
- [ACGR Files](https://www.cde.ca.gov/ds/ad/filesacgr.asp)
- [FYCGR Files](https://www.cde.ca.gov/ds/ad/filesfycgr.asp)
- [One-Year Graduate
  Files](https://www.cde.ca.gov/ds/ad/filesoygrads.asp)
- [ACGR File Structure](https://www.cde.ca.gov/ds/ad/fsacgr.asp)
- [FYCGR File Structure](https://www.cde.ca.gov/ds/ad/fsfycgr.asp)
