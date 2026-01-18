# Process raw CAASPP assessment data

Processes raw CAASPP research file data into a standardized schema.
Cleans column names, standardizes data types, and validates data
quality.

## Usage

``` r
process_assess(raw_data, end_year)
```

## Arguments

- raw_data:

  Raw CAASPP data from get_raw_assess() or import_local_assess()

- end_year:

  School year end (e.g., 2023 for 2022-23 school year)

## Value

A tibble with processed assessment data including columns:

- `end_year`: School year end (integer)

- `cds_code`: 14-digit CDS identifier (character)

- `county_code`: 2-digit county code (character)

- `district_code`: 5-digit district code (character)

- `school_code`: 7-digit school code (character)

- `agg_level`: Aggregation level (S=School, D=District, C=County,
  T=State)

- `grade`: Grade level (03, 04, 05, 06, 07, 08, 11, or 13 for all
  grades)

- `subject`: Assessment subject (ELA or Mathematics)

- `student_group`: Student group identifier

- `test_id`: Test identifier code

- `mean_scale_score`: Mean scale score (numeric)

- `pct_exceeded`: Percentage standard exceeded (numeric)

- `pct_met`: Percentage standard met (numeric)

- `pct_met_and_above`: Percentage standard met and above (numeric)

- `pct_nearly_met`: Percentage standard nearly met (numeric)

- `pct_not_met`: Percentage standard not met (numeric)

- `n_tested`: Number of students tested (integer)

- `n_exceeded`: Number standard exceeded (integer)

- `n_met`: Number standard met (integer)

- `n_met_and_above`: Number standard met and above (integer)

- `n_nearly_met`: Number standard nearly met (integer)

- `n_not_met`: Number standard not met (integer)

## Details

### Data Processing Steps:

1.  Extract CDS code components (county, district, school)

2.  Determine aggregation level from school code (0000000 = district
    summary)

3.  Clean and standardize column names

4.  Convert data types (character to numeric where appropriate)

5.  Validate ranges (percentages 0-100, non-negative counts)

6.  Handle suppressed values (groups with \< 11 students)

### Data Quality Checks:

- No Inf or NaN values in numeric columns

- Percentages between 0 and 100

- Counts are non-negative integers

- At least state-level data exists

## Examples

``` r
if (FALSE) { # \dontrun{
# Process raw assessment data
raw <- get_raw_assess(2023)
processed <- process_assess(raw$test_data, 2023)

# View processed data
head(processed)

# Filter to state-level 11th grade ELA results
library(dplyr)
state_11_ela <- processed %>%
  filter(agg_level == "T", grade == "11", subject == "ELA")
} # }
```
