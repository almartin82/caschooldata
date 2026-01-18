# Clear graduation rate cache

Removes all cached graduation rate data files.

## Usage

``` r
clear_grad_cache(years = NULL)
```

## Arguments

- years:

  Optional vector of years to clear. If NULL, clears all years.

## Value

Invisibly returns the number of files removed

## Examples

``` r
if (FALSE) { # \dontrun{
# Clear all graduation cache
clear_grad_cache()

# Clear only 2024 data
clear_grad_cache(2024)

# Clear multiple years
clear_grad_cache(2020:2024)
} # }
```
