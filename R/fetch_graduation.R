# ==============================================================================
# Graduation Rate Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading graduation rate data from the
# California Department of Education (CDE) School Dashboard.
#
# Data source: CDE Graduation Rate Indicator
# Available years: 2017-2025 (see get_available_grad_years())
#
# ==============================================================================

#' Fetch California graduation rate data
#'
#' Downloads and processes graduation rate data from the California Department
#' of Education (CDE) School Dashboard.
#'
#' @param end_year A school year. Year is the end of the academic year -
#'   eg 2023-24 school year is year '2024'. Valid values are 2017-2025.
#' @param tidy If TRUE (default), returns data in long (tidy) format with
#'   subgroup column. If FALSE, returns wide format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from CDE.
#' @return Data frame with graduation rate data. Includes columns for
#'   end_year, type, district_id, district_name, school_id, school_name,
#'   subgroup, metric, grad_rate, cohort_count, graduate_count,
#'   is_state, is_district, is_school.
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 graduation data (2023-24 school year)
#' grad_2024 <- fetch_graduation(2024)
#'
#' # Get historical data from 2018
#' grad_2018 <- fetch_graduation(2018)
#'
#' # Get wide format
#' grad_wide <- fetch_graduation(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' grad_fresh <- fetch_graduation(2024, use_cache = FALSE)
#'
#' # Filter to LA Unified schools
#' lausd <- grad_2024 |>
#'   dplyr::filter(district_name == "Los Angeles Unified")
#'
#' # Compare district rates
#' grad_2024 |>
#'   dplyr::filter(is_district, subgroup == "all") |>
#'   dplyr::select(district_name, grad_rate, cohort_count) |>
#'   dplyr::arrange(dplyr::desc(grad_rate))
#' }
fetch_graduation <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year
  available_years <- get_available_grad_years()
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between ", min(available_years), " and ", max(available_years), ". ",
      "Run get_available_grad_years() to see available years."
    ))
  }

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "grad_tidy" else "grad_wide"

  # Check cache first
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data from CDE
  raw <- get_raw_graduation(end_year)

  # Process to standard schema
  processed <- process_graduation(raw, end_year)

  # Optionally tidy
  if (tidy) {
    processed <- tidy_graduation(processed)
  }

  # Cache the result
  if (use_cache) {
    write_cache(processed, end_year, cache_type)
  }

  processed
}


#' Fetch graduation rate data for multiple years
#'
#' Downloads and combines graduation rate data for multiple school years.
#'
#' @param end_years Vector of school year ends (e.g., c(2020, 2021, 2022))
#' @param tidy If TRUE (default), returns data in long (tidy) format.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#' @return Combined data frame with graduation rate data for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get 5 years of data
#' grad_multi <- fetch_graduation_multi(2020:2024)
#'
#' # Track graduation rate trends
#' grad_multi |>
#'   dplyr::filter(is_state, subgroup == "all") |>
#'   dplyr::select(end_year, grad_rate, cohort_count)
#'
#' # Compare subgroups over time
#' grad_multi |>
#'   dplyr::filter(is_state, subgroup %in% c("all", "low_income", "english_learner")) |>
#'   dplyr::select(end_year, subgroup, grad_rate)
#' }
fetch_graduation_multi <- function(end_years, tidy = TRUE, use_cache = TRUE) {

  # Validate years
  available_years <- get_available_grad_years()
  invalid_years <- end_years[!end_years %in% available_years]
  if (length(invalid_years) > 0) {
    stop(paste("Invalid years:", paste(invalid_years, collapse = ", "),
               "\nAvailable years:", paste(range(available_years), collapse = "-")))
  }

  # Fetch each year
  results <- purrr::map(
    end_years,
    function(yr) {
      message(paste("Fetching", yr, "..."))
      fetch_graduation(yr, tidy = tidy, use_cache = use_cache)
    }
  )

  # Combine
  dplyr::bind_rows(results)
}


#' Clear graduation rate cache
#'
#' Removes all cached graduation rate data files.
#'
#' @param years Optional vector of years to clear. If NULL, clears all years.
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear all graduation cache
#' clear_grad_cache()
#'
#' # Clear only 2024 data
#' clear_grad_cache(2024)
#'
#' # Clear multiple years
#' clear_grad_cache(2020:2024)
#' }
clear_grad_cache <- function(years = NULL) {
  cache_dir <- get_cache_dir()

  if (is.null(years)) {
    # Clear all grad cache files
    files <- list.files(cache_dir, pattern = "^grad_.*\\.rds$", full.names = TRUE)
  } else {
    # Clear specific years
    patterns <- paste0("grad_.*_", years, "\\.rds$")
    files <- unlist(lapply(patterns, function(p) {
      list.files(cache_dir, pattern = p, full.names = TRUE)
    }))
  }

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached graduation file(s)"))
  } else {
    message("No graduation cache files to remove")
  }

  invisible(length(files))
}
