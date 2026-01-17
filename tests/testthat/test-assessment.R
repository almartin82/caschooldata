# ==============================================================================
# Assessment Data Tests
# ==============================================================================

test_that("get_available_assess_years returns correct structure", {
  years <- get_available_assess_years()

  expect_true(is.list(years))
  expect_true("min_year" %in% names(years))
  expect_true("max_year" %in% names(years))
  expect_true("all_years" %in% names(years))

  expect_equal(years$min_year, 2015)
  expect_equal(years$max_year, 2024)
  expect_true(all(2015:2024 %in% years$all_years))
})


test_that("get_raw_assess returns correct structure for valid year", {
  result <- get_raw_assess(2023)

  expect_true(is.list(result))
  expect_true("year" %in% names(result))
  expect_true("test_year" %in% names(result))
  expect_true("portal_url" %in% names(result))
  expect_true("status" %in% names(result))

  expect_equal(result$year, 2023)
  expect_equal(result$test_year, 2023)
  expect_true(grepl("caaspp-elpac.ets.org", result$portal_url))
})


test_that("get_raw_assess validates year input", {
  expect_error(
    get_raw_assess(2014),
    "end_year must be between 2015 and 2024"
  )

  expect_error(
    get_raw_assess(2025),
    "end_year must be between 2015 and 2024"
  )
})


test_that("get_raw_assess accepts valid subject parameter", {
  result_both <- get_raw_assess(2023, subject = "Both")
  expect_equal(result_both$subject, "Both")

  result_ela <- get_raw_assess(2023, subject = "ELA")
  expect_equal(result_ela$subject, "ELA")

  result_math <- get_raw_assess(2023, subject = "Math")
  expect_equal(result_math$subject, "Math")

  # Test that invalid subject raises error
  expect_error(
    get_raw_assess(2023, subject = "Invalid"),
    "'arg' should be one of"
  )
})


test_that("import_local_assess validates file paths", {
  expect_error(
    import_local_assess(
      test_data_path = "nonexistent.txt",
      entities_path = "nonexistent.txt",
      end_year = 2023
    ),
    "not found"
  )
})


test_that("process_assess handles NULL data gracefully", {
  expect_error(
    process_assess(NULL, 2023),
    "Raw assessment data is NULL"
  )
})


test_that("process_assess returns correct structure when given data", {
  # Create mock data matching CAASPP structure
  mock_data <- tibble::tibble(
    `County Code` = c("00", "01", "01"),
    `District Code` = c("00000", "00001", "00001"),
    `School Code` = c("0000000", "0000001", "0000002"),
    Grade = c("11", "11", "11"),
    Subject = c("ELA", "ELA", "ELA"),
    `Mean Scale Score` = c("2500", "2600", "2700"),
    `Percentage Standard Met and Above` = c("50.5", "60.2", "70.8"),
    `Number Tested` = c("1000", "500", "300")
  )

  result <- process_assess(mock_data, 2023)

  expect_true("end_year" %in% names(result))
  expect_true("cds_code" %in% names(result))
  expect_true("agg_level" %in% names(result))
  expect_true("subject" %in% names(result))
  expect_true("grade" %in% names(result))

  expect_equal(result$end_year[1], 2023)
  expect_equal(result$subject[1], "ELA")
  expect_equal(result$grade[1], "11")
})


test_that("tidy_assess converts wide to long format", {
  # Create mock processed data
  mock_data <- tibble::tibble(
    end_year = 2023,
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    mean_scale_score = 2500,
    pct_met_and_above = 50.5,
    n_tested = 1000
  )

  result <- tidy_assess(mock_data)

  expect_true("metric_type" %in% names(result))
  expect_true("metric_value" %in% names(result))

  # Should have more rows in tidy format (one per metric)
  expect_true(nrow(result) > nrow(mock_data))

  # Check that metric types were created
  metric_types <- unique(result$metric_type)
  expect_true("mean_scale_score" %in% metric_types)
  expect_true("pct_met_and_above" %in% metric_types)
  expect_true("n_tested" %in% metric_types)
})


test_that("id_assess_aggs adds aggregation identifiers", {
  # Create mock tidy data
  mock_data <- tibble::tibble(
    end_year = 2023,
    cds_code = "00000000000000",
    agg_level = c("S", "D", "C", "T"),
    grade = "11",
    subject = "ELA",
    metric_type = "pct_met_and_above",
    metric_value = c(60.0, 55.0, 52.0, 50.0)
  )

  result <- id_assess_aggs(mock_data)

  expect_true("is_state" %in% names(result))
  expect_true("is_county" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_school" %in% names(result))

  # Check logical values
  expect_true(result$is_state[4])
  expect_false(result$is_state[1])
  expect_true(result$is_school[1])
  expect_false(result$is_school[4])
})


test_that("summarize_proficiency filters to single metric", {
  # Create mock tidy data with multiple metrics
  mock_data <- tibble::tibble(
    end_year = 2023,
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    metric_type = c("pct_met_and_above", "pct_exceeded", "mean_scale_score"),
    metric_value = c(50.0, 20.0, 2500.0)
  )

  result <- summarize_proficiency(mock_data, "pct_met_and_above")

  # Should only have one row (one metric)
  expect_equal(nrow(result), 1)

  # Should not have metric_type column (it was removed)
  expect_false("metric_type" %in% names(result))

  # Should have the correct value
  expect_equal(result$metric_value, 50.0)
})


test_that("calc_assess_trend calculates year-over-year changes", {
  # Create mock data with 2 years
  mock_data <- tibble::tibble(
    end_year = c(2022, 2023),
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    metric_type = "pct_met_and_above",
    metric_value = c(50.0, 52.0)
  )

  result <- calc_assess_trend(mock_data, "pct_met_and_above")

  expect_true("change" %in% names(result))
  expect_true("pct_change" %in% names(result))

  # First year should have NA for change (no previous year)
  expect_true(is.na(result$change[1]))
  expect_true(is.na(result$pct_change[1]))

  # Second year should have change calculated
  expect_equal(result$change[2], 2.0, tolerance = 0.01)
  expect_equal(result$pct_change[2], 4.0, tolerance = 0.01)  # (52-50)/50 * 100
})


# Note: fetch_assess() requires local files or manual download
# These tests verify the function structure but don't test actual downloads
test_that("fetch_assess validates year parameter", {
  # Skip this test if we don't want to attempt downloads
  skip("Manual download required - function structure tested separately")

  expect_error(
    fetch_assess(2014),
    "end_year must be between 2015 and 2024"
  )
})


test_that("fetch_assess_multi returns combined data", {
  # This test would require local data files
  skip("Requires local CAASPP data files")

  # Example test structure:
  # result <- fetch_assess_multi(c(2022, 2023), local_data = local_files)
  # expect_true("end_year" %in% names(result))
  # expect_equal(sort(unique(result$end_year)), c(2022, 2023))
})


test_that("assessment data print methods work", {
  # Test ca_assess_data print
  mock_processed <- tibble::tibble(
    end_year = 2023,
    cds_code = "00000000000000",
    county_code = "00",
    district_code = "00000",
    school_code = "0000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    mean_scale_score = 2500,
    pct_met_and_above = 50.0,
    n_tested = 1000
  )
  class(mock_processed) <- c("ca_assess_data", class(mock_processed))

  expect_output(print(mock_processed), "California CAASPP Assessment Data")

  # Test ca_assess_tidy print
  mock_tidy <- tibble::tibble(
    end_year = 2023,
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    metric_type = "pct_met_and_above",
    metric_value = 50.0
  )
  class(mock_tidy) <- c("ca_assess_tidy", class(mock_tidy))

  expect_output(print(mock_tidy), "Tidy Format")
})
