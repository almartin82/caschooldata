# Import locally downloaded CAASPP assessment files

Imports CAASPP research files that have been manually downloaded from
the CAASPP portal. Use this function when automated downloads are not
available.

## Usage

``` r
import_local_assess(test_data_path, entities_path, end_year)
```

## Arguments

- test_data_path:

  Path to the caret-delimited test data file

- entities_path:

  Path to the entities file

- end_year:

  School year end (for metadata)

## Value

List containing parsed test_data and entities data frames

## Examples

``` r
if (FALSE) { # \dontrun{
# Import manually downloaded files
local_data <- import_local_assess(
  test_data_path = "~/Downloads/sb_ca2024_1_csv_v1.txt",
  entities_path = "~/Downloads/sb_ca2024entities_csv.txt",
  end_year = 2024
)

test_data <- local_data$test_data
entities <- local_data$entities
} # }
```
