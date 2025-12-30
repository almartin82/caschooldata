# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data files from
# the California Department of Education (CDE) website.
#
# Data source: https://www.cde.ca.gov/ds/ad/filesenrcensus.asp
#
# ==============================================================================

#' Get raw enrollment data from CDE
#'
#' Downloads the raw enrollment data file for a given year from the California
#' Department of Education website. Uses modern Census Day files for 2024+
#' and historical school-level files for 2017-2023.
#'
#' @param end_year A school year end (e.g., 2024 for 2023-24 school year)
#' @return Raw data frame as downloaded from CDE
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  min_year <- 2018  # Historical enrollment files start at 2017-18
  max_year <- 2025  # Current Census Day files

  if (end_year < min_year) {
    stop(paste("end_year must be", min_year, "or later."))
  }

  if (end_year > max_year) {
    stop(paste("end_year must be", max_year, "or earlier."))
  }

  # Modern format (2024+): Census Day files with aggregation levels and subgroups
  # Historical format (2017-2023): School-level files with race/gender breakdown
  if (end_year >= 2024) {
    get_raw_enr_modern(end_year)
  } else {
    get_raw_enr_historical(end_year)
  }
}


#' Download modern Census Day format (2024+) CDE data
#'
#' @param end_year School year end
#' @return Raw data frame
#' @keywords internal
get_raw_enr_modern <- function(end_year) {

  # Build download URL
  url <- build_enr_url(end_year)

  message(paste("Downloading Census Day enrollment data for", end_year - 1, "-", substr(end_year, 3, 4), "..."))

  # Download file to temp location
  tname <- tempfile(pattern = "cde_enr", tmpdir = tempdir(), fileext = ".txt")

  # Set longer timeout for large files
  old_timeout <- getOption("timeout")
  options(timeout = 300)  # 5 minutes

  tryCatch({
    downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    options(timeout = old_timeout)
    stop(paste("Failed to download enrollment data from CDE:", e$message))
  })

  options(timeout = old_timeout)

  # Check if download was successful (file should be reasonably large)
  file_info <- file.info(tname)
  if (file_info$size < 100000) {
    stop(paste("Download failed for year", end_year, "- file too small, may be error page"))
  }

  # Read tab-delimited file
  # CDE files are tab-delimited with headers
  # Use locale to handle non-UTF-8 characters in school/district names
  df <- readr::read_tsv(
    tname,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "latin1")
  )

  # Add end_year column
  df$end_year <- as.integer(end_year)

  message(paste("Downloaded", nrow(df), "records"))

  df
}


#' Download historical format (2017-2023) CDE data
#'
#' Historical files contain school-level data only with race/ethnicity and
#' gender breakdown. Files are organized by year ranges.
#'
#' @param end_year School year end
#' @return Raw data frame
#' @keywords internal
get_raw_enr_historical <- function(end_year) {

  # Build download URL
  url <- build_historical_enr_url(end_year)

  message(paste("Downloading historical enrollment data for", end_year - 1, "-", substr(end_year, 3, 4), "..."))
  message("Note: Historical files are large and may take a few minutes to download.")

  # Download file to temp location - these files can be 90MB+
  tname <- tempfile(pattern = "cde_enr_hist", tmpdir = tempdir(), fileext = ".txt")

  # Set longer timeout for large files
  old_timeout <- getOption("timeout")
  options(timeout = 600)  # 10 minutes

  tryCatch({
    downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    options(timeout = old_timeout)
    stop(paste("Failed to download historical enrollment data from CDE:", e$message))
  })

  options(timeout = old_timeout)

  # Check if download was successful
  file_info <- file.info(tname)
  if (file_info$size < 1000000) {  # Historical files should be at least 1MB
    stop(paste("Download failed for year", end_year, "- file too small, may be error page"))
  }

  message(paste("Downloaded", round(file_info$size / 1024 / 1024, 1), "MB file"))

  # Read tab-delimited file
  # Historical files: ACADEMIC_YEAR, CDS_CODE, COUNTY, DISTRICT, SCHOOL,
  # ENR_TYPE, RACE_ETHNICITY, GENDER, GR_KN, GR_1-12, UNGR_ELM, UNGR_SEC, ENR_TOTAL, ADULT
  df <- readr::read_tsv(
    tname,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "latin1")
  )

  # Filter to requested year (files contain multiple years)
  year_label <- paste0(end_year - 1, "-", substr(end_year, 3, 4))
  df <- df %>%
    dplyr::filter(ACADEMIC_YEAR == year_label)

  # Add end_year column
  df$end_year <- as.integer(end_year)

  message(paste("Loaded", nrow(df), "records for", year_label))

  df
}


#' Build CDE enrollment file URL
#'
#' Constructs the download URL for a specific year's enrollment file.
#' Uses the Census Day enrollment file which has comprehensive grade-level data.
#'
#' @param end_year A school year end (e.g., 2024 for 2023-24 school year)
#' @return URL string
#' @keywords internal
build_enr_url <- function(end_year) {

  # Build 2-digit year codes for the school year
  # e.g., 2024 -> "2324" for 2023-24 school year
  start_yy <- sprintf("%02d", (end_year - 1) %% 100)
  end_yy <- sprintf("%02d", end_year %% 100)
  year_code <- paste0(start_yy, end_yy)

  # Census Day enrollment URL pattern
  # Example: https://www3.cde.ca.gov/demo-downloads/census/cdenroll2324.txt
  # Note: 2023-24 has a -v2 suffix
  if (end_year == 2024) {
    filename <- paste0("cdenroll", year_code, "-v2.txt")
  } else {
    filename <- paste0("cdenroll", year_code, ".txt")
  }

  url <- paste0("https://www3.cde.ca.gov/demo-downloads/census/", filename)

  url
}


#' Build CDE cumulative enrollment file URL
#'
#' Constructs the download URL for cumulative enrollment file (alternative data source).
#' Cumulative enrollment counts all students enrolled during the year, not just Census Day.
#'
#' @param end_year A school year end (e.g., 2024 for 2023-24 school year)
#' @return URL string
#' @keywords internal
build_cumulative_enr_url <- function(end_year) {

  # Build 2-digit year codes
  start_yy <- sprintf("%02d", (end_year - 1) %% 100)
  end_yy <- sprintf("%02d", end_year %% 100)
  year_code <- paste0(start_yy, end_yy)

  # Cumulative enrollment URL pattern
  # Example: https://www3.cde.ca.gov/demo-downloads/ce/cenroll2324.txt
  filename <- paste0("cenroll", year_code, ".txt")

  url <- paste0("https://www3.cde.ca.gov/demo-downloads/ce/", filename)

  url
}


#' Build CDE historical enrollment file URL
#'
#' Constructs the download URL for historical school-level enrollment files
#' (2018-2023). These files cover multiple years each.
#'
#' @param end_year A school year end (e.g., 2020 for 2019-20 school year)
#' @return URL string
#' @keywords internal
build_historical_enr_url <- function(end_year) {

  # Historical files are organized by 3-year ranges:
  # enr201719-v2.txt contains: 2017-18, 2018-19, 2019-20 (end_year 2018, 2019, 2020)
  # enr202022-v2.txt contains: 2020-21, 2021-22, 2022-23 (end_year 2021, 2022, 2023)

  if (end_year >= 2021 && end_year <= 2023) {
    # 2020-21, 2021-22, 2022-23
    filename <- "enr202022-v2.txt"
  } else if (end_year >= 2018 && end_year <= 2020) {
    # 2017-18, 2018-19, 2019-20
    filename <- "enr201719-v2.txt"
  } else {
    stop(paste("Historical data not available for end_year", end_year,
               ". Supported years are 2018-2023."))
  }

  url <- paste0("https://www3.cde.ca.gov/demo-downloads/enrsch/", filename)

  url
}
