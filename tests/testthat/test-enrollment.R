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
