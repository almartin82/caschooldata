# Getting Started with caschooldata

## Overview

The `caschooldata` package provides tools for fetching and analyzing
California school enrollment data from the California Department of
Education (CDE). This vignette walks through the main features of the
package.

**What you’ll find in the data:**

- 8 years of enrollment data (2018-2025)
- 5.8+ million students across 1,000+ districts
- Demographic breakdowns by race/ethnicity, gender, and student groups
- Trends showing 400,000+ student decline since COVID-19

For a deep dive into trends and findings, see the [District Trends &
Demographics](https://almartin82.github.io/caschooldata/articles/district-highlights.md)
vignette.

## Installation

Install from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("almartin82/caschooldata")
```

## Fetching Enrollment Data

### Basic Usage

The main function is
[`fetch_enr()`](https://almartin82.github.io/caschooldata/reference/fetch_enr.md),
which downloads and processes enrollment data for a given school year:

``` r
library(caschooldata)
library(dplyr)

# Fetch 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

head(enr)
```

The `end_year` parameter refers to the spring semester year. For
example, `end_year = 2024` fetches data for the 2023-24 school year.

### Available Years

The package supports Census Day enrollment data from 2018-2025:

- **2024-2025**: Modern Census Day files with full demographic
  breakdowns
- **2018-2023**: Historical school-level files with race/ethnicity and
  gender data

``` r
# Fetch the most recent year
enr_2025 <- fetch_enr(2025)

# Fetch historical data
enr_2020 <- fetch_enr(2020)

# Fetch all years for trend analysis
enr_all <- fetch_enr_multi(2018:2025)
```

### Wide vs. Tidy Format

By default,
[`fetch_enr()`](https://almartin82.github.io/caschooldata/reference/fetch_enr.md)
returns data in **tidy (long) format**, which is ideal for analysis with
dplyr and ggplot2:

``` r
# Default: tidy format
enr_tidy <- fetch_enr(2024)
names(enr_tidy)
# Includes: grade_level, reporting_category, subgroup, n_students
```

For wide format (one column per grade), set `tidy = FALSE`:

``` r
# Wide format: one column per grade
enr_wide <- fetch_enr(2024, tidy = FALSE)
names(enr_wide)
# Includes: grade_tk, grade_k, grade_01, ..., grade_12, total_enrollment
```

### Fetching Multiple Years

Use
[`fetch_enr_multi()`](https://almartin82.github.io/caschooldata/reference/fetch_enr_multi.md)
to download data for multiple years at once:

``` r
# Fetch 2024 and 2025 data
all_years <- fetch_enr_multi(c(2024, 2025))

# Analyze enrollment trends
all_years %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

## Understanding the Data Schema

### Column Descriptions

The tidy enrollment data includes the following columns:

| Column                                              | Description                                                        |
|-----------------------------------------------------|--------------------------------------------------------------------|
| `end_year`                                          | School year end (e.g., 2024 for 2023-24)                           |
| `academic_year`                                     | Academic year string (e.g., “2023-24”)                             |
| `cds_code`                                          | 14-digit County-District-School identifier                         |
| `county_code`                                       | 2-digit county code (01-58)                                        |
| `district_code`                                     | 5-digit district code                                              |
| `school_code`                                       | 7-digit school code                                                |
| `agg_level`                                         | Aggregation level: T (State), C (County), D (District), S (School) |
| `county_name`                                       | County name                                                        |
| `district_name`                                     | District name                                                      |
| `school_name`                                       | School name                                                        |
| `charter_status`                                    | Y (Charter), N (Non-Charter), or All                               |
| `grade_level`                                       | Grade: TK, K, 01-12, or TOTAL                                      |
| `reporting_category`                                | CDE demographic category code                                      |
| `subgroup`                                          | Human-readable subgroup name                                       |
| `n_students`                                        | Enrollment count                                                   |
| `is_state`, `is_county`, `is_district`, `is_school` | Boolean aggregation flags                                          |
| `is_charter`                                        | Boolean charter indicator                                          |

### Aggregation Levels

The data includes four aggregation levels:

``` r
# State-level totals
state <- enr %>%
  filter(agg_level == "T")
# or equivalently:
state <- enr %>%
  filter(is_state)

# County-level (58 California counties)
counties <- enr %>%
  filter(is_county)

# District-level
districts <- enr %>%
  filter(is_district)

# School-level
schools <- enr %>%
  filter(is_school)
```

### Demographic Subgroups

The `reporting_category` column contains CDE codes, while `subgroup`
provides human-readable names:

| Category       | Code  | Subgroup Name    |
|----------------|-------|------------------|
| Total          | TA    | total_enrollment |
| Race/Ethnicity | RE_H  | hispanic         |
| Race/Ethnicity | RE_W  | white            |
| Race/Ethnicity | RE_A  | asian            |
| Race/Ethnicity | RE_B  | black            |
| Race/Ethnicity | RE_F  | filipino         |
| Race/Ethnicity | RE_P  | pacific_islander |
| Race/Ethnicity | RE_I  | native_american  |
| Race/Ethnicity | RE_T  | multiracial      |
| Gender         | GN_F  | female           |
| Gender         | GN_M  | male             |
| Gender         | GN_X  | nonbinary        |
| Student Groups | SG_EL | lep              |
| Student Groups | SG_DS | special_ed       |
| Student Groups | SG_SD | econ_disadv      |
| Student Groups | SG_FS | foster_youth     |
| Student Groups | SG_HM | homeless         |
| Student Groups | SG_MG | migrant          |

``` r
# View all available subgroups
enr %>%
  distinct(reporting_category, subgroup) %>%
  arrange(reporting_category)
```

### Grade Levels

Individual grades range from Transitional Kindergarten (TK) through 12th
grade:

``` r
# Available grade levels
enr %>%
  distinct(grade_level) %>%
  arrange(grade_level)

# Filter to specific grades
elementary <- enr %>%
  filter(grade_level %in% c("TK", "K", "01", "02", "03", "04", "05"))

middle_school <- enr %>%
  filter(grade_level %in% c("06", "07", "08"))

high_school <- enr %>%
  filter(grade_level %in% c("09", "10", "11", "12"))
```

## Filtering and Analysis Examples

### Top 10 Largest Districts

``` r
library(caschooldata)
library(dplyr)

enr <- fetch_enr(2024)

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, county_name, n_students) %>%
  head(10)
```

### County-Level Analysis

``` r
# Enrollment by county
county_enrollment <- enr %>%
  filter(is_county, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(county_name, n_students)

# Top 5 counties
head(county_enrollment, 5)
```

### Demographic Breakdown

``` r
# State-level race/ethnicity breakdown
enr %>%
  filter(
    is_state,
    grade_level == "TOTAL",
    grepl("^RE_", reporting_category)
  ) %>%
  mutate(pct = n_students / sum(n_students) * 100) %>%
  select(subgroup, n_students, pct) %>%
  arrange(desc(n_students))
```

### Charter vs. Non-Charter Comparison

``` r
# State-level charter enrollment
charter_comparison <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(charter_status) %>%
  summarize(total_enrollment = sum(n_students, na.rm = TRUE))

charter_comparison
```

### Grade-Level Aggregations

Use
[`enr_grade_aggs()`](https://almartin82.github.io/caschooldata/reference/enr_grade_aggs.md)
to create grade band summaries:

``` r
# Create K-8, HS, K-12 aggregations
grade_bands <- enr_grade_aggs(enr)

# View state-level grade bands
grade_bands %>%
  filter(is_state) %>%
  select(grade_level, n_students)
```

## Working with CDS Codes

California uses a 14-digit County-District-School (CDS) code system:

- **Positions 1-2**: County code (01-58)
- **Positions 3-7**: District code (5 digits)
- **Positions 8-14**: School code (7 digits)

``` r
# Parse a CDS code
parse_cds_code("19647331932334")
# Returns: list(county = "19", district = "64733", school = "1932334")

# Filter to a specific district using CDS pattern
lausd <- enr %>%
  filter(grepl("^1964733", cds_code), is_school)
```

## Visualization Examples

### Bar Chart: Top Counties

``` r
library(ggplot2)

enr <- fetch_enr(2024)

# Top 10 counties by enrollment
top_counties <- enr %>%
  filter(is_county, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10)

ggplot(top_counties, aes(x = reorder(county_name, n_students), y = n_students)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Top 10 California Counties by Enrollment",
    subtitle = "2023-24 School Year",
    x = NULL,
    y = "Total Enrollment"
  ) +
  theme_minimal()
```

### Demographic Composition

``` r
library(ggplot2)

# Race/ethnicity pie chart data
race_data <- enr %>%
  filter(
    is_state,
    grade_level == "TOTAL",
    grepl("^RE_", reporting_category)
  ) %>%
  mutate(pct = n_students / sum(n_students)) %>%
  select(subgroup, n_students, pct)

ggplot(race_data, aes(x = "", y = pct, fill = subgroup)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  labs(title = "California Enrollment by Race/Ethnicity") +
  theme_void() +
  theme(legend.position = "right")
```

### Enrollment Trend (Multi-Year)

``` r
library(ggplot2)

# Fetch multiple years
all_years <- fetch_enr_multi(c(2024, 2025))

# State enrollment over time
state_trend <- all_years %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(state_trend, aes(x = end_year, y = n_students)) +
  geom_line(color = "steelblue", size = 1.5) +
  geom_point(color = "steelblue", size = 3) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "California K-12 Enrollment",
    x = "School Year (End Year)",
    y = "Total Enrollment"
  ) +
  theme_minimal()
```

## Cache Management

The package caches downloaded data locally to avoid repeated downloads:

``` r
# Check what's cached
cache_status()

# Clear cache for a specific year
clear_enr_cache(2024)

# Force a fresh download (bypass cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)
```

The cache is stored in a user-specific application data directory (via
`rappdirs`). Cached data persists between R sessions.

## Data Quality Notes

- Enrollment counts are based on **Census Day** (first Wednesday in
  October)
- Some cells may be suppressed for privacy (small counts)
- Charter and non-charter enrollments are reported separately
- State and county totals may include students not assigned to specific
  schools

## Next Steps

- See the [District Trends & Demographics
  vignette](https://almartin82.github.io/caschooldata/articles/district-highlights.md)
  for data-driven findings
- Explore the [Data Quality QA
  vignette](https://almartin82.github.io/caschooldata/articles/data-quality-qa.md)
  for validation examples
- Check the function reference for detailed documentation:
  [`?fetch_enr`](https://almartin82.github.io/caschooldata/reference/fetch_enr.md),
  [`?tidy_enr`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md)
- Visit the [package
  website](https://almartin82.github.io/caschooldata/) for more
  resources
