# Fetch California school directory data

Downloads and processes school directory data from the California
Department of Education SchoolDirectory. This includes all public
schools and districts with contact information and administrator names.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  Currently unused. The directory data represents current schools and is
  not year-specific. Included for API consistency with other fetch
  functions.

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from CDE.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from CDE.

## Value

A tibble with school directory data. Columns include:

- `cds_code`: 14-digit CDS identifier

- `county_code`: 2-digit county code

- `district_code`: 5-digit district code

- `school_code`: 7-digit school code

- `school_name`: School name (or district name for district-level rows)

- `district_name`: District name

- `county_name`: County name

- `school_type`: Type of school (e.g., "Elementary", "High School")

- `street`: Street address

- `city`: City

- `state`: State (always "CA")

- `zip`: ZIP code

- `phone`: Phone number

- `admin_name`: Administrator name (principal for schools,
  superintendent for districts)

- `agg_level`: Aggregation level ("S" = School, "D" = District)

- `status`: School status (e.g., "Active", "Closed")

- `charter_status`: Charter indicator (Y/N)

- `latitude`: Geographic latitude

- `longitude`: Geographic longitude

## Details

The directory data is downloaded as an Excel file from the CDE
SchoolDirectory page. This data represents the current state of
California schools and districts and is updated periodically by CDE.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data
dir_data <- fetch_directory()

# Get raw format (original CDE column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to active schools only
library(dplyr)
active_schools <- dir_data |>
  filter(agg_level == "S", status == "Active")

# Find all schools in a district
lausd_schools <- dir_data |>
  filter(district_code == "64733", agg_level == "S")
} # }
```
