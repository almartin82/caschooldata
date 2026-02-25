# caschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/caschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/caschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/caschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/caschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/caschooldata/)** | **[Getting Started](https://almartin82.github.io/caschooldata/articles/quickstart.html)** | **[Enrollment Analysis](https://almartin82.github.io/caschooldata/articles/district-highlights.html)** | **[Assessment Analysis](https://almartin82.github.io/caschooldata/articles/california-assessment.html)**

Fetch and analyze California school enrollment and assessment data from the California Department of Education in R or Python.

Part of the [njschooldata](https://github.com/almartin82/njschooldata) family of state education data packages, providing programmatic access to official state DOE data with a consistent API across all 50 states.

## What can you find with caschooldata?

**44 years of enrollment data (1982-2025) plus CAASPP assessment results (2021-2025).** 5.8 million students today. Over 1,000 districts. Here are twenty stories hiding in the numbers:

---

### 1. California lost 400,000+ students since 2018

California public schools have lost over 400,000 students since 2018 when enrollment peaked at 6.22 million. By 2025, enrollment had fallen to 5.81 million — a decline of 6.7%.

```r
library(caschooldata)
library(dplyr)

enr <- fetch_enr_multi(2018:2025, use_cache = TRUE)

state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA",
         charter_status %in% c("All", NA)) %>%
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

Los Angeles Unified, the nation's second-largest school district, has lost over 100,000 students since 2018 — more than the entire enrollment of Fresno Unified.

```r
lausd <- enr %>%
  filter(
    is_district,
    grade_level == "TOTAL",
    reporting_category == "TA",
    charter_status %in% c("All", NA),
    grepl("Los Angeles Unified", district_name, ignore.case = TRUE)
  ) %>%
  arrange(end_year) %>%
  mutate(
    change = n_students - lag(n_students),
    cumulative_change = n_students - first(n_students)
  )

lausd %>% select(end_year, n_students, change, cumulative_change)
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
    reporting_category == "TA",
    charter_status %in% c("All", NA)
  ) %>%
  arrange(desc(n_students)) %>%
  head(5) %>%
  pull(district_name)

top5_trend <- enr %>%
  filter(
    is_district,
    grade_level == "TOTAL",
    reporting_category == "TA",
    charter_status %in% c("All", NA),
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

California's demographic makeup continues to shift. Hispanic students account for 56.1% of enrollment, white students 20%, and Asian students 10.1%.

```r
race_by_year <- enr %>%
  filter(
    is_state,
    grade_level == "TOTAL",
    charter_status %in% c("All", NA),
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
    charter_status %in% c("All", NA),
    end_year %in% c(2020, max(end_year))
  ) %>%
  tidyr::pivot_wider(
    id_cols = c(district_name, county_name, cds_code),
    names_from = end_year,
    values_from = n_students,
    names_prefix = "enr_"
  ) %>%
  filter(!is.na(enr_2020) & enr_2020 > 1000)

# Top 10 growing districts
district_changes %>%
  arrange(desc(pct_change)) %>%
  head(10) %>%
  select(district_name, county_name, enr_2020, change, pct_change)
```

---

### 6. Elementary enrollment dropped fastest — down 14%

Elementary (K-5) enrollment plummeted 14.3% from 2018 to 2025, while high school declined only 2.8%. Fewer births and kindergarten no-shows are hitting elementary hardest.

```r
grade_trends <- enr %>%
  filter(
    is_state,
    reporting_category == "TA",
    charter_status %in% c("All", NA),
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
    charter_status %in% c("All", NA),
    end_year %in% c(2020, max(end_year))
  ) %>%
  tidyr::pivot_wider(
    id_cols = c(county_name),
    names_from = end_year,
    values_from = n_students,
    names_prefix = "enr_"
  ) %>%
  filter(!is.na(enr_2020)) %>%
  arrange(pct_change)

# Top 10 counties with biggest percentage decline
county_changes %>%
  head(10) %>%
  select(county_name, enr_2020, change, pct_change)
```

![County analysis](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/county-analysis-1.png)

---

### 8. Kindergarten enrollment signals future decline

Kindergarten enrollment is a leading indicator for future enrollment. K enrollment dropped sharply in 2021 (COVID effect), partially recovered, then fell again in 2024-2025.

```r
k_trend <- enr %>%
  filter(
    is_state,
    reporting_category == "TA",
    charter_status %in% c("All", NA),
    grade_level == "K"
  ) %>%
  arrange(end_year) %>%
  mutate(
    change = n_students - lag(n_students),
    pct_change = (n_students - lag(n_students)) / lag(n_students) * 100
  )

k_trend %>% select(end_year, n_students, change, pct_change)
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
    charter_status %in% c("All", NA),
    reporting_category %in% c("GN_F", "GN_M")
  ) %>%
  group_by(end_year) %>%
  mutate(
    total = sum(n_students),
    pct = n_students / total * 100
  ) %>%
  ungroup()

gender_trend %>%
  select(end_year, subgroup, pct) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = pct)
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
    charter_status %in% c("All", NA),
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
enr_historical <- fetch_enr_multi(c(1985, 1995, 2005, 2015, 2025), use_cache = TRUE)

enr_historical %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA",
         charter_status %in% c("All", NA)) %>%
  select(end_year, n_students)
```

![State trend long-term](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/state-trend-1.png)

---

### 12. LAUSD has seen a multi-decade decline

The nation's second-largest district has lost nearly half its enrollment since its peak, making it a case study in urban enrollment decline.

```r
lausd_long <- fetch_enr_multi(c(1990, 2000, 2010, 2020, 2025), use_cache = TRUE)

lausd_long %>%
  filter(is_district, grepl("Los Angeles Unified", district_name),
         grade_level == "TOTAL", reporting_category == "TA",
         charter_status %in% c("All", NA)) %>%
  select(end_year, district_name, n_students)
```

![LAUSD long-term](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/lausd-1.png)

---

### 13. California's largest districts dominate enrollment

The top 10 districts alone account for a significant share of California's total enrollment, with LAUSD enrolling more students than many states.

```r
enr_2025 <- fetch_enr(2025, use_cache = TRUE)

enr_2025 %>%
  filter(is_district, grade_level == "TOTAL", reporting_category == "TA",
         charter_status %in% c("All", NA)) %>%
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
  filter(is_district, grade_level == "TOTAL",
         charter_status %in% c("All", NA),
         grepl("^RE_", reporting_category)) %>%
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

### 15. Enrollment declined every year since 2018

California has seen consistent year-over-year enrollment declines since 2018, with no year showing a recovery.

```r
state_yoy <- enr %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA",
         charter_status %in% c("All", NA)) %>%
  arrange(end_year) %>%
  mutate(
    prev_year = lag(n_students),
    change = n_students - prev_year,
    pct_change = (n_students - prev_year) / prev_year * 100
  )

state_yoy %>%
  select(end_year, n_students, change, pct_change)
```

![Year-over-year changes](https://almartin82.github.io/caschooldata/articles/district-highlights_files/figure-html/yoy-changes-1.png)

---

## Assessment Data: CAASPP Results

California's CAASPP (California Assessment of Student Performance and Progress) system includes the Smarter Balanced assessments for English Language Arts (ELA) and Mathematics. Data available from 2021-2025 (no 2020 due to COVID-19).

---

### 16. Grade 11 proficiency: 55.7% in ELA, 27.9% in Math

California's 11th graders showed a nearly 28-point gap between ELA and Math proficiency in 2024. Less than a third of juniors met standards in Math.

```r
library(caschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)

# Set theme
theme_set(theme_minimal(base_size = 12))

# Fetch 2024 assessment data
assess_2024 <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)

# State-level proficiency by subject (Grade 11)
state_g11 <- assess_2024 %>%
  filter(is_state, grade == "11", metric_type == "pct_met_and_above") %>%
  select(subject, metric_value)

state_g11
```

![Grade 11 Proficiency](https://almartin82.github.io/caschooldata/articles/california-assessment_files/figure-html/finding-1-plot-1.png)

---

### 17. High schoolers outperform elementary in ELA

Grade 11 students have the highest ELA proficiency (55.7%), significantly above Grade 3 (42.8%). Unlike most states, California's ELA proficiency rises with grade level.

```r
# ELA proficiency by grade
ela_by_grade <- assess_2024 %>%
  filter(is_state, subject == "ELA",
         metric_type == "pct_met_and_above",
         grade %in% sprintf("%02d", c(3:8, 11))) %>%
  select(grade, metric_value) %>%
  arrange(grade)

ela_by_grade
```

![ELA by Grade](https://almartin82.github.io/caschooldata/articles/california-assessment_files/figure-html/finding-2-plot-1.png)

---

### 18. Math proficiency drops dramatically by middle school

Math proficiency peaks in Grade 3 at 45.6% and falls to under 32% by Grade 8. By Grade 11, only 27.9% meet standards.

```r
# Math proficiency by grade
math_by_grade <- assess_2024 %>%
  filter(is_state, subject == "Math",
         metric_type == "pct_met_and_above",
         grade %in% sprintf("%02d", c(3:8, 11))) %>%
  select(grade, metric_value) %>%
  arrange(grade)

math_by_grade
```

![Math by Grade](https://almartin82.github.io/caschooldata/articles/california-assessment_files/figure-html/finding-3-plot-1.png)

---

### 19. 2021 was the peak, not a pandemic trough

Surprisingly, Grade 11 ELA proficiency peaked in 2021 at 59.2% — the first post-COVID test year — then fell to 54.8% in 2022 and has slowly recovered to 55.7% by 2024. This likely reflects selective participation in 2021.

```r
# Fetch multiple years
assess_multi <- fetch_assess_multi(c(2021, 2022, 2023, 2024),
                                    tidy = TRUE, use_cache = TRUE)

# State-level trend
state_trend <- assess_multi %>%
  filter(is_state, grade == "11", metric_type == "pct_met_and_above") %>%
  select(end_year, subject, metric_value) %>%
  arrange(subject, end_year)

state_trend %>%
  pivot_wider(names_from = subject, values_from = metric_value)
```

![COVID Recovery](https://almartin82.github.io/caschooldata/articles/california-assessment_files/figure-html/finding-5-plot-1.png)

---

### 20. ELA-Math gap ranges from -2.8 to +27.8 points across grades

The gap between ELA and Math proficiency is NOT consistent. In Grade 3, Math actually outperforms ELA by 2.8 points. By Grade 11, the gap balloons to 27.8 points in ELA's favor. This widening gap reflects the cumulative struggle with math as concepts become more abstract.

```r
# ELA-Math gap by grade
ela_math_gap <- assess_2024 %>%
  filter(is_state, metric_type == "pct_met_and_above",
         grade %in% sprintf("%02d", c(3:8, 11))) %>%
  select(grade, subject, metric_value) %>%
  pivot_wider(names_from = subject, values_from = metric_value) %>%
  mutate(gap = ELA - Math)

ela_math_gap
```

![ELA-Math Gap](https://almartin82.github.io/caschooldata/articles/california-assessment_files/figure-html/finding-14-plot-1.png)

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
enr_2025 <- fetch_enr(2025, use_cache = TRUE)

# Fetch recent years (2018-2025)
enr_recent <- fetch_enr_multi(2018:2025, use_cache = TRUE)

# State totals (filter charter_status to avoid tripling in 2024+)
enr_2025 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL",
         charter_status %in% c("All", NA))

# District breakdown
enr_2025 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         charter_status %in% c("All", NA)) %>%
  arrange(desc(n_students))

# Demographics by district
enr_2025 %>%
  filter(is_district, grade_level == "TOTAL",
         charter_status %in% c("All", NA),
         grepl("^RE_", reporting_category)) %>%
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

# State totals (filter charter_status to avoid tripling)
state_total = enr_2025[
    (enr_2025['is_state'] == True) &
    (enr_2025['grade_level'] == 'TOTAL') &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['charter_status'].isin(['All']))
]

# District breakdown
district_totals = enr_2025[
    (enr_2025['is_district'] == True) &
    (enr_2025['grade_level'] == 'TOTAL') &
    (enr_2025['subgroup'] == 'total_enrollment') &
    (enr_2025['charter_status'].isin(['All']))
].sort_values('n_students', ascending=False)
```

## Data availability

### Enrollment Data

| Years | Source | Aggregation Levels | Demographics | Notes |
|-------|--------|-------------------|--------------|-------|
| **2024-2025** | Census Day files | State, County, District, School | Race, Gender, Student Groups (EL, FRPM, SWD, etc.) | Full detail, TK included |
| **2008-2023** | Historical files | School (aggregates computed) | Race, Gender | Entity names included |
| **1994-2007** | Historical files | School (aggregates computed) | Race, Gender | No entity names (CDS codes only) |
| **1982-1993** | Historical files | School (aggregates computed) | Race, Gender | Letter-based race codes (mapped) |

### Assessment Data (CAASPP)

| Years | Source | Subjects | Grades | Notes |
|-------|--------|----------|--------|-------|
| **2021-2025** | CAASPP Research Files | ELA, Math | 3-8, 11 | Pre-2021 data has column mapping issue; no 2020 due to COVID-19 |

### What's available by year range

- **Subgroups**: Race/ethnicity and gender available for all years. Student groups (English Learners, FRPM, Special Ed) only available 2024+.
- **Grade levels**: K-12 available for all years. Transitional Kindergarten (TK) only available 2024+.
- **Aggregation**: Modern files (2024+) include pre-computed state/county/district totals. Historical files only have school-level data; this package computes aggregates automatically.
- **Entity names**: School/district names available 2008+ and 1982-1993. Not available for 1994-2007 (use CDS code lookups).
- **Charter status**: Modern files (2024+) report "All", "N" (non-charter), and "Y" (charter) separately. Always filter to `charter_status %in% c("All", NA)` for deduplicated totals.

## Data Notes

### Enrollment Data

- **Source**: California Department of Education [DataQuest](https://dq.cde.ca.gov/dataquest/) and [Data Files](https://www.cde.ca.gov/ds/)
- **Census Day**: All enrollment counts are from Census Day (first Wednesday in October)
- **Suppression**: Counts of 10 or fewer students are suppressed for privacy
- **Charter Status**: Modern files (2024+) report charter and non-charter separately; always filter to `charter_status %in% c("All", NA)` to avoid tripling

### Assessment Data (CAASPP)

- **Source**: [CAASPP Research Files Portal](https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB)
- **Years Available**: 2021-2025 (pre-2021 has a known column mapping issue; no 2020 due to COVID-19)
- **Grades Tested**: 3-8 and 11 for ELA and Mathematics
- **Suppression**: Groups with fewer than 11 students are not reported
- **Performance Levels**: Standard Exceeded, Standard Met, Standard Nearly Met, Standard Not Met

## Part of the State Schooldata Project

This package is part of the [njschooldata](https://github.com/almartin82/njschooldata) family, providing a simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
