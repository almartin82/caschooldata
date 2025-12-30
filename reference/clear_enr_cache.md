# Clear enrollment cache

Removes cached enrollment data files.

## Usage

``` r
clear_enr_cache(end_year = NULL)
```

## Arguments

- end_year:

  Optional. If provided, only clear cache for this year. If NULL
  (default), clears all cached enrollment data.

## Value

Invisibly returns the number of files removed

## Examples

``` r
if (FALSE) { # \dontrun{
# Clear all cached data
clear_enr_cache()

# Clear only 2024 data
clear_enr_cache(2024)
} # }
```
