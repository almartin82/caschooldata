# ==============================================================================
# Enrollment Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading enrollment data from the
# California Department of Education (CDE) website.
#
# ==============================================================================

#' Fetch California enrollment data
#'
#' Downloads and processes enrollment data from the California Department of
#' Education DataQuest data files. Data is based on Census Day enrollment
#' (first Wednesday in October).
#'
#' @param end_year A school year. Year is the end of the academic year - e.g., 2024
#'   for the 2023-24 school year. Currently supports 2024-2025 (Census Day files).
#' @param tidy If TRUE (default), returns data in long (tidy) format with grade
#'   and subgroup columns. If FALSE, returns wide format with grade columns.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from CDE.
#' @return A tibble with enrollment data. In tidy format, includes columns:
#'   \itemize{
#'     \item \code{end_year}: School year end (integer)
#'     \item \code{cds_code}: 14-digit CDS identifier
#'     \item \code{county_code}: 2-digit county code
#'     \item \code{district_code}: 5-digit district code
#'     \item \code{school_code}: 7-digit school code
#'     \item \code{agg_level}: Aggregation level (T=State, C=County, D=District, S=School)
#'     \item \code{county_name}, \code{district_name}, \code{school_name}: Entity names
#'     \item \code{charter_status}: Charter indicator (Y/N/All)
#'     \item \code{grade_level}: Grade (TK, K, 01-12, or TOTAL)
#'     \item \code{reporting_category}: CDE demographic category code
#'     \item \code{subgroup}: Human-readable subgroup name
#'     \item \code{n_students}: Enrollment count
#'   }
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 enrollment data (2023-24 school year)
#' enr_2024 <- fetch_enr(2024)
#'
#' # Get wide format (one column per grade)
#' enr_wide <- fetch_enr(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' enr_fresh <- fetch_enr(2024, use_cache = FALSE)
#'
#' # Filter to school-level total enrollment
#' library(dplyr)
#' schools <- enr_2024 %>%
#'   filter(agg_level == "S", reporting_category == "TA", grade_level == "TOTAL")
#' }
fetch_enr <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  # Census Day enrollment files are available for 2024 and 2025
  # Earlier years use different file formats
  min_year <- 2024
  max_year <- 2025

  if (end_year < min_year || end_year > max_year) {
    stop(paste0(
      "end_year must be between ", min_year, " and ", max_year, ". ",
      "Census Day enrollment files are currently available for these years only."
    ))
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "tidy" else "wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from CDE
  raw <- get_raw_enr(end_year)

  # Process to standard schema
  processed <- process_enr(raw, end_year)

  # Optionally tidy (pivot to long format)
  if (tidy) {
    result <- tidy_enr(processed) %>%
      id_enr_aggs()
  } else {
    result <- processed
  }

  # Cache the result
  if (use_cache) {
    write_cache(result, end_year, cache_type)
  }

  result
}


#' Fetch enrollment for multiple years
#'
#' Convenience function to download enrollment data for multiple years at once.
#'
#' @param years Vector of school year ends (e.g., c(2024, 2025))
#' @param tidy If TRUE (default), returns tidy format
#' @param use_cache If TRUE (default), uses cache when available
#' @return Combined tibble with data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 and 2025 data
#' enr_multi <- fetch_enr_multi(c(2024, 2025))
#' }
fetch_enr_multi <- function(years, tidy = TRUE, use_cache = TRUE) {

  results <- purrr::map_df(years, function(y) {
    fetch_enr(end_year = y, tidy = tidy, use_cache = use_cache)
  })

  results
}
