# caschooldata fetch_enr Tidiness Audit

**Date**: 2026-01-05 **Auditor**: Claude Code **Package Version**: 0.1.0
**Year Tested**: 2024 (most recent available)

------------------------------------------------------------------------

## Executive Summary

**Tidiness Score**: 6/10

The package has the correct PRD column structure in the source code, but
has **two critical data quality issues** that prevent it from meeting
PRD standards:

1.  **ID Code Corruption**: State and County level records have
    corrupted IDs like “000NA” and “00000NA” instead of “00000” and
    “0000000”
2.  **High NA Percentage**: 39% of Campus-level and 16.3% of
    District-level rows have NA in the `pct` column, which should be
    calculated from the data

------------------------------------------------------------------------

## PRD Compliance Check

### Required Columns (10/10 Present)

| Column        | Present | Data Type | Notes                                   |
|---------------|---------|-----------|-----------------------------------------|
| end_year      | ✓       | integer   | Correct                                 |
| district_id   | ✓       | character | **Contains “000NA” corruption**         |
| campus_id     | ✓       | character | **Contains “00000NA” corruption**       |
| district_name | ✓       | character | NA for State/County (expected)          |
| campus_name   | ✓       | character | NA for State/County/District (expected) |
| type          | ✓       | character | Values: State, County, District, Campus |
| grade_level   | ✓       | character | Values: TOTAL, TK, K, 01-12             |
| subgroup      | ✓       | character | Properly mapped from reporting_category |
| n_students    | ✓       | numeric   | No NA values                            |
| pct           | ✓       | numeric   | **High NA rate (31.5% overall)**        |

### Column Structure

**All 10 PRD columns are present and in the correct order.**

The output includes 23 total columns: - 10 PRD columns (first 10
columns) - 5 CA-specific columns: academic_year, cds_code, county_code,
county_name, charter_status - 5 helper columns: is_state, is_county,
is_district, is_school, is_charter - 3 internal columns: agg_level,
reporting_category, total_enrollment

------------------------------------------------------------------------

## Issues Found

### Issue 1: ID Code Corruption (CRITICAL)

**Severity**: High **Impact**: State and County level data has unusable
ID codes

**Problem**: - State-level records have `district_id = "000NA"` and
`campus_id = "00000NA"` - County-level records have
`district_id = "000NA"` and `campus_id = "00000NA"`

**Expected Behavior**: - State-level should have `district_id = "00000"`
and `campus_id = "0000000"` - County-level should have
`district_id = "00000"` and `campus_id = "0000000"`

**Root Cause**: The
[`process_enr_modern()`](https://almartin82.github.io/caschooldata/reference/process_enr_modern.md)
function in `R/process_enrollment.R` uses `sprintf("%05s", value)` to
pad codes with leading zeros. When the raw data has NA values for
DistrictCode and SchoolCode at State/County levels,
`sprintf("%05s", NA)` produces ” NA” (with spaces), which then gets
converted to “000NA” by the `gsub(" ", "0", ...)` replacement.

**Code Location**: `R/process_enrollment.R`, lines 96-114

**Evidence**:

    State district_id samples: 000NA NA NA NA NA
    State campus_id samples: 00000NA NA NA NA NA
    Rows with NA in district_id: 70,485
    Rows with NA in campus_id: 844,785

### Issue 2: High NA Percentage in pct Column (HIGH)

**Severity**: High **Impact**: 31.5% of all rows have NA in the `pct`
column

**Problem**: - Overall: 854,909 / 2,712,729 rows (31.5%) have NA in
`pct` - Campus level: 728,392 / 1,867,944 rows (39.0%) - District level:
126,517 / 774,300 rows (16.3%) - County level: 0 / 69,030 rows (0%) -
State level: 0 / 1,455 rows (0%)

**Expected Behavior**: The `pct` column should represent the percentage
of total enrollment for each subgroup within a given (entity,
grade_level) combination. For example, for the “hispanic” subgroup at a
specific school in grade “01”, `pct` should be
`n_students_hispanic / n_students_total`.

**Root Cause**: The
[`tidy_enr()`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md)
function calculates `pct` by: 1. Grouping by
`(end_year, district_id, campus_id, type, grade_level)` 2. Finding the
`n_students` value where `subgroup == "total"` to use as the denominator
3. Calculating `pct = n_students / total_for_group`

This fails when: - The `subgroup == "total"` row doesn’t exist for that
(entity, grade_level) combination - The `total_for_group` is NA, leading
to division by NA

**Evidence**:

    pct column range: Min: 0, Max: 1, NA values: 854909
    Values > 1: 0
    Values < 0: 0
    Inf values: 0

**Investigation Needed**: Why are so many (entity, grade_level)
combinations missing the `subgroup == "total"` row?

------------------------------------------------------------------------

## Comparison to NJ Reference Implementation

The NJ reference implementation
(`/Users/almartin/Documents/njschooldata/R/fetch_enrollment.R`) has:

1.  **Tidy Output Schema**: Returns long format with grade and subgroup
    columns
2.  **ID Handling**: Preserves leading zeros in character columns
3.  **Percentage Calculation**: Has
    [`tidy_enr()`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md)
    function that calculates percentages

**Key Difference**: - NJ’s
[`tidy_enr()`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md)
uses a simpler structure with gender/grade pivoting - CA has more
complex reporting categories (race, gender, student groups, ELAS, age
ranges) - CA’s percentage calculation logic is more complex due to
multiple subgroup types

------------------------------------------------------------------------

## Testing Summary

### Data Quality Checks

| Check                   | Result | Notes                      |
|-------------------------|--------|----------------------------|
| Zeros in state total    | PASS   | State total \> 0           |
| pct in \[0,1\] range    | PASS   | All values are 0-1 (or NA) |
| No Inf in pct           | PASS   | 0 Inf values               |
| Non-negative n_students | PASS   | All values \>= 0           |

### Fidelity Checks

| Check                       | Result     | Notes             |
|-----------------------------|------------|-------------------|
| Raw data matches processed  | NOT TESTED | Need to implement |
| Specific value verification | NOT TESTED | Need to implement |

------------------------------------------------------------------------

## Recommendations

### Immediate Fixes Required

1.  **Fix NA handling in ID code processing** (Issue 1)
    - Replace [`sprintf()`](https://rdrr.io/r/base/sprintf.html) with
      conditional logic that handles NA values
    - Set NA codes to “00000” (district) and “0000000” (school)
      explicitly
2.  **Fix high NA rate in pct calculation** (Issue 2)
    - Investigate why `subgroup == "total"` rows are missing
    - Ensure all (entity, grade_level) combinations have a total row
    - Consider alternative calculation method if totals are unreliable

### Additional Improvements

3.  **Add correctness tests** (as required by PRD)
    - Test specific verified values from raw Excel files
    - Test aggregation correctness (sum of schools = district, etc.)
    - Test percentage calculation accuracy
4.  **Reduce CA-specific columns in output**
    - Consider moving `academic_year`, `cds_code`, `county_code`,
      `county_name`, `charter_status` to the end
    - PRD columns should be clearly prioritized

------------------------------------------------------------------------

## Next Steps

1.  [x] Document findings in this audit
2.  Fix Issue 1: ID code NA handling in `process_enrollment.R`
3.  Investigate and fix Issue 2: pct NA calculation in
    `tidy_enrollment.R`
4.  Implement correctness tests in
    `tests/testthat/test-raw-data-fidelity.R`
5.  Run
    [`devtools::check()`](https://devtools.r-lib.org/reference/check.html)
    to ensure no regressions
6.  Build pkgdown site to verify documentation

------------------------------------------------------------------------

## Test Commands Used

``` r
# Load package and test
library(caschooldata)
library(dplyr)

data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

# Check columns
prd_cols <- c('end_year', 'district_id', 'campus_id', 'district_name', 'campus_name',
              'type', 'grade_level', 'subgroup', 'n_students', 'pct')
for (col in prd_cols) {
  cat(if (col %in% names(data)) '✓' else '✗', ' ', col, '\n')
}

# Check pct range
summary(data$pct)

# Check ID corruption
sum(grepl('NA', data$district_id))
sum(grepl('NA', data$campus_id))
```

------------------------------------------------------------------------

## Files Modified During Audit

None yet - this is the initial audit report.
