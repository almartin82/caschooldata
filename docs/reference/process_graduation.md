# Process raw graduation data into standard schema

Transforms raw CDE graduation data into the standardized schema used by
the package. Converts record types, parses CDS codes, maps student
groups, and standardizes column names.

## Usage

``` r
process_graduation(raw_data, end_year)
```

## Arguments

- raw_data:

  Data frame from get_raw_graduation()

- end_year:

  School year end

## Value

Processed data frame with standardized columns
