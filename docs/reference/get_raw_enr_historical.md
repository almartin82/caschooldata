# Download historical format (1982-2023) CDE data

Historical files contain school-level data only with race/ethnicity and
gender breakdown. Files are organized by year ranges with different
formats:

- 1982-1993: 4-char year format, letter race codes, has names

- 1994-2007: 7-char year format, no names in file

- 2008-2023: 7-char year format, has names

## Usage

``` r
get_raw_enr_historical(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Raw data frame
