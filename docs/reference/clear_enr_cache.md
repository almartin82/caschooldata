# Clear the caschooldata cache

Removes all cached data files.

## Usage

``` r
clear_enr_cache(end_year = NULL, data_type = NULL)
```

## Arguments

- end_year:

  Optional. If provided, only clear cache for this year. If NULL
  (default), clears all cached data.

- data_type:

  Type of cache to clear: "enr" (enrollment), "grad" (graduation), or
  NULL (both).

## Value

Invisibly returns the number of files removed

## Examples

``` r
if (FALSE) { # \dontrun{
# Clear all cached data
clear_enr_cache()

# Clear only 2024 data
clear_enr_cache(2024)

# Clear only graduation cache
clear_enr_cache(data_type = "grad")
} # }
```
