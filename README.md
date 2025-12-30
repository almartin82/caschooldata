# caschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/caschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/almartin82/caschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**[Documentation Site](https://almartin82.github.io/caschooldata/)**

An R package for fetching and processing California school enrollment data from the California Department of Education (CDE).

## Data Highlights: What You'll Find

California's 5.8+ million student public school system has undergone dramatic shifts. Here's what the data reveals:

| # | Finding | Key Metric |
|---|---------|------------|
| 1 | **Statewide enrollment collapse** | 400,000+ students lost since 2020 (~7% decline) |
| 2 | **LAUSD exodus** | Nation's 2nd-largest district lost 80,000+ students |
| 3 | **Top 5 districts hemorrhaging** | 100,000+ students lost combined |
| 4 | **Hispanic majority** | Now 56% of California's enrollment |
| 5 | **District divergence** | Some districts grew while most contracted |
| 6 | **High school hit first** | Secondary grades dropped faster than elementary |
| 7 | **Bay Area flight** | San Francisco, Santa Clara counties hit hardest |
| 8 | **Kindergarten warning** | K enrollment drop signals more decline ahead |
| 9 | **Gender ratio stable** | Male/female split unchanged at ~51/49 |
| 10 | **English Learners** | 18%+ of students, a major population |

See the full analysis with visualizations in the [District Highlights vignette](https://almartin82.github.io/caschooldata/articles/district-highlights.html).

## Overview

`caschooldata` provides a simple interface to download, process, and analyze California public school enrollment data. The package handles:
- Downloading enrollment data from CDE DataQuest
- Processing raw data into a standardized schema
- Converting to tidy (long) format for analysis
- Local caching to speed up repeated queries

## Installation

Install from GitHub using the `remotes` package:

```r
# install.packages("remotes")
remotes::install_github("almartin82/caschooldata")
```

## Quick Start

### Fetch enrollment data

```r
library(caschooldata)
library(dplyr)

# Fetch 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

# View the data
head(enr)
```

### Filter to specific levels

```r
# State totals
state_total <- enr %>%
  filter(is_state, subgroup == "total", grade_level == "TOTAL")

# All districts
districts <- enr %>%
  filter(is_district, subgroup == "total", grade_level == "TOTAL")

# All schools
schools <- enr %>%
  filter(is_school, subgroup == "total", grade_level == "TOTAL")
```
### Analyze demographics

```r
# State-level demographic breakdown
enr %>%
  filter(is_state, grade_level == "TOTAL") %>%
  select(subgroup, n_students) %>%
  arrange(desc(n_students))
```

### Work with wide format

```r
# Get wide format (one column per grade)
enr_wide <- fetch_enr(2024, tidy = FALSE)
```

### Fetch multiple years

```r
# Get data for multiple years
all_years <- fetch_enr_multi(c(2024, 2025))
```

## Available Data

### Years

Eight years of Census Day enrollment data (2018-2025):

- **2024-2025** (modern format): Full demographic breakdowns, all aggregation levels, TK data
- **2018-2023** (historical format): School-level race/ethnicity and gender data

```r
# Fetch multi-year data for trend analysis
enr_all <- fetch_enr_multi(2018:2025)
```

### Aggregation Levels

- **State** (`agg_level = "T"`, `is_state = TRUE`): Statewide totals
- **County** (`agg_level = "C"`, `is_county = TRUE`): 58 California counties
- **District** (`agg_level = "D"`, `is_district = TRUE`): All school districts
- **School** (`agg_level = "S"`, `is_school = TRUE`): Individual schools

### Demographic Subgroups

The `reporting_category` and `subgroup` columns include:
- **Total enrollment** (`TA` / `total`)
- **Race/Ethnicity**: Hispanic, White, Asian, Black, Filipino, Pacific Islander, Native American, Multiracial
- **Gender**: Female, Male, Nonbinary
- **Student Groups**: English Learners, Students with Disabilities, Socioeconomically Disadvantaged, Foster Youth, Homeless, Migrant

### Grade Levels

- Individual grades: TK, K, 01-12
- Total: TOTAL
- Grade band aggregations available via `enr_grade_aggs()`: K8, HS, K12

## Data Source

Data is sourced from the California Department of Education:
- **DataQuest**: https://dq.cde.ca.gov/dataquest/
- **Data Files**: https://www.cde.ca.gov/ds/

Enrollment counts are based on Census Day (first Wednesday in October).

## Documentation

For full documentation, see the [pkgdown site](https://almartin82.github.io/caschooldata/).

## License

MIT License
