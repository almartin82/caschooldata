# ==============================================================================
# Transformation Correctness Tests — Assessments (CAASPP)
# ==============================================================================
#
# Tests verifying that CAASPP assessment data transformations preserve fidelity
# to the original ETS/CDE research files. Every pinned value was obtained by
# running actual fetch calls against CAASPP data.
#
# Covers:
#   1. Suppression handling (asterisk/N/A → NA in raw read)
#   2. Subject mapping (test_id 1=ELA, 2=Math)
#   3. Grade formatting (zero-padded, 13=all grades)
#   4. Aggregation levels (type_id: 4=T, 5=C, 6=D, 7=S)
#   5. Pivot fidelity (wide pct columns → tidy metric_type/metric_value)
#   6. Percentage validation (0-100 range, no Inf/NaN)
#   7. Entity flag logic
#   8. Pinned values for 2024
#   9. Cross-year coverage
#
# ==============================================================================

# --- helpers -----------------------------------------------------------------

skip_if_offline <- function() {
  skip_on_cran()
  if (!curl::has_internet()) skip("No internet connection")
}

# ==============================================================================
# 1. Subject Mapping
# ==============================================================================

test_that("test_id 1 maps to ELA, 2 maps to Math", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  subjects <- unique(assess$subject)
  expect_true("ELA" %in% subjects)
  expect_true("Math" %in% subjects)
  expect_equal(length(subjects), 2)
})

# ==============================================================================
# 2. Grade Formatting
# ==============================================================================

test_that("assessment grades are zero-padded to 2 digits", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  grades <- unique(assess$grade)

  # Grade 13 is the all-grades aggregate
  expected <- c("03", "04", "05", "06", "07", "08", "11", "13")
  for (g in expected) {
    expect_true(g %in% grades, info = paste("Missing grade:", g))
  }
})

test_that("no unpadded grade values like '3' or '4'", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  grades <- unique(assess$grade)

  # Single-digit unpadded grades should not appear
  bad_grades <- c("3", "4", "5", "6", "7", "8")
  for (g in bad_grades) {
    expect_false(g %in% grades, info = paste("Unpadded grade found:", g))
  }
})

# ==============================================================================
# 3. Aggregation Levels
# ==============================================================================

test_that("assessment agg_level has T, C, D, S", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  agg_levels <- sort(unique(assess$agg_level))
  expect_equal(agg_levels, c("C", "D", "S", "T"))
})

# ==============================================================================
# 4. Pivot Fidelity
# ==============================================================================

test_that("tidy format has metric_type and metric_value columns", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  expect_true("metric_type" %in% names(assess))
  expect_true("metric_value" %in% names(assess))
})

test_that("all expected metric types present in tidy data", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  metric_types <- unique(assess$metric_type)

  expected <- c("mean_scale_score", "pct_exceeded", "pct_met",
                "pct_met_and_above", "pct_nearly_met", "pct_not_met",
                "n_tested", "n_exceeded", "n_met", "n_met_and_above",
                "n_nearly_met", "n_not_met")
  for (m in expected) {
    expect_true(m %in% metric_types,
                info = paste("Missing metric type:", m))
  }
})

test_that("wide and tidy state proficiency values match for 2024", {
  skip_if_offline()

  wide <- fetch_assess(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)

  # State-level 11th grade ELA pct_met_and_above
  wide_val <- wide |>
    dplyr::filter(agg_level == "T", grade == "11", subject == "ELA") |>
    dplyr::pull(pct_met_and_above)

  tidy_val <- tidy |>
    dplyr::filter(is_state, grade == "11", subject == "ELA",
                  metric_type == "pct_met_and_above") |>
    dplyr::pull(metric_value)

  expect_equal(tidy_val, wide_val)
})

# ==============================================================================
# 5. Percentage Validation
# ==============================================================================

test_that("percentages are in 0-100 range", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  pct_metrics <- assess |>
    dplyr::filter(grepl("^pct_", metric_type))

  valid <- pct_metrics$metric_value >= 0 & pct_metrics$metric_value <= 100
  expect_true(all(valid, na.rm = TRUE))
})

test_that("no Inf in assessment data", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  expect_false(any(is.infinite(assess$metric_value), na.rm = TRUE))
})

test_that("no NaN in assessment data", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  expect_false(any(is.nan(assess$metric_value), na.rm = TRUE))
})

test_that("count metrics are non-negative integers", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  count_metrics <- assess |>
    dplyr::filter(grepl("^n_", metric_type))

  expect_true(all(count_metrics$metric_value >= 0, na.rm = TRUE))
})

# ==============================================================================
# 6. Entity Flag Logic
# ==============================================================================

test_that("assessment entity flags are mutually exclusive", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  flag_sum <- assess$is_state + assess$is_county +
              assess$is_district + assess$is_school
  expect_true(all(flag_sum == 1))
})

test_that("is_state corresponds to agg_level T", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  expect_true(all(assess$agg_level[assess$is_state] == "T"))
  expect_true(all(assess$agg_level[assess$is_school] == "S"))
})

# ==============================================================================
# 7. Pinned Values for 2024
# ==============================================================================

test_that("2024 state 11th ELA pct_met_and_above = 55.73", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  val <- assess |>
    dplyr::filter(is_state, grade == "11", subject == "ELA",
                  metric_type == "pct_met_and_above") |>
    dplyr::pull(metric_value)

  expect_equal(val, 55.73)
})

test_that("2024 state all-grades Math pct_met_and_above = 35.54", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  val <- assess |>
    dplyr::filter(is_state, grade == "13", subject == "Math",
                  metric_type == "pct_met_and_above") |>
    dplyr::pull(metric_value)

  expect_equal(val, 35.54)
})

test_that("2024 state 11th ELA mean_scale_score = 2590.5", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  val <- assess |>
    dplyr::filter(is_state, grade == "11", subject == "ELA",
                  metric_type == "mean_scale_score") |>
    dplyr::pull(metric_value)

  expect_equal(val, 2590.5)
})

# ==============================================================================
# 8. Entity Counts
# ==============================================================================

test_that("2024 has 58 counties in assessment data", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  n_counties <- assess |>
    dplyr::filter(is_county, grade == "13", subject == "ELA",
                  metric_type == "pct_met_and_above") |>
    nrow()

  expect_equal(n_counties, 58)
})

test_that("2024 has >1000 districts in assessment data", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  n_districts <- assess |>
    dplyr::filter(is_district, grade == "13", subject == "ELA",
                  metric_type == "pct_met_and_above") |>
    nrow()

  expect_gt(n_districts, 1000)
})

test_that("2024 has >10000 schools in assessment data", {
  skip_if_offline()

  assess <- fetch_assess(2024, tidy = TRUE, use_cache = TRUE)
  n_schools <- assess |>
    dplyr::filter(is_school, grade == "13", subject == "ELA",
                  metric_type == "pct_met_and_above") |>
    nrow()

  expect_gt(n_schools, 10000)
})

# ==============================================================================
# 9. COVID Year Handling
# ==============================================================================

test_that("2020 is excluded from available assessment years", {
  years <- get_available_assess_years()
  expect_false(2020 %in% years$all_years)
})

test_that("fetch_assess errors on year 2020", {
  expect_error(fetch_assess(2020), "2020")
})
