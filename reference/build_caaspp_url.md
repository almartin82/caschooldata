# Build CAASPP research file URL

Constructs the direct download URL for CAASPP research files.

## Usage

``` r
build_caaspp_url(
  end_year,
  file_type = c("1", "all", "all_ela", "all_math"),
  format = c("csv", "ascii")
)
```

## Arguments

- end_year:

  School year end

- file_type:

  One of "1" (All Students), "all" (All Student Groups), "all_ela" (All
  Groups ELA only), "all_math" (All Groups Math only)

- format:

  One of "csv" (caret-delimited) or "ascii" (fixed-width)

## Value

URL string
