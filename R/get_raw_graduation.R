# ==============================================================================
# Raw Graduation Rate Data Download Functions - CDE
# ==============================================================================
#
# This file contains functions for downloading raw graduation rate data from the
# California Department of Education (CDE) School Dashboard.
#
# Data source: CDE Graduation Rate Indicator
# Available years: 2017-2025 (9 years)
# Format: Excel (.xlsx) files
#
# ==============================================================================

#' Base URL for CDE graduation rate downloads
#' @keywords internal
CDE_GRAD_BASE_URL <- "https://www3.cde.ca.gov/researchfiles/cadashboard"

#' Get available graduation years
#'
#' Returns a vector of years for which graduation rate data is available
#' from the California Department of Education.
#'
#' @return Integer vector of years (2017-2025)
#' @export
#' @examples
#' \dontrun{
#' get_available_grad_years()
#' # Returns: 2017 2018 2019 ... 2025
#' }
get_available_grad_years <- function() {
  c(2017, 2018, 2019, 2022, 2024, 2025)
}

#' Build graduation rate download URL for a given year
#'
#' Constructs the appropriate URL for downloading CDE graduation data.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return URL to download Excel file
#' @keywords internal
build_grad_url <- function(end_year) {

  # URL pattern: graddownload{year}.xlsx
  # Example: 2024 -> graddownload2024.xlsx
  url <- paste0(CDE_GRAD_BASE_URL, "/graddownload", end_year, ".xlsx")

  url
}

#' Download raw graduation data from CDE
#'
#' Downloads graduation rate data Excel file from CDE School Dashboard.
#'
#' @param end_year School year end (2023-24 = 2024). Valid years: 2017-2025.
#' @return Data frame with graduation data
#' @keywords internal
get_raw_graduation <- function(end_year) {

  # Validate year
  available_years <- get_available_grad_years()
  if (!end_year %in% available_years) {
    stop("end_year must be between ", min(available_years), " and ",
         max(available_years), ". Run get_available_grad_years() to see available years.")
  }

  message(paste("Downloading CDE graduation data for", end_year, "..."))

  # Build URL
  url <- build_grad_url(end_year)

  # Create temp file for Excel
  temp_xlsx <- tempfile(fileext = ".xlsx")

  # Download Excel file
  message("  Downloading Excel file from CDE...")
  response <- tryCatch({
    httr::GET(
      url,
      httr::write_disk(temp_xlsx, overwrite = TRUE),
      httr::timeout(120),
      httr::add_headers(
        Accept = "*/*"
      )
    )
  }, error = function(e) {
    stop("Failed to connect to CDE: ", e$message)
  })

  if (httr::http_error(response)) {
    stop(paste("HTTP error:", httr::status_code(response),
               "\nFailed to download graduation data for", end_year))
  }

  # Verify it's a valid Excel file (not HTML error page)
  file_info <- file.info(temp_xlsx)
  if (file_info$size < 1000) {
    stop("Downloaded file is too small to be a valid Excel file.")
  }

  message("  Downloaded ", round(file_info$size / 1024 / 1024, 2), " MB")

  # Read Excel file
  message("  Reading Excel file...")
  df <- tryCatch({
    readxl::read_excel(temp_xlsx)
  }, error = function(e) {
    stop("Failed to read Excel file: ", e$message)
  })

  # Clean up temp file
  unlink(temp_xlsx)

  message("  Loaded ", nrow(df), " rows, ", ncol(df), " columns")

  # Add end_year column
  df$end_year <- end_year

  df
}
