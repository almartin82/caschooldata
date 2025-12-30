# Identify aggregation rows in enrollment data

Adds boolean flags to identify state, county, district, and school level
records based on CDS code patterns or the agg_level column.

## Usage

``` r
id_enr_aggs(data)
```

## Arguments

- data:

  Tidy enrollment data frame

## Value

Data frame with is_state, is_county, is_district, is_school columns
added
