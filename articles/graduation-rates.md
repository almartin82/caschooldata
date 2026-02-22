# California Graduation Rate Analysis

## Overview

California’s graduation rates vary significantly across districts,
demographics, and student groups. This vignette shows how to fetch and
analyze graduation rate data from the California Department of
Education.

**Key insights you’ll discover:** - Statewide graduation rates have
improved from 84% to 88% since 2018 - Significant disparities exist
across demographic groups - Top-performing districts consistently
maintain 97%+ graduation rates - The gap between Asian and Black
students is 13 percentage points

## Fetching Graduation Data

### Single Year

Fetch graduation rates for a specific school year:

``` r
library(caschooldata)
library(dplyr)
library(ggplot2)

# Get 2024 graduation rates (2023-24 school year)
grad_2024 <- fetch_graduation(2024, use_cache = TRUE)

# Statewide overview
state_overview <- grad_2024 %>%
  filter(is_state, subgroup == "all") %>%
  select(grad_rate, cohort_count, graduate_count)

stopifnot(nrow(state_overview) > 0)
state_overview
```

    ##   grad_rate cohort_count graduate_count
    ## 1     0.867       517434         448696

### Multiple Years

Fetch multiple years for trend analysis:

``` r
# Get multiple years of graduation data
# Available years: 2018, 2019, 2022, 2024, 2025 (gaps due to CDE reporting changes)
grad_multi <- fetch_graduation_multi(c(2018, 2019, 2022, 2024, 2025), use_cache = TRUE)

# Check available years
grad_multi %>%
  filter(is_state, subgroup == "all") %>%
  select(end_year, grad_rate, cohort_count)
```

    ##   end_year grad_rate cohort_count
    ## 1     2018     0.835       518317
    ## 2     2019     0.858       508055
    ## 3     2022     0.874       512524
    ## 4     2024     0.867       517434
    ## 5     2025     0.878       507889

## Statewide Trends

### Overall Graduation Rate Trend

``` r
state_trend <- grad_multi %>%
  filter(is_state, subgroup == "all")

stopifnot(nrow(state_trend) > 0)

state_trend %>%
  select(end_year, grad_rate) %>%
  print()
```

    ##   end_year grad_rate
    ## 1     2018     0.835
    ## 2     2019     0.858
    ## 3     2022     0.874
    ## 4     2024     0.867
    ## 5     2025     0.878

``` r
ggplot(state_trend, aes(x = end_year, y = grad_rate)) +
  geom_line(linewidth = 1, color = "#0078D4") +
  geom_point(size = 3, color = "#0078D4") +
  geom_text(aes(label = paste0(round(grad_rate * 100, 1), "%")),
            vjust = -1, size = 3.5) +
  labs(
    title = "California Statewide Graduation Rate Trend",
    subtitle = "4-year cohort, all students (2018-2025)",
    x = "School Year End",
    y = "Graduation Rate",
    caption = "Source: California Department of Education"
  ) +
  scale_y_continuous(limits = c(0.80, 0.95),
                     labels = scales::percent_format(accuracy = 1)) +
  theme_minimal()
```

![California statewide graduation rate
trend](graduation-rates_files/figure-html/state-trend-1.png)

California statewide graduation rate trend

**Key Finding:** Statewide graduation rates have improved from about 84%
in 2018 to 88% in 2025, with data gaps in 2020-2021 and 2023 due to
pandemic reporting changes.

## Demographic Disparities

### Graduation Rates by Student Group

``` r
demo_data <- grad_2024 %>%
  filter(
    is_state,
    subgroup %in% c("all", "hispanic", "white", "asian", "black", "low_income")
  )

stopifnot(nrow(demo_data) > 0)

demo_data %>%
  select(subgroup, grad_rate, cohort_count) %>%
  arrange(desc(grad_rate)) %>%
  print()
```

    ##     subgroup grad_rate cohort_count
    ## 1      asian     0.922        48266
    ## 2      white     0.892       107494
    ## 3        all     0.867       517434
    ## 4   hispanic     0.853       293952
    ## 5 low_income     0.844       379711
    ## 6      black     0.791        27002

``` r
demo_data %>%
  arrange(desc(grad_rate)) %>%
  mutate(subgroup = factor(subgroup, levels = subgroup)) %>%
  ggplot(aes(x = subgroup, y = grad_rate, fill = subgroup)) +
  geom_col() +
  geom_text(aes(label = paste0(round(grad_rate * 100, 1), "%")),
            hjust = -0.1, size = 3.5) +
  coord_flip() +
  labs(
    title = "California Graduation Rates by Demographic Group (2024)",
    subtitle = "Significant disparities exist across student groups",
    x = "",
    y = "Graduation Rate",
    caption = "Source: California Department of Education"
  ) +
  scale_y_continuous(limits = c(0, 1.05),
                     labels = scales::percent_format(accuracy = 1)) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal() +
  theme(legend.position = "none")
```

![Graduation rates by demographic group
2024](graduation-rates_files/figure-html/demographic-chart-1.png)

Graduation rates by demographic group 2024

**Key Finding:** Graduation rates vary by demographic group, with Asian
students graduating at about 92% and Black students at about 79% – a 13
percentage point gap.

## District-Level Analysis

### Top Performing Districts

``` r
top_districts <- grad_2024 %>%
  filter(
    is_district,
    subgroup == "all",
    cohort_count >= 500
  ) %>%
  arrange(desc(grad_rate)) %>%
  head(10)

stopifnot(nrow(top_districts) > 0)

top_districts %>%
  select(district_name, grad_rate, cohort_count) %>%
  print()
```

    ##                     district_name grad_rate cohort_count
    ## 1         Manhattan Beach Unified     0.994          631
    ## 2  Palos Verdes Peninsula Unified     0.988          981
    ## 3               Claremont Unified     0.979          613
    ## 4         Murrieta Valley Unified     0.977         2085
    ## 5         Tulare Joint Union High     0.976         1270
    ## 6            Tamalpais Union High     0.975         1285
    ## 7             Acalanes Union High     0.974         1351
    ## 8     Santa Monica-Malibu Unified     0.974          797
    ## 9        San Ramon Valley Unified     0.973         2692
    ## 10                 Dublin Unified     0.972          928

``` r
ggplot(top_districts, aes(x = reorder(district_name, grad_rate), y = grad_rate)) +
  geom_col(fill = "#107C41") +
  geom_text(aes(label = paste0(round(grad_rate * 100, 1), "%")),
            hjust = -0.1, size = 3) +
  coord_flip() +
  labs(
    title = "Top 10 California Districts by Graduation Rate (2024)",
    subtitle = "Districts with 500+ student cohorts",
    x = "",
    y = "Graduation Rate",
    caption = "Source: California Department of Education"
  ) +
  scale_y_continuous(limits = c(0, 1.05),
                     labels = scales::percent_format(accuracy = 1)) +
  theme_minimal()
```

![Top 10 districts by graduation
rate](graduation-rates_files/figure-html/top-districts-1.png)

Top 10 districts by graduation rate

### Finding Districts with Improving Trends

``` r
# Identify districts with improvement over time
# Use district_id to avoid issues with duplicate district names across counties
district_trends <- grad_multi %>%
  filter(
    is_district,
    subgroup == "all",
    cohort_count >= 100
  ) %>%
  group_by(district_id, district_name) %>%
  filter(n() >= 3) %>%  # Districts with at least 3 data points
  summarize(
    first_year = min(end_year),
    last_year = max(end_year),
    first_rate = grad_rate[end_year == min(end_year)],
    last_rate = grad_rate[end_year == max(end_year)],
    improvement = grad_rate[end_year == max(end_year)] - grad_rate[end_year == min(end_year)],
    .groups = "drop"
  ) %>%
  filter(!is.na(improvement)) %>%
  arrange(desc(improvement)) %>%
  head(10)

stopifnot(nrow(district_trends) > 0)

district_trends %>%
  mutate(
    first_rate_pct = paste0(round(first_rate * 100, 1), "%"),
    last_rate_pct = paste0(round(last_rate * 100, 1), "%"),
    improvement_pct = paste0("+", round(improvement * 100, 1), "%")
  ) %>%
  select(district_name, first_year, last_year, first_rate_pct, last_rate_pct, improvement_pct)
```

    ## # A tibble: 10 × 6
    ##    district_name               first_year last_year first_rate_pct last_rate_pct
    ##    <chr>                            <dbl>     <dbl> <chr>          <chr>        
    ##  1 San Joaquin County Office …       2018      2025 33.7%          56%          
    ##  2 Los Angeles County Office …       2018      2025 55.3%          76.8%        
    ##  3 Merced County Office of Ed…       2018      2025 59.6%          77.6%        
    ##  4 Mendota Unified                   2018      2025 74.3%          91.8%        
    ##  5 San Diego County Office of…       2018      2025 40.2%          57.6%        
    ##  6 Santa Cruz County Office o…       2018      2025 63.1%          79.8%        
    ##  7 Fortuna Union High                2018      2025 75.4%          91.3%        
    ##  8 Konocti Unified                   2018      2025 69.6%          85%          
    ##  9 San Francisco County Offic…       2022      2025 50.4%          63.6%        
    ## 10 Yreka Union High                  2018      2025 81.5%          94%          
    ## # ℹ 1 more variable: improvement_pct <chr>

### Case Study: High-Performing Districts vs State Average

``` r
# Select top 5 districts by graduation rate
top5_names <- grad_2024 %>%
  filter(
    is_district,
    subgroup == "all",
    cohort_count >= 500
  ) %>%
  arrange(desc(grad_rate)) %>%
  head(5) %>%
  pull(district_name)

# Compare these districts with state average over time
case_study <- grad_multi %>%
  filter(
    subgroup == "all",
    is_state | district_name %in% top5_names
  ) %>%
  mutate(
    label = ifelse(is_state, "State Average", district_name)
  )

stopifnot(nrow(case_study) > 0)

case_study %>%
  dplyr::as_tibble() %>%
  select(end_year, label, grad_rate) %>%
  print(n = 30)
```

    ## # A tibble: 112 × 3
    ##    end_year label                          grad_rate
    ##       <dbl> <chr>                              <dbl>
    ##  1     2018 State Average                      0.835
    ##  2     2018 Claremont Unified                  0.946
    ##  3     2018 Claremont Unified                  0.571
    ##  4     2018 Claremont Unified                  0.96 
    ##  5     2018 Palos Verdes Peninsula Unified     0.983
    ##  6     2018 Palos Verdes Peninsula Unified     1    
    ##  7     2018 Palos Verdes Peninsula Unified     0.982
    ##  8     2018 Palos Verdes Peninsula Unified     0.983
    ##  9     2018 Manhattan Beach Unified            0.99 
    ## 10     2018 Manhattan Beach Unified            0.993
    ## 11     2018 Murrieta Valley Unified            0.976
    ## 12     2018 Murrieta Valley Unified            0.978
    ## 13     2018 Murrieta Valley Unified            0.899
    ## 14     2018 Murrieta Valley Unified            0.982
    ## 15     2018 Murrieta Valley Unified            0.986
    ## 16     2018 Tulare Joint Union High            0.961
    ## 17     2018 Tulare Joint Union High            0.957
    ## 18     2018 Tulare Joint Union High            0.976
    ## 19     2018 Tulare Joint Union High            0.874
    ## 20     2018 Tulare Joint Union High            0.765
    ## 21     2018 Tulare Joint Union High            0.985
    ## 22     2018 Tulare Joint Union High            0.957
    ## 23     2019 State Average                      0.858
    ## 24     2019 Claremont Unified                  0.943
    ## 25     2019 Claremont Unified                  0.762
    ## 26     2019 Claremont Unified                  0.95 
    ## 27     2019 Palos Verdes Peninsula Unified     0.981
    ## 28     2019 Palos Verdes Peninsula Unified     1    
    ## 29     2019 Palos Verdes Peninsula Unified     0.984
    ## 30     2019 Palos Verdes Peninsula Unified     0.978
    ## # ℹ 82 more rows

``` r
ggplot(case_study, aes(x = end_year, y = grad_rate, color = label, group = label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Graduation Rate Trends: Top Districts vs State Average",
    subtitle = "High-performing districts consistently maintain >95% graduation rates",
    x = "School Year End",
    y = "Graduation Rate",
    color = "",
    caption = "Source: California Department of Education"
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_color_brewer(palette = "Set1") +
  theme_minimal() +
  theme(legend.position = "bottom")
```

![District comparison: top performers vs state
average](graduation-rates_files/figure-html/case-study-1.png)

District comparison: top performers vs state average

## Data Quality Notes

### Coverage and Limitations

``` r
# Check data coverage by year
grad_multi %>%
  filter(subgroup == "all") %>%
  group_by(end_year) %>%
  summarise(
    n_schools = sum(type == "School" & !is.na(grad_rate)),
    n_districts = sum(type == "District" & !is.na(grad_rate)),
    .groups = "drop"
  )
```

    ## # A tibble: 5 × 3
    ##   end_year n_schools n_districts
    ##      <dbl>     <int>       <int>
    ## 1     2018      2217         449
    ## 2     2019      2237         446
    ## 3     2022      2299         444
    ## 4     2024      2312         446
    ## 5     2025      2294         441

**Important notes:** - Data available from 2018 onwards (2017 URL
returns 404) - No data for 2020, 2021, or 2023 due to pandemic-related
reporting changes - Small schools/districts may have suppressed data for
privacy - Graduation rates calculated per California’s adjusted cohort
formula - Some student groups may have small cohort sizes affecting
reliability

## Advanced Analysis

### Identifying Outlier Schools

``` r
# Find schools with unusual graduation rates (for investigation)
outliers <- grad_2024 %>%
  filter(
    type == "School",
    subgroup == "all",
    cohort_count >= 30,
    !is.na(grad_rate)
  ) %>%
  mutate(
    z_score = scale(grad_rate)[,1],
    is_outlier = abs(z_score) > 2
  ) %>%
  filter(is_outlier) %>%
  arrange(desc(abs(z_score))) %>%
  select(school_name, district_name, grad_rate, cohort_count, z_score) %>%
  head(10)

outliers
```

    ##                                                         school_name
    ## 1    Joseph Pomeroy Widney Career Preparatory and Transition Center
    ## 2                                    Berenece Carlson Home Hospital
    ## 3                                                             TRACE
    ## 4                                                 Special Education
    ## 5                              Santa Clara County Special Education
    ## 6                                       Highlands Community Charter
    ## 7                          Five Keys Independence HS (SF Sheriff's)
    ## 8  Escuela Popular/Center for Training and Careers, Family Learning
    ## 9                                  Five Keys Charter (SF Sheriff's)
    ## 10                          San Bernardino County Special Education
    ##                                district_name grad_rate cohort_count   z_score
    ## 1                        Los Angeles Unified     0.000           40 -4.863299
    ## 2                        Los Angeles Unified     0.000           61 -4.863299
    ## 3                          San Diego Unified     0.000           56 -4.863299
    ## 4          Tulare County Office of Education     0.000           71 -4.863299
    ## 5     Santa Clara County Office of Education     0.015           68 -4.777873
    ## 6                        Twin Rivers Unified     0.028         3643 -4.703838
    ## 7                      San Francisco Unified     0.032         2284 -4.681058
    ## 8                       East Side Union High     0.033          510 -4.675363
    ## 9                      San Francisco Unified     0.034          236 -4.669668
    ## 10 San Bernardino County Office of Education     0.043           94 -4.618412

These schools merit further investigation to understand best practices
or areas needing support.

## Summary

This vignette demonstrated how to:

1.  **Fetch** graduation rate data for single or multiple years
2.  **Analyze** statewide trends and district performance
3.  **Compare** graduation rates across demographic groups
4.  **Identify** disparities and high-performing districts

**Next steps:** - Explore the `district-highlights` vignette for deeper
enrollment analysis - Use `data-quality-qa` vignette to understand data
quality considerations - Combine enrollment and graduation data for
comprehensive analyses

For more information, see the [caschooldata
documentation](https://almartin82.github.io/caschooldata/).

## Session Info

``` r
sessionInfo()
```

    ## R version 4.5.2 (2025-10-31)
    ## Platform: x86_64-pc-linux-gnu
    ## Running under: Ubuntu 24.04.3 LTS
    ## 
    ## Matrix products: default
    ## BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
    ## LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
    ## 
    ## locale:
    ##  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
    ##  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
    ##  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    ## [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
    ## 
    ## time zone: UTC
    ## tzcode source: system (glibc)
    ## 
    ## attached base packages:
    ## [1] stats     graphics  grDevices utils     datasets  methods   base     
    ## 
    ## other attached packages:
    ## [1] ggplot2_4.0.2      dplyr_1.2.0        caschooldata_0.1.0 testthat_3.3.2    
    ## 
    ## loaded via a namespace (and not attached):
    ##  [1] gtable_0.3.6       jsonlite_2.0.0     compiler_4.5.2     brio_1.1.5        
    ##  [5] tidyselect_1.2.1   jquerylib_0.1.4    systemfonts_1.3.1  scales_1.4.0      
    ##  [9] textshaping_1.0.4  readxl_1.4.5       yaml_2.3.12        fastmap_1.2.0     
    ## [13] R6_2.6.1           labeling_0.4.3     generics_0.1.4     curl_7.0.0        
    ## [17] knitr_1.51         tibble_3.3.1       desc_1.4.3         bslib_0.10.0      
    ## [21] pillar_1.11.1      RColorBrewer_1.1-3 rlang_1.1.7        utf8_1.2.6        
    ## [25] cachem_1.1.0       xfun_0.56          fs_1.6.6           sass_0.4.10       
    ## [29] S7_0.2.1           cli_3.6.5          withr_3.0.2        pkgdown_2.2.0     
    ## [33] magrittr_2.0.4     digest_0.6.39      grid_4.5.2         rappdirs_0.3.4    
    ## [37] lifecycle_1.0.5    vctrs_0.7.1        evaluate_1.0.5     glue_1.8.0        
    ## [41] cellranger_1.1.0   farver_2.1.2       codetools_0.2-20   ragg_1.5.0        
    ## [45] purrr_1.2.1        httr_1.4.8         rmarkdown_2.30     tools_4.5.2       
    ## [49] pkgconfig_2.0.3    htmltools_0.5.9
