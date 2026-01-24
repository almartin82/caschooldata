# caschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/caschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/caschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/caschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/caschooldata/)** | **[Getting Started](https://almartin82.github.io/caschooldata/articles/quickstart.html)** | **[Full Analysis](https://almartin82.github.io/caschooldata/articles/district-highlights.html)**

Fetch and analyze California school enrollment data from the California Department of Education in R or Python.

Part of the [njschooldata](https://github.com/almartin82/njschooldata) family of state education data packages, providing programmatic access to official state DOE data with a consistent API across all 50 states.

## What can you find with caschooldata?

**44 years of enrollment data (1982-2025).** 5.8 million students today. Over 1,000 districts. Here are fifteen stories hiding in the numbers:

---

### 1. California lost 400,000+ students since 2020

The most striking trend: California public schools have lost over 400,000 students since the pandemic began. This represents a decline of roughly 7% in just five years.

```r
library(caschooldata)
library(dplyr)

enr <- fetch_enr_multi(2018:2025)

state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA") %>%
  arrange(end_year) %>%
  mutate(
    cumulative_change = n_students - first(n_students),
    pct_change = (n_students - first(n_students)) / first(n_students) * 100
  )

state_trend %>%
  select(end_year, n_students, cumulative_change, pct_change)
```

![State enrollment trend](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/finding-1-1.png)

---

### 2. LAUSD has lost the equivalent of a major city's school district

Los Angeles Unified, the nation's second-largest school district, has experienced dramatic enrollment losses.

```r
lausd <- enr %>%
  filter(
    is_district,
    grade_level == "TOTAL",
    reporting_category == "TA",
    grepl("Los Angeles Unified", district_name, ignore.case = TRUE)
  ) %>%
  arrange(end_year) %>%
  mutate(
    change = n_students - lag(n_students),
    cumulative_change = n_students - first(n_students)
  )

lausd %>%
  select(end_year, n_students, change, cumulative_change)
```

![LAUSD decline](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/finding-2-1.png)

---

### 3. The top 5 districts lost over 100,000 students combined

California's five largest districts all face significant enrollment challenges.

```r
# Find the 5 largest districts (by 2025 enrollment)
top5_districts <- enr %>%
  filter(
    is_district,
    end_year == max(end_year),
    grade_level == "TOTAL",
    reporting_category == "TA"
  ) %>%
  arrange(desc(n_students)) %>%
  head(5) %>%
  pull(district_name)

top5_trend <- enr %>%
  filter(
    is_district,
    grade_level == "TOTAL",
    reporting_category == "TA",
    district_name %in% top5_districts
  ) %>%
  arrange(district_name, end_year)

top5_trend %>%
  group_by(district_name) %>%
  summarize(
    enr_first = first(n_students),
    enr_last = last(n_students),
    change = last(n_students) - first(n_students),
    pct_change = (last(n_students) - first(n_students)) / first(n_students) * 100
  )
```

![Top 5 districts](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/finding-3-1.png)

---

### 4. Hispanic students now comprise 56% of California's enrollment

California's demographic makeup has shifted significantly over the past few decades.

```r
race_by_year <- enr %>%
  filter(
    is_state,
    grade_level == "TOTAL",
    grepl("^RE_", reporting_category)
  ) %>%
  group_by(end_year) %>%
  mutate(
    total = sum(n_students, na.rm = TRUE),
    pct = n_students / total * 100
  ) %>%
  ungroup()

race_by_year %>%
  filter(end_year == max(end_year)) %>%
  arrange(desc(pct)) %>%
  select(subgroup, n_students, pct)
```

![Demographics](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/finding-4-1.png)

---

### 5. Some districts grew while others collapsed

Not all districts experienced decline. A handful of districts bucked the statewide trend with substantial growth since 2020.

```r
district_changes <- enr %>%
  filter(
    is_district,
    grade_level == "TOTAL",
    reporting_category == "TA",
    end_year %in% c(2020, max(end_year))
  ) %>%
  tidyr::pivot_wider(
    id_cols = c(district_name, county_name, cds_code),
    names_from = end_year,
    values_from = n_students,
    names_prefix = "enr_"
  ) %>%
  filter(!is.na(enr_2020) & enr_2020 > 1000) %>%
  mutate(
    change = enr_2025 - enr_2020,
    pct_change = change / enr_2020 * 100
  )

# Top 10 growing districts
district_changes %>%
  arrange(desc(pct_change)) %>%
  head(10) %>%
  select(district_name, county_name, enr_2020, change, pct_change)
```

---

### 6. High school enrollment dropped faster than elementary

Enrollment loss varied significantly by grade level, with high schools seeing the earliest and steepest declines.

```r
grade_trends <- enr %>%
  filter(
    is_state,
    reporting_category == "TA",
    grade_level %in% c("K", "01", "02", "03", "04", "05",
                        "06", "07", "08", "09", "10", "11", "12")
  ) %>%
  mutate(
    grade_band = case_when(
      grade_level %in% c("K", "01", "02", "03", "04", "05") ~ "Elementary (K-5)",
      grade_level %in% c("06", "07", "08") ~ "Middle (6-8)",
      TRUE ~ "High (9-12)"
    )
  ) %>%
  group_by(end_year, grade_band) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

grade_trends %>%
  group_by(grade_band) %>%
  mutate(index = n_students / first(n_students) * 100)
```

![Grade bands](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/grade-bands-1.png)

---

### 7. The Bay Area exodus: Tech counties lost the most students

San Francisco, Santa Clara, and other Bay Area counties experienced some of the steepest enrollment drops percentage-wise.

```r
county_changes <- enr %>%
  filter(
    is_county,
    grade_level == "TOTAL",
    reporting_category == "TA",
    end_year %in% c(2020, max(end_year))
  ) %>%
  tidyr::pivot_wider(
    id_cols = c(county_name),
    names_from = end_year,
    values_from = n_students,
    names_prefix = "enr_"
  ) %>%
  filter(!is.na(enr_2020)) %>%
  mutate(
    change = enr_2025 - enr_2020,
    pct_change = change / enr_2020 * 100
  ) %>%
  arrange(pct_change)

# Top 10 counties with biggest percentage decline
county_changes %>%
  head(10) %>%
  select(county_name, enr_2020, change, pct_change)
```

![County analysis](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/county-analysis-1.png)

---

### 8. Kindergarten enrollment signals future decline

Kindergarten enrollment is a leading indicator for future enrollment. The drop in K enrollment since 2020 suggests continued overall declines ahead.

```r
k_trend <- enr %>%
  filter(
    is_state,
    reporting_category == "TA",
    grade_level == "K"
  ) %>%
  arrange(end_year) %>%
  mutate(
    change = n_students - lag(n_students),
    pct_change = (n_students - lag(n_students)) / lag(n_students) * 100
  )

k_trend %>%
  select(end_year, n_students, change, pct_change)
```

![Kindergarten trend](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/kindergarten-1.png)

---

### 9. Gender ratios have remained remarkably stable

Despite major enrollment shifts, the gender ratio has stayed nearly constant at roughly 51% male, 49% female.

```r
gender_trend <- enr %>%
  filter(
    is_state,
    grade_level == "TOTAL",
    reporting_category %in% c("GN_F", "GN_M")
  ) %>%
  group_by(end_year) %>%
  mutate(
    total = sum(n_students),
    pct = n_students / total * 100
  ) %>%
  ungroup()

gender_trend %>%
  select(end_year, subgroup, n_students, pct) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = c(n_students, pct))
```

![Gender distribution](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/gender-1.png)

---

### 10. English Learners remain a substantial population

English Learners represent approximately 18% of California's student population (data available for 2024-2025).

```r
el_data <- enr %>%
  filter(
    is_state,
    grade_level == "TOTAL",
    reporting_category %in% c("TA", "SG_EL"),
    end_year >= 2024
  ) %>%
  tidyr::pivot_wider(
    id_cols = end_year,
    names_from = reporting_category,
    values_from = n_students
  ) %>%
  mutate(el_pct = SG_EL / TA * 100)

el_data
```

---

### 11. State enrollment peaked around 2003-04 at 6.3 million

California's K-12 enrollment peaked around 2003-04 at 6.3 million students. Today it's under 5.8 million, a decline of nearly half a million students from the peak.

```r
enr_historical <- fetch_enr_multi(c(1985, 1995, 2005, 2015, 2025))

enr_historical %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA") %>%
  select(end_year, n_students)
```

![State trend long-term](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/state-trend-1.png)

---

### 12. LAUSD has seen a multi-decade decline

The nation's second-largest district has lost nearly half its enrollment since its peak, making it a case study in urban enrollment decline.

```r
lausd_long <- fetch_enr_multi(c(1990, 2000, 2010, 2020, 2025))

lausd_long %>%
  filter(is_district, grepl("Los Angeles Unified", district_name),
         grade_level == "TOTAL", reporting_category == "TA") %>%
  select(end_year, district_name, n_students)
```

![LAUSD long-term](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/lausd-1.png)

---

### 13. California's largest districts dominate enrollment

The top 5 districts alone account for a significant share of California's total enrollment, with LAUSD enrolling more students than many states.

```r
enr_2025 <- fetch_enr(2025)

enr_2025 %>%
  filter(is_district, grade_level == "TOTAL", reporting_category == "TA") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, county_name, n_students)
```

![Top districts](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/top5-1.png)

---

### 14. Demographics vary dramatically across major districts

While the state overall is majority Hispanic, individual districts show vastly different demographic compositions: majority Hispanic in LA and Fresno, highly diverse in SF and San Diego.

```r
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL", grepl("^RE_", reporting_category)) %>%
  filter(district_name %in% c("San Francisco Unified", "Los Angeles Unified",
                               "Fresno Unified", "San Diego Unified")) %>%
  group_by(district_name, subgroup) %>%
  summarize(n = sum(n_students), .groups = "drop") %>%
  group_by(district_name) %>%
  mutate(pct = n / sum(n) * 100) %>%
  tidyr::pivot_wider(id_cols = district_name, names_from = subgroup, values_from = pct)
```

![Demographics by district](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/demographics-1.png)

---

### 15. Enrollment declined every year since 2020

California has seen consistent year-over-year enrollment declines since 2020, with no year showing a recovery.

```r
enr_recent <- fetch_enr_multi(2018:2025)

state_yoy <- enr_recent %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA") %>%
  arrange(end_year) %>%
  mutate(
    prev_year = lag(n_students),
    change = n_students - prev_year,
    pct_change = (n_students - prev_year) / prev_year * 100
  )

state_yoy %>%
  select(end_year, n_students, change, pct_change)
```

![Year-over-year changes](https://almartin82.github.io/caschooldata/articles/data-quality-qa_files/figure-html/state-plot-1.png)

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/caschooldata")
```

## Quick start

### R

```r
library(caschooldata)
library(dplyr)

# Fetch one year
enr_2025 <- fetch_enr(2025)

# Fetch recent years (2018-2025)
enr_recent <- fetch_enr_multi(2018:2025)

# Fetch ALL 44 years of data (1982-2025)
enr_all <- fetch_enr_multi(1982:2025)

# State totals
enr_2025 %>%
  filter(is_state, subgroup == "total", grade_level == "TOTAL")

# District breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Demographics by district
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL", grepl("^RE_", reporting_category)) %>%
  group_by(district_name, subgroup) %>%
  summarize(n = sum(n_students))
```

### Python

```python
import pycaschooldata as ca

# Check available years
years = ca.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
enr_2025 = ca.fetch_enr(2025)

# Fetch multiple years
enr_recent = ca.fetch_enr_multi([2023, 2024, 2025])

# State totals
state_total = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['grade_level'] == 'TOTAL') &
    (enr_2025['subgroup'] == 'total')
]

# District breakdown
district_totals = enr_2025[
    (enr_2025['is_district'] == True) &
    (enr_2025['grade_level'] == 'TOTAL') &
    (enr_2025['subgroup'] == 'total')
].sort_values('n_students', ascending=False)
```

## Data availability

| Years | Source | Aggregation Levels | Demographics | Notes |
|-------|--------|-------------------|--------------|-------|
| **2024-2025** | Census Day files | State, County, District, School | Race, Gender, Student Groups (EL, FRPM, SWD, etc.) | Full detail, TK included |
| **2008-2023** | Historical files | School (aggregates computed) | Race, Gender | Entity names included |
| **1994-2007** | Historical files | School (aggregates computed) | Race, Gender | No entity names (CDS codes only) |
| **1982-1993** | Historical files | School (aggregates computed) | Race, Gender | Letter-based race codes (mapped) |

### What's available by year range

- **Subgroups**: Race/ethnicity and gender available for all years. Student groups (English Learners, FRPM, Special Ed) only available 2024+.
- **Grade levels**: K-12 available for all years. Transitional Kindergarten (TK) only available 2024+.
- **Aggregation**: Modern files (2024+) include pre-computed state/county/district totals. Historical files only have school-level data; this package computes aggregates automatically.
- **Entity names**: School/district names available 2008+ and 1982-1993. Not available for 1994-2007 (use CDS code lookups).

## Data Notes

- **Source**: California Department of Education [DataQuest](https://dq.cde.ca.gov/dataquest/) and [Data Files](https://www.cde.ca.gov/ds/)
- **Census Day**: All enrollment counts are from Census Day (first Wednesday in October)
- **Suppression**: Counts of 10 or fewer students are suppressed for privacy
- **Charter Status**: Modern files (2024+) report charter and non-charter separately; historical files aggregate all schools

## Part of the State Schooldata Project

This package is part of the [njschooldata](https://github.com/almartin82/njschooldata) family, providing a simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
