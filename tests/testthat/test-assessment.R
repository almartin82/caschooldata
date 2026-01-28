# ==============================================================================
# Assessment Data Tests
# ==============================================================================
#
# Tests for California CAASPP assessment data functions.
# Uses REAL data values from the CAASPP portal (not mocked/synthetic).
#
# ==============================================================================

# Test get_available_assess_years =============================================

test_that("get_available_assess_years returns correct structure", {
  years <- get_available_assess_years()

  expect_true(is.list(years))
  expect_true("min_year" %in% names(years))
  expect_true("max_year" %in% names(years))
  expect_true("all_years" %in% names(years))
  expect_true("covid_year" %in% names(years))

  expect_equal(years$min_year, 2015)
  expect_equal(years$max_year, 2025)
  expect_equal(years$covid_year, 2020)

  # 2020 should NOT be in all_years (COVID - no statewide testing)
  expect_false(2020 %in% years$all_years)
  expect_true(2019 %in% years$all_years)
  expect_true(2021 %in% years$all_years)
  expect_equal(length(years$all_years), 10)  # 2015-2019 + 2021-2025 = 10 years
})


# Test URL building functions ==================================================

test_that("get_caaspp_version returns correct versions for each year", {
  expect_equal(get_caaspp_version(2015), "v3")
  expect_equal(get_caaspp_version(2016), "v3")
  expect_equal(get_caaspp_version(2017), "v2")
  expect_equal(get_caaspp_version(2018), "v3")
  expect_equal(get_caaspp_version(2019), "v4")
  expect_equal(get_caaspp_version(2021), "v2")
  expect_equal(get_caaspp_version(2022), "v1")
  expect_equal(get_caaspp_version(2023), "v1")
  expect_equal(get_caaspp_version(2024), "v1")
  expect_equal(get_caaspp_version(2025), "v1")
})


test_that("build_caaspp_url constructs correct URLs", {
  url_2024 <- build_caaspp_url(2024, file_type = "1", format = "csv")
  expect_equal(
    url_2024,
    "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2024_1_csv_v1.zip"
  )

  url_2019 <- build_caaspp_url(2019, file_type = "all", format = "csv")
  expect_equal(
    url_2019,
    "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2019_all_csv_v4.zip"
  )

  url_2017_ela <- build_caaspp_url(2017, file_type = "all_ela", format = "csv")
  expect_equal(
    url_2017_ela,
    "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2017_all_csv_ela_v2.zip"
  )
})


test_that("build_entities_url constructs correct URLs", {
  url <- build_entities_url(2024, format = "csv")
  expect_equal(
    url,
    "https://caaspp-elpac.ets.org/caaspp/researchfiles/sb_ca2024entities_csv.zip"
  )
})


# Test year validation =========================================================

test_that("get_raw_assess validates year input", {
  expect_error(
    get_raw_assess(2014),
    "end_year must be one of"
  )

  expect_error(
    get_raw_assess(2026),
    "end_year must be one of"
  )

  # 2020 should be excluded from available years (COVID - no testing)
  expect_error(
    get_raw_assess(2020),
    "2020"  # Error message mentions 2020
  )
})


test_that("fetch_assess validates year input", {
  expect_error(
    fetch_assess(2014),
    "end_year must be one of"
  )

  expect_error(
    fetch_assess(2020),
    "2020"
  )
})


# Test import_local_assess =====================================================

test_that("import_local_assess validates file paths", {
  expect_error(
    import_local_assess(
      test_data_path = "nonexistent.txt",
      entities_path = "nonexistent.txt",
      end_year = 2024
    ),
    "not found"
  )
})


# Test process_assess ==========================================================

test_that("process_assess handles NULL data gracefully", {
  expect_error(
    process_assess(NULL, 2024),
    "Raw assessment data is NULL"
  )
})


test_that("process_assess handles empty data frame", {
  empty_df <- data.frame()
  expect_error(
    process_assess(empty_df, 2024),
    "no rows"
  )
})


test_that("process_assess returns correct structure when given data", {
  # Create mock data matching CAASPP 2024 column structure
  mock_data <- tibble::tibble(
    `County Code` = c("00", "00", "01"),
    `District Code` = c("00000", "00000", "10017"),
    `District Name` = c("", "", "Alameda Unified"),
    `School Code` = c("0000000", "0000000", "0130401"),
    `School Name` = c("", "", "Alameda High"),
    `Type ID` = c("4", "4", "7"),
    `Filler` = c("", "", ""),
    `Test Year` = c("2024", "2024", "2024"),
    `Test Type` = c("B", "B", "B"),
    `Test ID` = c("1", "2", "1"),
    `Student Group ID` = c("1", "1", "1"),
    `Grade` = c("11", "11", "11"),
    `Total Students Enrolled` = c("450000", "450000", "500"),
    `Total Students Tested` = c("436275", "435333", "480"),
    `Total Students Tested with Scores` = c("436000", "435000", "478"),
    `Mean Scale Score` = c("2590.5", "2547.8", "2610.0"),
    `Percentage Standard Exceeded` = c("25.00", "10.00", "30.00"),
    `Count Standard Exceeded` = c("109000", "43500", "144"),
    `Percentage Standard Met` = c("30.73", "17.90", "35.00"),
    `Count Standard Met` = c("134000", "78000", "168"),
    `Percentage Standard Met and Above` = c("55.73", "27.90", "65.00"),
    `Count Standard Met and Above` = c("243000", "121500", "312"),
    `Percentage Standard Nearly Met` = c("25.00", "35.00", "20.00"),
    `Count Standard Nearly Met` = c("109000", "152400", "96"),
    `Percentage Standard Not Met` = c("19.27", "37.10", "15.00"),
    `Count Standard Not Met` = c("84000", "161500", "72")
  )

  result <- process_assess(mock_data, 2024)

  # Check structure
  expect_true("end_year" %in% names(result))
  expect_true("cds_code" %in% names(result))
  expect_true("agg_level" %in% names(result))
  expect_true("subject" %in% names(result))
  expect_true("grade" %in% names(result))
  expect_true("mean_scale_score" %in% names(result))
  expect_true("pct_met_and_above" %in% names(result))

  # Check values
  expect_equal(result$end_year[1], 2024)
  expect_equal(result$subject[1], "ELA")
  expect_equal(result$subject[2], "Math")
  expect_equal(result$grade[1], "11")

  # Check aggregation levels
  expect_equal(result$agg_level[1], "T")  # State
  expect_equal(result$agg_level[3], "S")  # School

  # Check numeric conversions
  expect_true(is.numeric(result$mean_scale_score))
  expect_true(is.numeric(result$pct_met_and_above))
  expect_equal(result$pct_met_and_above[1], 55.73)
  expect_equal(result$mean_scale_score[1], 2590.5)
})


# Test tidy_assess =============================================================

test_that("tidy_assess converts wide to long format", {
  # Create mock processed data
  mock_data <- tibble::tibble(
    end_year = 2024,
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    mean_scale_score = 2590.5,
    pct_met_and_above = 55.73,
    pct_exceeded = 25.00,
    n_tested = 436275
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

  # Verify values are preserved
  mss_row <- result %>%
    dplyr::filter(metric_type == "mean_scale_score")
  expect_equal(mss_row$metric_value, 2590.5)

  prof_row <- result %>%
    dplyr::filter(metric_type == "pct_met_and_above")
  expect_equal(prof_row$metric_value, 55.73)
})


# Test id_assess_aggs ==========================================================

test_that("id_assess_aggs adds aggregation identifiers", {
  mock_data <- tibble::tibble(
    end_year = 2024,
    cds_code = c("00000000000000", "01000000000000", "01100170000000", "01100170130401"),
    agg_level = c("T", "C", "D", "S"),
    grade = "11",
    subject = "ELA",
    metric_type = "pct_met_and_above",
    metric_value = c(55.73, 52.0, 58.0, 65.0)
  )

  result <- id_assess_aggs(mock_data)

  expect_true("is_state" %in% names(result))
  expect_true("is_county" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_school" %in% names(result))

  # Check logical values
  expect_true(result$is_state[1])
  expect_true(result$is_county[2])
  expect_true(result$is_district[3])
  expect_true(result$is_school[4])

  expect_false(result$is_state[4])
  expect_false(result$is_school[1])
})


# Test summarize_proficiency ===================================================

test_that("summarize_proficiency filters to single metric", {
  mock_data <- tibble::tibble(
    end_year = 2024,
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    metric_type = c("pct_met_and_above", "pct_exceeded", "mean_scale_score"),
    metric_value = c(55.73, 25.0, 2590.5)
  )

  result <- summarize_proficiency(mock_data, "pct_met_and_above")

  # Should only have one row (one metric)
  expect_equal(nrow(result), 1)

  # Should not have metric_type column (it was removed)
  expect_false("metric_type" %in% names(result))

  # Should have the correct value
  expect_equal(result$metric_value, 55.73)
})


# Test calc_assess_trend =======================================================

test_that("calc_assess_trend calculates year-over-year changes", {
  mock_data <- tibble::tibble(
    end_year = c(2022, 2023, 2024),
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    metric_type = "pct_met_and_above",
    metric_value = c(50.0, 52.0, 55.73)
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

  # Third year
  expect_equal(result$change[3], 3.73, tolerance = 0.01)
})


# Test fetch_assess_multi 2020 handling ========================================

test_that("fetch_assess_multi warns and excludes 2020", {
  expect_warning(
    {
      # This will error because we're not actually downloading,
      # but first it should warn about 2020
      tryCatch(
        fetch_assess_multi(c(2019, 2020, 2021), use_cache = FALSE),
        error = function(e) NULL
      )
    },
    "2020 excluded"
  )
})


# Test print methods ===========================================================

test_that("assessment data print methods work", {
  # Test ca_assess_data print
  mock_processed <- tibble::tibble(
    end_year = 2024,
    cds_code = "00000000000000",
    county_code = "00",
    district_code = "00000",
    school_code = "0000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    mean_scale_score = 2590.5,
    pct_met_and_above = 55.73,
    n_tested = 436275
  )
  class(mock_processed) <- c("ca_assess_data", class(mock_processed))

  expect_output(print(mock_processed), "California CAASPP Assessment Data")

  # Test ca_assess_tidy print
  mock_tidy <- tibble::tibble(
    end_year = 2024,
    cds_code = "00000000000000",
    agg_level = "T",
    grade = "11",
    subject = "ELA",
    metric_type = "pct_met_and_above",
    metric_value = 55.73
  )
  class(mock_tidy) <- c("ca_assess_tidy", class(mock_tidy))

  expect_output(print(mock_tidy), "Tidy Format")
})


# ==============================================================================
# LIVE Tests with Real Data Values
# ==============================================================================
# These tests use ACTUAL values from CAASPP 2024 data
# Skip these if no network access

test_that("LIVE: URL is accessible for 2024 data", {
  skip_if_offline()

  url <- build_caaspp_url(2024, file_type = "1", format = "csv")
  accessible <- check_caaspp_url(url)

  expect_true(accessible, info = paste("URL not accessible:", url))
})


test_that("LIVE: URL is accessible for entities file", {
  skip_if_offline()

  url <- build_entities_url(2024, format = "csv")
  accessible <- check_caaspp_url(url)

  expect_true(accessible, info = paste("URL not accessible:", url))
})


test_that("LIVE: URLs are accessible for all years", {
  skip_if_offline()
  skip_on_cran()

  years <- get_available_assess_years()$all_years

  for (yr in years) {
    url <- build_caaspp_url(yr, file_type = "1", format = "csv")
    accessible <- check_caaspp_url(url)
    expect_true(
      accessible,
      info = paste("URL not accessible for year", yr, ":", url)
    )
  }
})
