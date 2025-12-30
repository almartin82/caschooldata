# Get cache status

Reports which years have cached data available, including file sizes and
ages.

## Usage

``` r
cache_status()
```

## Value

Data frame with cache information (invisibly). Columns include:

- `end_year`: School year end

- `cache_type`: Type of cached data (tidy or wide)

- `size_mb`: File size in megabytes

- `age_days`: Days since file was created/modified

## Examples

``` r
if (FALSE) { # \dontrun{
cache_status()
} # }
```
