# Get available CAASPP assessment years

Returns a vector of years for which CAASPP assessment data is available.

## Usage

``` r
get_available_assess_years()
```

## Value

Named list with:

- `min_year`: First available year (2015)

- `max_year`: Last available year (2024)

- `all_years`: All available years

- `note`: Special notes about data availability

## Examples

``` r
if (FALSE) { # \dontrun{
# Check available assessment years
years <- get_available_assess_years()
print(years)

# Fetch all available years
all_assess <- fetch_assess_multi(years$all_years)
} # }
```
