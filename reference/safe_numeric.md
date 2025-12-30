# Convert to numeric, handling suppression markers

CDE uses asterisks (\*) for suppressed data where cell size is 10 or
fewer.

## Usage

``` r
safe_numeric(x)
```

## Arguments

- x:

  Vector to convert

## Value

Numeric vector with NA for non-numeric values
