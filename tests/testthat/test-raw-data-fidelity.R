# ==============================================================================
# Raw Data Fidelity Tests
# ==============================================================================
#
# These tests verify that fetch_enr(..., tidy=TRUE) maintains fidelity to
# the raw, unprocessed source data from CDE.
#
# Tests verify specific values and data quality characteristics.
#
# ==============================================================================

test_that("State total enrollment is non-zero and reasonable", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # State total enrollment should be > 5 million (CA has ~6 million students)
  state_total <- data |>
    dplyr::filter(type == "State", grade_level == "TOTAL", subgroup == "total") |>
    dplyr::pull(n_students) |>
    unique()

  expect_gt(state_total, 5000000,
            info = "State total enrollment should be > 5 million")
  expect_lt(state_total, 10000000,
            info = "State total enrollment should be < 10 million")
})


test_that("ID codes do not contain 'NA' string corruption", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # district_id should not contain the literal string "NA"
  has_na_in_district_id <- any(grepl("NA", data$district_id))
  expect_false(has_na_in_district_id,
               info = "district_id should not contain 'NA' string")

  # campus_id should not contain the literal string "NA"
  has_na_in_campus_id <- any(grepl("NA", data$campus_id))
  expect_false(has_na_in_campus_id,
               info = "campus_id should not contain 'NA' string")

  # State-level should have placeholder codes
  state_ids <- data |>
    dplyr::filter(type == "State") |>
    dplyr::slice(1)

  expect_equal(state_ids$district_id, "00000",
               info = "State district_id should be '00000'")
  expect_equal(state_ids$campus_id, "0000000",
               info = "State campus_id should be '0000000'")

  # County-level should have placeholder codes
  county_ids <- data |>
    dplyr::filter(type == "County") |>
    dplyr::slice(1)

  expect_equal(county_ids$district_id, "00000",
               info = "County district_id should be '00000'")
  expect_equal(county_ids$campus_id, "0000000",
               info = "County campus_id should be '0000000'")
})


test_that("pct column has no NA or NaN values", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # pct should have no NA values
  na_count <- sum(is.na(data$pct))
  expect_equal(na_count, 0,
               info = "pct column should have 0 NA values")

  # pct should have no NaN values
  nan_count <- sum(is.nan(data$pct))
  expect_equal(nan_count, 0,
               info = "pct column should have 0 NaN values")

  # pct should be between 0 and 1 for all non-NA values
  expect_true(all(data$pct >= 0 & data$pct <= 1, na.rm = TRUE),
              info = "pct should be between 0 and 1")
})


test_that("Zero enrollment subgroups have pct = 0", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # Rows with n_students = 0 should have pct = 0 (not NA)
  zero_enrollment <- data |>
    dplyr::filter(n_students == 0)

  expect_true(all(zero_enrollment$pct == 0, na.rm = TRUE),
              info = "Zero enrollment subgroups should have pct = 0")

  # Check a specific case: TK grade often has 0 enrollment for many subgroups
  tk_zero <- data |>
    dplyr::filter(grade_level == "TK", n_students == 0)

  if (nrow(tk_zero) > 0) {
    expect_true(all(tk_zero$pct == 0),
                info = "TK grade zero enrollment should have pct = 0")
  }
})


test_that("Total subgroup has pct = 1.0", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # The 'total' subgroup should have pct = 1.0 (100% of total)
  total_subgroup <- data |>
    dplyr::filter(subgroup == "total", !is.na(pct))

  expect_true(all(total_subgroup$pct == 1.0),
              info = "Total subgroup should have pct = 1.0")
})


test_that("Percentages sum correctly within entity/grade/subgroup", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # For a specific entity and grade, race subgroups should sum to approximately 100%
  # Test with State level, TOTAL grade
  state_total <- data |>
    dplyr::filter(
      type == "State",
      grade_level == "TOTAL",
      subgroup %in% c("asian", "black", "hispanic", "white",
                      "native_american", "pacific_islander", "filipino",
                      "multiracial", "not_reported")
    )

  race_sum <- sum(state_total$pct, na.rm = TRUE)

  # Should be close to 1.0 (allowing for rounding and suppressed data)
  expect_gt(race_sum, 0.95,
            info = "Race subgroups should sum to approximately 100%")
  expect_lt(race_sum, 1.05,
            info = "Race subgroups should sum to approximately 100%")
})


test_that("District aggregates equal sum of campuses", {
  skip_if_offline()

  # This test is computationally expensive, so we test with a sample
  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # Pick one district to test
  sample_district <- data |>
    dplyr::filter(type == "District") |>
    dplyr::slice(1) |>
    dplyr::pull(district_id)

  # Get district total for TOTAL grade, total subgroup
  district_total <- data |>
    dplyr::filter(
      district_id == sample_district,
      type == "District",
      grade_level == "TOTAL",
      subgroup == "total"
    ) |>
    dplyr::pull(n_students)

  # Sum all campuses in this district
  campus_sum <- data |>
    dplyr::filter(
      district_id == sample_district,
      type == "Campus",
      grade_level == "TOTAL",
      subgroup == "total"
    ) |>
    dplyr::summarize(total = sum(n_students, na.rm = TRUE), .groups = "drop") |>
    dplyr::pull(total)

  # Campus sum should equal district total (within 1% tolerance for edge cases)
  expect_equal(district_total, campus_sum,
               tolerance = district_total * 0.01,
               info = "District total should equal sum of campus totals")
})


test_that("No Inf or -Inf values in numeric columns", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # n_students should not be Inf or -Inf
  expect_false(any(is.infinite(data$n_students)),
               info = "n_students should not contain Inf values")

  # pct should not be Inf or -Inf
  expect_false(any(is.infinite(data$pct)),
               info = "pct should not contain Inf values")
})


test_that("Grade levels are present and correctly coded", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # Should have standard grade levels
  expected_grades <- c("TOTAL", "TK", "K", "01", "02", "03", "04", "05",
                       "06", "07", "08", "09", "10", "11", "12")

  for (grade in expected_grades) {
    expect_true(grade %in% unique(data$grade_level),
                info = paste("Grade level", grade, "should be present"))
  }

  # TK should be present for 2024+
  expect_true("TK" %in% unique(data$grade_level),
              info = "TK grade should be present for 2024+")
})


test_that("Subgroup categories are correctly mapped", {
  skip_if_offline()

  data <- fetch_enr(2024, tidy = TRUE, use_cache = FALSE)

  # Should have core race subgroups
  expected_races <- c("asian", "black", "hispanic", "white")

  for (race in expected_races) {
    expect_true(race %in% unique(data$subgroup),
                info = paste("Subgroup", race, "should be present"))
  }

  # Should have gender subgroups
  expect_true("male" %in% unique(data$subgroup),
              info = "male subgroup should be present")
  expect_true("female" %in% unique(data$subgroup),
              info = "female subgroup should be present")

  # Should have total
  expect_true("total" %in% unique(data$subgroup),
              info = "total subgroup should be present")
})


# Helper function for skipping tests when offline
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}
