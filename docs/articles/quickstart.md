# Getting Started with caschooldata

## Installation

Install from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("almartin82/caschooldata")
```

## Quick Example

Fetch the most recent year of California enrollment data:

``` r
library(caschooldata)
library(dplyr)

# Fetch 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

head(enr)
```

    ## # A tibble: 6 × 21
    ##   end_year academic_year agg_level cds_code       county_code district_code
    ##      <int> <chr>         <chr>     <chr>          <chr>       <chr>        
    ## 1     2024 2023-24       T         00000NA00000NA 00          000NA        
    ## 2     2024 2023-24       T         00000NA00000NA 00          000NA        
    ## 3     2024 2023-24       T         00000NA00000NA 00          000NA        
    ## 4     2024 2023-24       T         00000NA00000NA 00          000NA        
    ## 5     2024 2023-24       T         00000NA00000NA 00          000NA        
    ## 6     2024 2023-24       T         00000NA00000NA 00          000NA        
    ## # ℹ 15 more variables: school_code <chr>, county_name <chr>,
    ## #   district_name <chr>, school_name <chr>, charter_status <chr>,
    ## #   grade_level <chr>, reporting_category <chr>, subgroup <chr>,
    ## #   n_students <dbl>, total_enrollment <dbl>, is_state <lgl>, is_county <lgl>,
    ## #   is_district <lgl>, is_school <lgl>, is_charter <lgl>

## Understanding the Data

The data is returned in **tidy (long) format** by default:

- Each row is one subgroup for one school/district/county/state
- `reporting_category` is the CDE demographic category code (e.g., “TA”,
  “RE_H”)
- `subgroup` is the human-readable name (e.g., “total”, “hispanic”)
- `grade_level` shows the grade (“TOTAL”, “TK”, “K”, “01”-“12”)
- `n_students` is the enrollment count
- `agg_level` indicates the level: T (State), C (County), D (District),
  S (School)

``` r
enr %>%
  filter(is_state) %>%
  select(end_year, agg_level, subgroup, grade_level, n_students) %>%
  head(10)
```

    ## # A tibble: 10 × 5
    ##    end_year agg_level subgroup        grade_level n_students
    ##       <int> <chr>     <chr>           <chr>            <dbl>
    ##  1     2024 T         age_0_3         TOTAL               13
    ##  2     2024 T         age_4_18        TOTAL          5794728
    ##  3     2024 T         age_19_22       TOTAL            23564
    ##  4     2024 T         age_23_29       TOTAL             4889
    ##  5     2024 T         age_30_39       TOTAL             7408
    ##  6     2024 T         age_40_49       TOTAL             4354
    ##  7     2024 T         age_50_plus     TOTAL             2734
    ##  8     2024 T         adult_el        TOTAL            14572
    ##  9     2024 T         english_learner TOTAL          1074833
    ## 10     2024 T         english_only    TOTAL          3539761

## Filtering by Level

Use the aggregation flags to filter data:

``` r
# State totals
state <- enr %>% filter(is_state, subgroup == "total", grade_level == "TOTAL")
state %>% select(end_year, n_students)
```

    ## # A tibble: 3 × 2
    ##   end_year n_students
    ##      <int>      <dbl>
    ## 1     2024    5837690
    ## 2     2024    5128055
    ## 3     2024     709635

``` r
# All counties
counties <- enr %>% filter(is_county, subgroup == "total", grade_level == "TOTAL")
nrow(counties)
```

    ## [1] 169

``` r
# All districts
districts <- enr %>% filter(is_district, subgroup == "total", grade_level == "TOTAL")
nrow(districts)
```

    ## [1] 2354

``` r
# All schools
schools <- enr %>% filter(is_school, subgroup == "total", grade_level == "TOTAL")
nrow(schools)
```

    ## [1] 10579

## Simple Analysis: Top 10 Districts

``` r
enr %>%
  filter(is_district, subgroup == "total", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, county_name, n_students) %>%
  head(10)
```

    ## # A tibble: 10 × 3
    ##    district_name       county_name n_students
    ##    <chr>               <chr>            <dbl>
    ##  1 Los Angeles Unified Los Angeles     529902
    ##  2 Los Angeles Unified Los Angeles     381116
    ##  3 Los Angeles Unified Los Angeles     148786
    ##  4 San Diego Unified   San Diego       114330
    ##  5 San Diego Unified   San Diego        95492
    ##  6 Fresno Unified      Fresno           71480
    ##  7 Fresno Unified      Fresno           68246
    ##  8 Long Beach Unified  Los Angeles      64267
    ##  9 Long Beach Unified  Los Angeles      63966
    ## 10 Elk Grove Unified   Sacramento       63518

## Demographic Breakdown

California enrollment data includes detailed demographic subgroups:

``` r
# State-level demographics for 2024
enr %>%
  filter(is_state, grade_level == "TOTAL") %>%
  select(subgroup, n_students) %>%
  arrange(desc(n_students))
```

    ## # A tibble: 97 × 2
    ##    subgroup                        n_students
    ##    <chr>                                <dbl>
    ##  1 total                              5837690
    ##  2 age_4_18                           5794728
    ##  3 total                              5128055
    ##  4 age_4_18                           5111687
    ##  5 socioeconomically_disadvantaged    3659382
    ##  6 english_only                       3539761
    ##  7 hispanic                           3275030
    ##  8 socioeconomically_disadvantaged    3217530
    ##  9 english_only                       3088646
    ## 10 male                               2997905
    ## # ℹ 87 more rows

## Wide Format

If you prefer wide format (one column per grade), set `tidy = FALSE`:

``` r
enr_wide <- fetch_enr(2024, tidy = FALSE)

enr_wide %>%
  filter(agg_level == "T") %>%
  select(end_year, reporting_category, total_enrollment,
         starts_with("grade_")) %>%
  head(5)
```

    ## # A tibble: 5 × 17
    ##   end_year reporting_category total_enrollment grade_tk grade_k grade_01
    ##      <int> <chr>                         <dbl>    <dbl>   <dbl>    <dbl>
    ## 1     2024 AR_03                            13        1       0        0
    ## 2     2024 AR_0418                     5794728   151490  370750   396408
    ## 3     2024 AR_1922                       23564        0       0        0
    ## 4     2024 AR_2329                        4889        0       0        0
    ## 5     2024 AR_3039                        7408        0       0        0
    ## # ℹ 11 more variables: grade_02 <dbl>, grade_03 <dbl>, grade_04 <dbl>,
    ## #   grade_05 <dbl>, grade_06 <dbl>, grade_07 <dbl>, grade_08 <dbl>,
    ## #   grade_09 <dbl>, grade_10 <dbl>, grade_11 <dbl>, grade_12 <dbl>

## Historical Data

Fetch multiple years to analyze trends:

``` r
# Fetch multiple years of data
years <- 2024:2025
all_enr <- fetch_enr_multi(years)

# State enrollment trend
all_enr %>%
  filter(is_state, subgroup == "total", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

## CDS Codes

California uses a 14-digit County-District-School (CDS) code system:

- 2 digits: County code (01-58, California’s 58 counties)
- 5 digits: District code
- 7 digits: School code

You can parse CDS codes using the
[`parse_cds_code()`](https://almartin82.github.io/caschooldata/reference/parse_cds_code.md)
function:

``` r
# Example: Parse a school's CDS code
parse_cds_code("19647331932334")
```

    ##         cds_code county_code district_code school_code
    ## 1 19647331932334          19         64733     1932334

## Visualization Example

``` r
library(ggplot2)

# Top 10 counties by enrollment
county_enr <- enr %>%
  filter(is_county, subgroup == "total", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10)

ggplot(county_enr, aes(x = reorder(county_name, n_students), y = n_students)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Top 10 California Counties by Enrollment",
    x = NULL,
    y = "Total Enrollment"
  ) +
  theme_minimal()
```

![](quickstart_files/figure-html/visualization-1.png)

## Cache Management

The package caches downloaded data locally to speed up repeated queries:

``` r
# Check cache status
cache_status()

# Clear cache for a specific year
clear_enr_cache(2024)

# Force fresh download (bypass cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)
```

## Next Steps

- Use
  [`?fetch_enr`](https://almartin82.github.io/caschooldata/reference/fetch_enr.md)
  for full function documentation
- See
  [`?tidy_enr`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md)
  for details on the tidy transformation
- See
  [`?id_enr_aggs`](https://almartin82.github.io/caschooldata/reference/id_enr_aggs.md)
  for aggregation level identification
- See
  [`?enr_grade_aggs`](https://almartin82.github.io/caschooldata/reference/enr_grade_aggs.md)
  for grade-level aggregations (K-8, HS, K-12)
