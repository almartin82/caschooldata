# Identify assessment aggregations

Adds aggregation identifier columns to assessment data. Creates
is_state, is_county, is_district, is_school logical columns.

## Usage

``` r
id_assess_aggs(data)
```

## Arguments

- data:

  Assessment data (processed or tidy format)

## Value

Data with additional aggregation identifier columns

## Details

Creates logical columns for easy filtering:

- `is_state`: TRUE for state-level aggregations

- `is_county`: TRUE for county-level aggregations

- `is_district`: TRUE for district-level aggregations

- `is_school`: TRUE for school-level aggregations

Also creates `entity_name` column based on aggregation level.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Add aggregation identifiers
tidy <- tidy_assess(processed_data) %>%
  id_assess_aggs()

# Filter to school-level data
schools <- tidy %>%
  filter(is_school)

# Filter to state-level data
state <- tidy %>%
  filter(is_state)
} # }
```
