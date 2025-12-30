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
#' Department of Education website.
#'
#' @param end_year A school year end (e.g., 2024 for 2023-24 school year)
#' @return Raw data frame as downloaded from CDE
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  min_year <- 2017  # Cumulative enrollment files start at 2016-17

if (end_year < min_year) {
    stop(paste("end_year must be", min_year, "or later. Historical data requires different handling."))
  }

  # Build download URL
  url <- build_enr_url(end_year)

  message(paste("Downloading enrollment data for", end_year - 1, "-", substr(end_year, 3, 4), "..."))

  # Download file to temp location
  tname <- tempfile(pattern = "cde_enr", tmpdir = tempdir(), fileext = ".txt")

  tryCatch({
    downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    stop(paste("Failed to download enrollment data from CDE:", e$message))
  })

  # Check if download was successful (file should be reasonably large)
  file_info <- file.info(tname)
  if (file_info$size < 100000) {
    stop(paste("Download failed for year", end_year, "- file too small, may be error page"))
  }

  # Read tab-delimited file
  # CDE files are tab-delimited with headers
  df <- readr::read_tsv(
    tname,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE
  )

  # Add end_year column
  df$end_year <- as.integer(end_year)

  message(paste("Downloaded", nrow(df), "records"))

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
