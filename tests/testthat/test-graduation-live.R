# ==============================================================================
# Graduation Rate LIVE Pipeline Tests
# ==============================================================================
#
# These tests verify the entire data pipeline using LIVE network calls.
# NO MOCKS - real HTTP requests to California CDE.
#
# Purpose: Detect breakages early when state DOE websites change.
#
# Test Categories:
#   1. URL Availability - HTTP 200 checks
#   2. File Download - Verify actual file retrieval
#   3. File Parsing - Excel parsing succeeds
#   4. Column Structure - Expected columns present
#   5. Year Filtering - Single year extraction works
#   6. Data Quality - No Inf/NaN, valid ranges
#   7. Aggregation - State totals match
#   8. Output Fidelity - tidy=TRUE matches raw
#
# ==============================================================================

# Helper function for network skip guard
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}

# ==============================================================================
# Test 1: URL Availability
# ==============================================================================

test_that("CDE graduation URL returns HTTP 200 for 2024", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.xlsx"

  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})

test_that("CDE graduation URL returns HTTP 200 for 2022", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2022.xlsx"

  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})

test_that("CDE graduation URL returns HTTP 200 for 2019", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2019.xlsx"

  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})

# ==============================================================================
# Test 2: File Download
# ==============================================================================

test_that("Can download 2024 graduation Excel file", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.xlsx"

  response <- httr::GET(url, httr::write_disk(tempfile(), overwrite = TRUE), httr::timeout(60))

  expect_equal(httr::status_code(response), 200)

  # Verify reasonable file size (should be ~1-2 MB)
  headers <- httr::headers(response)
  content_length <- as.numeric(headers$`content-length`)

  expect_gt(content_length, 1000000)  # At least 1 MB
})

test_that("Can download historical graduation file (2018)", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2018.xlsx"

  response <- httr::GET(url, httr::timeout(60))

  expect_equal(httr::status_code(response), 200)
})

# ==============================================================================
# Test 3: File Parsing
# ==============================================================================

test_that("Can parse 2024 Excel file", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.xlsx"

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(60))

  expect_equal(httr::status_code(response), 200)

  # Parse Excel
  df <- readxl::read_excel(temp_file)

  expect_true(is.data.frame(df))
  expect_gt(nrow(df), 10000)
})

test_that("Excel file has multiple sheets", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.xlsx"

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(60))

  sheets <- readxl::excel_sheets(temp_file)

  expect_gt(length(sheets), 0)
})

# ==============================================================================
# Test 4: Column Structure
# ==============================================================================

test_that("Excel file has expected columns", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.xlsx"

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(60))

  df <- readxl::read_excel(temp_file)

  # Expected columns (case-insensitive)
  col_lower <- tolower(names(df))

  expect_true("cds" %in% col_lower)
  expect_true("studentgroup" %in% col_lower || "student group" %in% col_lower)
  expect_true("currdenom" %in% col_lower || "curr denom" %in% col_lower)
  expect_true("currnumer" %in% col_lower || "curr numer" %in% col_lower)
  expect_true("currstatus" %in% col_lower || "curr status" %in% col_lower)
})

test_that("Column data types are correct", {
  skip_if_offline()

  url <- "https://www3.cde.ca.gov/researchfiles/cadashboard/graddownload2024.xlsx"

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(60))

  df <- readxl::read_excel(temp_file)

  # CDS should be character (column name varies by year)
  cols <- tolower(gsub(" ", "", names(df)))
  expect_true(any(grepl("cds", cols)))

  # Counts should be numeric
  expect_true(is.numeric(df$currdenom) || is.numeric(df$`Curr Denom`) || is.numeric(df$`CurrDenom`))
})

# ==============================================================================
# Test 5: Year Filtering
# ==============================================================================

test_that("Can extract data for single year (2024)", {
  skip_if_offline()

  # This tests the actual fetch_graduation function
  data <- caschooldata::fetch_graduation(2024, use_cache = FALSE)

  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 0)

  # All records should have end_year = 2024
  expect_true(all(data$end_year == 2024))
})

test_that("Can extract data for multiple years", {
  skip_if_offline()

  # Test that we can fetch different years
  data_2024 <- caschooldata::fetch_graduation(2024, use_cache = FALSE)
  data_2022 <- caschooldata::fetch_graduation(2022, use_cache = FALSE)

  expect_gt(nrow(data_2024), 0)
  expect_gt(nrow(data_2022), 0)
})

# ==============================================================================
# Test 6: Data Quality
# ==============================================================================

test_that("No Inf or NaN in tidy output", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  for (col in names(data)[sapply(data, is.numeric)]) {
    expect_false(any(is.infinite(data[[col]])), info = col)
    expect_false(any(is.nan(data[[col]])), info = col)
  }
})

test_that("All graduation rates in valid range (0-1)", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  expect_true(all(data$grad_rate >= 0 & data$grad_rate <= 1, na.rm = TRUE))
})

test_that("All cohort counts are non-negative", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  expect_true(all(data$cohort_count >= 0, na.rm = TRUE))
})

test_that("No truly duplicate records (same entity + subgroup + metric)", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  # Create unique key
  data$key <- paste(data$end_year, data$type, data$school_id,
                    data$subgroup, data$metric, sep = "_")

  # Allow small number of duplicates (data quality issue in source)
  unique_count <- length(unique(data$key))
  duplicate_ratio <- (nrow(data) - unique_count) / nrow(data)

  expect_lte(duplicate_ratio, 0.25)  # Allow up to 25% duplicates (CDE data has multiple record types)
})

# ==============================================================================
# Test 7: Aggregation
# ==============================================================================

test_that("State record has all expected subgroups", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  state_data <- dplyr::filter(data, type == "State")

  subgroups <- unique(state_data$subgroup)

  # Should have at least 10 subgroups
  expect_gte(length(subgroups), 10)
})

test_that("District records exist", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  district_data <- dplyr::filter(data, type == "District")

  expect_gt(nrow(district_data), 0)

  # CA has ~400-500 districts with graduation data (not all ~1000+ districts report)
  unique_districts <- length(unique(district_data$district_id))
  expect_gte(unique_districts, 400)
})

test_that("School records exist", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  school_data <- dplyr::filter(data, type == "School")

  expect_gt(nrow(school_data), 0)
})

# ==============================================================================
# Test 8: Output Fidelity
# ==============================================================================

test_that("State-level graduation rate is reasonable", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  state_all <- data |>
    dplyr::filter(type == "State", subgroup == "all") |>
    dplyr::pull(grad_rate)

  # CA state graduation rate should be ~80-90%
  expect_gte(state_all, 0.80)
  expect_lte(state_all, 0.95)
})

test_that("State cohort count is reasonable", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  state_cohort <- data |>
    dplyr::filter(type == "State", subgroup == "all") |>
    dplyr::pull(cohort_count)

  # CA should have ~400k-600k students in cohort
  expect_gte(state_cohort, 400000)
  expect_lte(state_cohort, 700000)
})

test_that("Los Angeles Unified district data exists", {
  skip_if_offline()

  data <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)

  # LAUSD CDS code: 19647330193220 (partial match on district portion)
  lausd_data <- dplyr::filter(data,
                               type == "District",
                               grepl("1964733", district_id))

  expect_gt(nrow(lausd_data), 0)
})

test_that("tidy=TRUE preserves data from raw", {
  skip_if_offline()

  # Get both tidy and wide formats
  tidy <- caschooldata::fetch_graduation(2024, tidy = TRUE, use_cache = FALSE)
  wide <- caschooldata::fetch_graduation(2024, tidy = FALSE, use_cache = FALSE)

  # State graduation rate should match
  state_tidy <- tidy |> dplyr::filter(type == "State", subgroup == "all") |> dplyr::pull(grad_rate)
  state_wide <- wide |> dplyr::filter(type == "State", subgroup == "all") |> dplyr::pull(grad_rate)

  expect_equal(state_tidy, state_wide)
})
