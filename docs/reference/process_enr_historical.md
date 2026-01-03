# Process historical format (1982-2023) CDE data

Historical files contain school-level data with race/ethnicity and
gender breakdown. This function aggregates the data to create reporting
categories similar to the modern format and synthesizes
district/county/state aggregates.

## Usage

``` r
process_enr_historical(raw_data, end_year)
```

## Arguments

- raw_data:

  Raw data frame from get_raw_enr_historical()

- end_year:

  The school year end for context

## Value

Processed data frame with standard schema

## Details

File format varies by era:

- 2015-2023: Has names, ENR_TYPE column, numeric race codes 0-9

- 2008-2014: Has names, no ENR_TYPE, numeric race codes 0-9

- 1994-2007: No names (just CDS_CODE), numeric race codes 1-8

- 1982-1993: Has names (DISTRICT_NAME, SCHOOL_NAME), letter race codes
