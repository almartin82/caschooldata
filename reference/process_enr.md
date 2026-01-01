# Process raw enrollment data to standard schema

Takes raw enrollment data from CDE and standardizes column names, types,
and handles any year-specific format differences. Uses modern processing
for 2024+ Census Day files and historical processing for 2017-2023
files.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  Raw data frame from get_raw_enr()

- end_year:

  The school year end for context

## Value

Processed data frame with standard schema
