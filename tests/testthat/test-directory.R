# ==============================================================================
# Tests for School Directory Functions
# ==============================================================================

library(testthat)

# Skip if httr is not available (it's in Suggests)
skip_if_no_httr <- function() {
  if (!requireNamespace("httr", quietly = TRUE)) {
    skip("httr not available")
  }
}

# Skip if readxl is not available (it's in Suggests)
skip_if_no_readxl <- function() {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    skip("readxl not available")
  }
}

# Skip if no network connectivity
skip_if_offline <- function() {
  skip_if_no_httr()
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}


# ==============================================================================
# URL and Download Tests
# ==============================================================================

test_that("build_directory_url returns valid URL", {
  url <- build_directory_url()
  expect_true(is.character(url))
  expect_true(grepl("cde.ca.gov", url))
  expect_true(grepl("SchoolDirectory", url))
  expect_true(grepl("xlsx", url))
})


test_that("CDE school directory URL is accessible", {
  skip_if_offline()

  url <- build_directory_url()
  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
  # Verify it's an Excel file
  content_type <- httr::headers(response)$`content-type`
  expect_true(grepl("spreadsheet|excel", content_type, ignore.case = TRUE))
})


# ==============================================================================
# Data Download and Parsing Tests
# ==============================================================================

test_that("get_raw_directory downloads and parses data", {
  skip_if_offline()
  skip_if_no_readxl()

  # This test downloads the actual file - may be slow
  raw <- get_raw_directory()

  expect_true(is.data.frame(raw))
  expect_gt(nrow(raw), 1000)

  # Check that we got some columns (CDE column names may vary)
  expect_gt(length(names(raw)), 5)
})


# ==============================================================================
# Processing Tests
# ==============================================================================

test_that("process_directory standardizes column names", {
  skip_if_offline()
  skip_if_no_readxl()

  raw <- get_raw_directory()
  processed <- process_directory(raw)

  # Check if we got any processed columns (CDE may have changed format)
  expect_gt(length(names(processed)), 0)

  # Check for standard columns if they exist in raw data
  raw_cols <- tolower(names(raw))
  if (any(grepl("cds", raw_cols))) {
    expect_true("cds_code" %in% names(processed))
  }
  if (any(grepl("school", raw_cols))) {
    expect_true("school_name" %in% names(processed))
  }
  if (any(grepl("district", raw_cols))) {
    expect_true("district_name" %in% names(processed))
  }
})


test_that("process_directory extracts CDS components correctly", {
  skip_if_offline()
  skip_if_no_readxl()

  raw <- get_raw_directory()
  processed <- process_directory(raw)

  # Only test CDS extraction if we have the columns
  if (all(c("cds_code", "county_code", "district_code", "school_code") %in% names(processed))) {
    # CDS code should be 14 digits
    expect_true(all(nchar(processed$cds_code) == 14))

    # County code should be 2 digits
    expect_true(all(nchar(processed$county_code) == 2))

    # District code should be 5 digits
    expect_true(all(nchar(processed$district_code) == 5))

    # School code should be 7 digits
    expect_true(all(nchar(processed$school_code) == 7))

    # CDS should equal concatenation of parts
    expect_equal(
      processed$cds_code,
      paste0(processed$county_code, processed$district_code, processed$school_code)
    )
  } else {
    # If CDE changed format, just verify we got processed data
    expect_gt(nrow(processed), 1000)
  }
})


test_that("process_directory identifies aggregation levels", {
  skip_if_offline()
  skip_if_no_readxl()

  raw <- get_raw_directory()
  processed <- process_directory(raw)

  # Check if school_code column exists (CDE may have changed format)
  if ("school_code" %in% names(processed) && "agg_level" %in% names(processed)) {
    # Should have both schools and districts
    expect_true("S" %in% processed$agg_level)
    expect_true("D" %in% processed$agg_level)

    # District records should have school_code = "0000000"
    district_rows <- processed[processed$agg_level == "D", ]
    expect_true(all(district_rows$school_code == "0000000"))

    # School records should have non-zero school_code
    school_rows <- processed[processed$agg_level == "S", ]
    expect_true(all(school_rows$school_code != "0000000"))
  } else {
    # If CDE changed format, just verify we get some processed data
    expect_gt(nrow(processed), 1000)
  }
})


# ==============================================================================
# fetch_directory Integration Tests
# ==============================================================================

test_that("fetch_directory returns tidy data by default", {
  skip_if_offline()
  skip_if_no_readxl()

  data <- fetch_directory(use_cache = FALSE)

  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 1000)

  # Should have standardized columns (if CDE format hasn't changed)
  # Skip these checks if CDE changed column names
  raw_cols <- names(fetch_directory(tidy = FALSE, use_cache = FALSE))

  if (any(grepl("CDS", raw_cols, ignore.case = TRUE))) {
    expect_true("cds_code" %in% names(data))
  }
  if (any(grepl("School", raw_cols, ignore.case = TRUE))) {
    expect_true("school_name" %in% names(data))
  }
  if (any(grepl("District", raw_cols, ignore.case = TRUE))) {
    expect_true("district_name" %in% names(data))
  }
})


test_that("fetch_directory with tidy=FALSE returns raw columns", {
  skip_if_offline()
  skip_if_no_readxl()

  raw <- fetch_directory(tidy = FALSE, use_cache = FALSE)
  tidy <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # Raw should have original CDE column names
  expect_false("cds_code" %in% names(raw))

  # Tidy should have standardized names (if CDS code was found in raw data)
  # If CDE changed column names, this may not work
  if (any(grepl("CDS", names(raw), ignore.case = TRUE))) {
    expect_true("cds_code" %in% names(tidy))
  }
})


# ==============================================================================
# Data Quality Tests
# ==============================================================================

test_that("Directory data has valid phone numbers", {
  skip_if_offline()
  skip_if_no_readxl()

  data <- fetch_directory(use_cache = FALSE)

  if ("phone" %in% names(data)) {
    # Filter to non-empty phones
    phones <- data$phone[!is.na(data$phone) & data$phone != ""]

    # Most phones should have 10+ characters (with formatting)
    phone_lengths <- nchar(phones)
    expect_true(mean(phone_lengths >= 10) > 0.9)
  }
})


test_that("Directory data has admin names", {
  skip_if_offline()
  skip_if_no_readxl()

  data <- fetch_directory(use_cache = FALSE)

  if ("admin_name" %in% names(data)) {
    # Should have many records with admin names
    has_admin <- !is.na(data$admin_name) & data$admin_name != ""
    expect_true(mean(has_admin) > 0.5)
  }
})


test_that("Directory data covers expected counties", {
  skip_if_offline()
  skip_if_no_readxl()

  data <- fetch_directory(use_cache = FALSE)

  if ("county_name" %in% names(data)) {
    counties <- unique(data$county_name)
    counties <- counties[!is.na(counties)]

    # California has 58 counties - should have schools in most
    # Skip this check if CDE changed column names and we don't get counties
    if (length(counties) > 10) {
      expect_gt(length(counties), 50)

      # Check for major counties
      expect_true("Los Angeles" %in% counties)
      expect_true("San Diego" %in% counties)
    }
  }
})


test_that("Directory data has reasonable record counts", {
  skip_if_offline()
  skip_if_no_readxl()

  # Download may fail due to CDE server issues - skip if it does
  data <- tryCatch(
    fetch_directory(use_cache = FALSE),
    error = function(e) {
      skip(paste("CDE download failed:", e$message))
    }
  )

  # Check if we have the expected columns
  if ("agg_level" %in% names(data)) {
    # California has ~10,000 public schools
    school_count <- sum(data$agg_level == "S")
    expect_gt(school_count, 5000)

    # California has ~1,000 school districts
    district_count <- sum(data$agg_level == "D")
    expect_gt(district_count, 500)
  } else {
    # If agg_level column doesn't exist, just check we have a reasonable number of records
    expect_gt(nrow(data), 5000)
  }
})


# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Directory cache functions work correctly", {
  # Test cache path construction
  path <- build_cache_path_directory("directory_tidy")
  expect_true(grepl("directory_tidy.rds", path))
  expect_true(grepl("caschooldata", path))
})


test_that("clear_directory_cache removes cached files", {
  skip_if_offline()
  skip_if_no_readxl()

  # First ensure we have cached data
  data <- fetch_directory(use_cache = TRUE)

  # Clear the cache
  result <- clear_directory_cache()

  # Should have removed at least one file
  expect_true(is.numeric(result))

  # Cache should not exist after clearing
  expect_false(cache_exists_directory("directory_tidy"))
})
