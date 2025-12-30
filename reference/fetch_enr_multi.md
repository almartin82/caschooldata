# Fetch enrollment for multiple years

Convenience function to download enrollment data for multiple years at
once.

## Usage

``` r
fetch_enr_multi(years, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- years:

  Vector of school year ends (e.g., c(2024, 2025))

- tidy:

  If TRUE (default), returns tidy format

- use_cache:

  If TRUE (default), uses cache when available

## Value

Combined tibble with data for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 and 2025 data
enr_multi <- fetch_enr_multi(c(2024, 2025))
} # }
```
