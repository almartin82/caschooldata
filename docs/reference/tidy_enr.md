# Convert enrollment data to tidy format

Pivots enrollment data from wide format (one column per grade) to long
format with a grade column. Also handles the reporting_category column
which already contains demographic subgroups.

## Usage

``` r
tidy_enr(wide_data)
```

## Arguments

- wide_data:

  Data frame in wide format from process_enr()

## Value

Tidy data frame with grade and subgroup columns

## Examples

``` r
if (FALSE) { # \dontrun{
# Get wide format and then tidy
wide <- fetch_enr(2024, tidy = FALSE)
tidy <- tidy_enr(wide)
} # }
```
