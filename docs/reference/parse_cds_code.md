# Parse CDS code into components

Splits a 14-digit CDS code into county, district, and school components.

## Usage

``` r
parse_cds_code(cds_code)
```

## Arguments

- cds_code:

  A 14-digit CDS code string or vector of codes

## Value

Data frame with county_code, district_code, school_code columns

## Examples

``` r
if (FALSE) { # \dontrun{
# Parse a single CDS code
parse_cds_code("01611920130229")

# Parse multiple codes
parse_cds_code(c("01611920130229", "19647330000000"))
} # }
```
