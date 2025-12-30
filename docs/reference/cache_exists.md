# Check if cached data exists

Check if cached data exists

## Usage

``` r
cache_exists(end_year, cache_type, max_age = 30)
```

## Arguments

- end_year:

  School year end

- cache_type:

  Type of cache ("tidy" or "wide")

- max_age:

  Maximum age in days (default 30). Set to Inf to ignore age.

## Value

Logical indicating if valid cache exists
