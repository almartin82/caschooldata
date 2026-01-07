# ==============================================================================
# Tests for Enrollment Functions
# ==============================================================================

test_that("parse_cds_code parses correctly", {
  # Test single CDS code
  result <- parse_cds_code("01611920130229")
  expect_equal(result$county_code, "01")
  expect_equal(result$district_code, "61192")
  expect_equal(result$school_code, "0130229")
  expect_equal(result$cds_code, "01611920130229")

  # Test with leading zeros
  result <- parse_cds_code("01100170000000")
  expect_equal(result$county_code, "01")
  expect_equal(result$district_code, "10017")
  expect_equal(result$school_code, "0000000")

  # Test multiple codes
  codes <- c("01611920130229", "19647330000000")
  result <- parse_cds_code(codes)
  expect_equal(nrow(result), 2)
  expect_equal(result$county_code[1], "01")
  expect_equal(result$county_code[2], "19")
})


test_that("build_enr_url constructs correct URLs", {
  # Test 2024 URL (has -v2 suffix)
  url_2024 <- build_enr_url(2024)
  expect_true(grepl("cdenroll2324-v2.txt", url_2024))
  expect_true(grepl("demo-downloads/census", url_2024))

  # Test 2025 URL
  url_2025 <- build_enr_url(2025)
  expect_true(grepl("cdenroll2425.txt", url_2025))
})


test_that("map_reporting_category maps codes correctly", {
  # Test race/ethnicity codes
  expect_equal(map_reporting_category("RE_H"), "hispanic")
  expect_equal(map_reporting_category("RE_W"), "white")
  expect_equal(map_reporting_category("RE_B"), "black")

  # Test gender codes
  expect_equal(map_reporting_category("GN_F"), "female")
  expect_equal(map_reporting_category("GN_M"), "male")

  # Test student group codes
  expect_equal(map_reporting_category("SG_EL"), "english_learner")
  expect_equal(map_reporting_category("SG_SD"), "socioeconomically_disadvantaged")

  # Test total
  expect_equal(map_reporting_category("TA"), "total")

  # Test unknown code returns original
  expect_equal(map_reporting_category("UNKNOWN"), "UNKNOWN")
})


test_that("safe_numeric handles suppression markers", {
  # Test normal numbers
  expect_equal(safe_numeric("123"), 123)
  expect_equal(safe_numeric("1,234"), 1234)

  # Test suppressed values
  expect_true(is.na(safe_numeric("*")))

  # Test mixed
  result <- safe_numeric(c("100", "*", "200"))
  expect_equal(result[1], 100)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 200)
})


test_that("fetch_enr validates year range", {
  # Test year too low (1981 is before the 1982 minimum)
  expect_error(fetch_enr(1981), "end_year must be between")

  # Test year too high (2030 is beyond available data)
  expect_error(fetch_enr(2030), "end_year must be between")
})


test_that("get_available_years returns correct range", {
  years <- get_available_years()

  # Should return an integer vector

  expect_type(years, "integer")

  # Should include the documented range 1982-2025
  expect_equal(min(years), 1982)
  expect_equal(max(years), 2025)

  # Should include both historical and modern years
  expect_true(2020 %in% years)  # Historical year
  expect_true(2025 %in% years)  # Most recent available year
})


test_that("cache functions work correctly", {
  # Test cache path construction
  path <- build_cache_path(2024, "tidy")
  expect_true(grepl("enr_2024_tidy.rds", path))
  expect_true(grepl("caschooldata", path))
})


test_that("tidy format has PRD-compliant columns", {
  skip_if_offline()

  data <- fetch_enr(2023, tidy = TRUE, use_cache = FALSE)

  # Check for all PRD-required columns (must be present)
  prd_cols <- c(
    "end_year", "district_id", "campus_id", "district_name", "campus_name",
    "type", "grade_level", "subgroup", "n_students", "pct"
  )

  for (col in prd_cols) {
    expect_true(col %in% names(data), info = paste("Missing column:", col))
  }

  # PRD columns should come first in the column order
  first_10_cols <- names(data)[1:10]
  expect_equal(first_10_cols, prd_cols,
               info = "First 10 columns should be PRD-specified columns")
})


test_that("type column has human-readable values", {
  skip_if_offline()

  data <- fetch_enr(2023, tidy = TRUE, use_cache = FALSE)

  # Check that type has the correct values
  expect_true("State" %in% data$type)
  expect_true("District" %in% data$type)
  expect_true("Campus" %in% data$type)
  expect_true("County" %in% data$type)

  # Check that type values are all valid
  valid_types <- c("State", "County", "District", "Campus")
  expect_true(all(data$type %in% valid_types),
              info = "All type values should be valid")

  # Check that type is consistent with is_* helper columns
  expect_true(all(data$type[data$is_state] == "State"))
  expect_true(all(data$type[data$is_district] == "District"))
  expect_true(all(data$type[data$is_school] == "Campus"))
  expect_true(all(data$type[data$is_county] == "County"))
})


test_that("pct column calculates percentages correctly", {
  skip_if_offline()

  data <- fetch_enr(2023, tidy = TRUE, use_cache = FALSE)

  # Test that total subgroup has pct = 1.0
  total_rows <- data |>
    dplyr::filter(subgroup == "total", !is.na(pct))

  expect_true(all(total_rows$pct == 1.0),
              info = "Total subgroup should have pct = 1.0")

  # Test that pct is between 0 and 1
  expect_true(all(data$pct >= 0 & data$pct <= 1, na.rm = TRUE),
              info = "pct should be between 0 and 1")

  # Test that pct sums correctly for subgroups within a group
  # Pick a specific entity and grade_level
  test_entity <- data |>
    dplyr::filter(type == "State", grade_level == "TOTAL") |>
    dplyr::select(subgroup, n_students, pct) |>
    dplyr::arrange(desc(n_students)) |>
    head(5)

  # The total should have pct = 1
  expect_equal(test_entity$pct[test_entity$subgroup == "total"], 1,
               tolerance = 0.001)

  # Hispanic should have a reasonable percentage (around 0.5-0.6 based on CA demographics)
  hispanic_pct <- test_entity$pct[test_entity$subgroup == "hispanic"]
  expect_true(hispanic_pct > 0.4 & hispanic_pct < 0.7,
              info = "Hispanic percentage should be reasonable for CA")
})


test_that("district_id and campus_id are correctly renamed", {
  skip_if_offline()

  data <- fetch_enr(2023, tidy = TRUE, use_cache = FALSE)

  # Old column names should NOT exist
  expect_false("district_code" %in% names(data))
  expect_false("school_code" %in% names(data))

  # New column names should exist
  expect_true("district_id" %in% names(data))
  expect_true("campus_id" %in% names(data))

  # campus_id should be NA for district rows
  district_rows <- data |>
    dplyr::filter(type == "District")

  expect_true(all(is.na(district_rows$campus_id) | district_rows$campus_id == "0000000"),
              info = "District rows should have campus_id = NA or '0000000'")
})


test_that("campus_name is correctly renamed from school_name", {
  skip_if_offline()

  data <- fetch_enr(2023, tidy = TRUE, use_cache = FALSE)

  # Old column name should NOT exist
  expect_false("school_name" %in% names(data))

  # New column name should exist
  expect_true("campus_name" %in% names(data))
})


skip_if_offline <- function() {
  # Skip test if offline
  tryCatch({
    response <- httr::HEAD("https://www.google.com", timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}
