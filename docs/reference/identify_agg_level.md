# Identify aggregation level from CDS code

Determines if a CDS code represents state, county, district, or school
level based on the pattern of zeros in the code.

## Usage

``` r
identify_agg_level(cds_code)
```

## Arguments

- cds_code:

  A 14-digit CDS code string or vector

## Value

Character vector with "state", "county", "district", or "school"
