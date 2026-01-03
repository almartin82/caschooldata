# Get raw enrollment data from CDE

Downloads the raw enrollment data file for a given year from the
California Department of Education website. Uses modern Census Day files
for 2024+ and historical school-level files for 1982-2023.

## Usage

``` r
get_raw_enr(end_year)
```

## Arguments

- end_year:

  A school year end (e.g., 2024 for 2023-24 school year)

## Value

Raw data frame as downloaded from CDE
