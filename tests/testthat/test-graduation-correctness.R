# ==============================================================================
# Transformation Correctness Tests — Graduation
# ==============================================================================
#
# Tests verifying that graduation rate data transformations preserve fidelity
# to the original CDE School Dashboard Excel files. Every pinned value was
# obtained by running actual fetch calls against CDE data.
#
# Covers:
#   1. Subgroup renaming (standard names)
#   2. Graduation rate scaling (0-100 in source → 0-1 in output)
#   3. Entity type logic (State/District/School, mutually exclusive flags)
#   4. Data quality (no Inf/NaN, valid ranges)
#   5. Pinned values for 2025 and 2024
#   6. Cross-year consistency
#
# ==============================================================================

# --- helpers -----------------------------------------------------------------

skip_if_offline <- function() {
  skip_on_cran()
  if (!curl::has_internet()) skip("No internet connection")
}

# ==============================================================================
# 1. Subgroup Renaming
# ==============================================================================

test_that("graduation subgroup names are standardized", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(grad$subgroup)

  # Key standard names
  expected <- c("all", "hispanic", "white", "black", "asian",
                "native_american", "multiracial", "english_learner",
                "low_income", "special_ed")
  for (s in expected) {
    expect_true(s %in% subgroups,
                info = paste("Missing graduation subgroup:", s))
  }
})

test_that("raw CDE subgroup codes are not in output", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(grad$subgroup)

  # Raw CDE codes should not appear
  raw_codes <- c("ALL", "AA", "AI", "AS", "FI", "HI", "PI", "WH",
                 "MR", "EL", "SED", "SWD", "FOS", "HOM")
  for (code in raw_codes) {
    expect_false(code %in% subgroups,
                 info = paste("Raw CDE code found:", code))
  }
})

test_that("filipino is a separate graduation subgroup", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  expect_true("filipino" %in% unique(grad$subgroup))
})

# ==============================================================================
# 2. Graduation Rate Scaling
# ==============================================================================

test_that("graduation rates are in 0-1 range (not 0-100)", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(grad$grad_rate >= 0 & grad$grad_rate <= 1, na.rm = TRUE))
})

test_that("state all-students rate is in reasonable range (0.80-0.95)", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  state_rate <- grad |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(grad_rate)

  expect_gte(state_rate, 0.80)
  expect_lte(state_rate, 0.95)
})

# ==============================================================================
# 3. Entity Type Logic
# ==============================================================================

test_that("entity flags are mutually exclusive in graduation data", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  flag_sum <- grad$is_state + grad$is_district + grad$is_school
  expect_true(all(flag_sum == 1))
})

test_that("type column matches entity flags", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(grad$type[grad$is_state] == "State"))
  expect_true(all(grad$type[grad$is_district] == "District"))
  expect_true(all(grad$type[grad$is_school] == "School"))
})

test_that("state has all expected subgroups", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  state_subgroups <- grad |>
    dplyr::filter(is_state) |>
    dplyr::pull(subgroup) |>
    unique()

  expect_gte(length(state_subgroups), 10)
})

# ==============================================================================
# 4. Data Quality
# ==============================================================================

test_that("no Inf in graduation data", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  for (col in names(grad)[sapply(grad, is.numeric)]) {
    expect_false(any(is.infinite(grad[[col]]), na.rm = TRUE),
                 info = paste("Inf in", col))
  }
})

test_that("no NaN in graduation data", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  for (col in names(grad)[sapply(grad, is.numeric)]) {
    expect_false(any(is.nan(grad[[col]]), na.rm = TRUE),
                 info = paste("NaN in", col))
  }
})

test_that("cohort counts are non-negative", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(grad$cohort_count >= 0, na.rm = TRUE))
})

test_that("graduate counts are non-negative", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(grad$graduate_count >= 0, na.rm = TRUE))
})

test_that("graduate count <= cohort count", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(grad$graduate_count <= grad$cohort_count, na.rm = TRUE))
})

# ==============================================================================
# 5. Pinned Values
# ==============================================================================

test_that("2025 state graduation rate = 0.878", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  state_rate <- grad |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(grad_rate)

  expect_equal(state_rate, 0.878, tolerance = 0.001)
})

test_that("2025 state cohort count = 507,889", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  state_cohort <- grad |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(cohort_count)

  expect_equal(state_cohort, 507889)
})

test_that("2025 state graduate count = 445,720", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  state_grads <- grad |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(graduate_count)

  expect_equal(state_grads, 445720)
})

test_that("2025 LAUSD graduation rate present and reasonable", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  lausd <- grad |>
    dplyr::filter(is_district, grepl("1964733", district_id),
                  subgroup == "all")

  expect_gt(nrow(lausd), 0)
  expect_equal(lausd$grad_rate[1], 0.865, tolerance = 0.001)
})

test_that("2024 state graduation rate = 0.867", {
  skip_if_offline()

  grad <- fetch_graduation(2024, tidy = TRUE, use_cache = TRUE)
  state_rate <- grad |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(grad_rate)

  expect_equal(state_rate, 0.867, tolerance = 0.001)
})

test_that("2024 state cohort count = 517,434", {
  skip_if_offline()

  grad <- fetch_graduation(2024, tidy = TRUE, use_cache = TRUE)
  state_cohort <- grad |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(cohort_count)

  expect_equal(state_cohort, 517434)
})

# ==============================================================================
# 6. Entity Coverage
# ==============================================================================

test_that("2025 has >400 districts with graduation data", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  n_districts <- grad |>
    dplyr::filter(is_district, subgroup == "all") |>
    nrow()

  expect_gt(n_districts, 400)
})

test_that("2025 has >1000 schools with graduation data", {
  skip_if_offline()

  grad <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  n_schools <- grad |>
    dplyr::filter(is_school, subgroup == "all") |>
    nrow()

  expect_gt(n_schools, 1000)
})

# ==============================================================================
# 7. Cross-Year Consistency
# ==============================================================================

test_that("state graduation rate YoY change < 10 percentage points", {
  skip_if_offline()

  grad_2024 <- fetch_graduation(2024, tidy = TRUE, use_cache = TRUE)
  grad_2025 <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)

  rate_2024 <- grad_2024 |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(grad_rate)
  rate_2025 <- grad_2025 |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(grad_rate)

  pp_change <- abs(rate_2025 - rate_2024) * 100  # percentage points
  expect_lt(pp_change, 10)
})

test_that("tidy and wide outputs match for graduation state rate", {
  skip_if_offline()

  tidy <- fetch_graduation(2025, tidy = TRUE, use_cache = TRUE)
  wide <- fetch_graduation(2025, tidy = FALSE, use_cache = TRUE)

  tidy_rate <- tidy |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(grad_rate)
  wide_rate <- wide |>
    dplyr::filter(is_state, subgroup == "all") |>
    dplyr::pull(grad_rate)

  expect_equal(tidy_rate, wide_rate)
})

# ==============================================================================
# 8. Available Years
# ==============================================================================

test_that("get_available_grad_years returns expected years", {
  years <- get_available_grad_years()
  expect_true(is.numeric(years) || is.integer(years))
  expect_true(2025 %in% years)
  expect_true(2024 %in% years)
  expect_true(2017 %in% years)
})
