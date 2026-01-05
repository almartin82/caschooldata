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
#'   for the 2023-24 school year. Supports 1982-2025:
#'   - 2024-2025: Modern Census Day files with full demographic breakdowns
#'   - 2008-2023: Historical files with race/gender data and entity names
#'   - 1994-2007: Historical files with race/gender data (no entity names)
#'   - 1982-1993: Historical files with letter-based race codes
#' @param tidy If TRUE (default), returns data in long (tidy) format with grade
#'   and subgroup columns. If FALSE, returns wide format with grade columns.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from CDE.
#' @return A tibble with enrollment data. In tidy format, includes columns:
#'   \itemize{
#'     \item \code{end_year}: School year end (integer)
#'     \item \code{district_id}: 5-digit district identifier (formerly district_code)
#'     \item \code{campus_id}: 7-digit campus identifier (formerly school_code, NA for district rows)
#'     \item \code{district_name}: District name
#'     \item \code{campus_name}: Campus name (formerly school_name, NA for district rows)
#'     \item \code{type}: Aggregation level ("State", "County", "District", or "Campus")
#'     \item \code{grade_level}: Grade (TK, K, 01-12, TOTAL, K8, HS, or K12). Note: TK is NA for 1982-2023.
#'     \item \code{subgroup}: Demographic subgroup (total, hispanic, white, asian, black, etc.)
#'     \item \code{n_students}: Enrollment count
#'     \item \code{pct}: Percentage of total enrollment (0-1 scale)
#'     \item \code{academic_year}: Academic year label (e.g., "2023-24")
#'     \item \code{cds_code}: 14-digit CDS identifier
#'     \item \code{county_code}: 2-digit county code
#'     \item \code{county_name}: County name
#'     \item \code{charter_status}: Charter indicator (All/Y/N)
#'     \item \code{is_state}, \code{is_county}, \code{is_district}, \code{is_school}: Boolean flags
#'   }
#' @details
#' Historical data differs from modern (2024+) data in several ways:
#' - Transitional Kindergarten (TK) data is not available (grade_tk is NA)
#' - Charter status is not available (charter_status is "All")
#' - District and county aggregates are computed from school-level data
#' - Student group categories (SG_*) are not available
#' - For 1994-2007: Entity names are not available (use CDS code to look up)
#' - For 1982-1993: Race categories use different coding (mapped to modern codes)
#'
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 enrollment data (2023-24 school year)
#' enr_2024 <- fetch_enr(2024)
#'
#' # Get historical data (2019-20 school year)
#' enr_2020 <- fetch_enr(2020)
#'
#' # Get data from the 1990s
#' enr_1995 <- fetch_enr(1995)
#'
#' # Get wide format (one column per grade)
#' enr_wide <- fetch_enr(2024, tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' enr_fresh <- fetch_enr(2024, use_cache = FALSE)
#'
#' # Filter to school-level total enrollment
#' library(dplyr)
#' schools <- enr_2024 |>
#'   filter(type == "Campus", subgroup == "total", grade_level == "TOTAL")
#' }
fetch_enr <- function(end_year, tidy = TRUE, use_cache = TRUE) {

  # Validate year using get_available_years()
  available_years <- get_available_years()
  min_year <- min(available_years)
  max_year <- max(available_years)

  if (end_year < min_year || end_year > max_year) {
    stop(paste0(
      "end_year must be between ", min_year, " and ", max_year, ".\n",
      "Use get_available_years() to see all available years."
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
    result <- tidy_enr(processed) |>
      id_enr_aggs()

    # Reorder columns: PRD columns first, then CA-specific, then helpers
    prd_cols <- c(
      "end_year", "district_id", "campus_id", "district_name", "campus_name",
      "type", "grade_level", "subgroup", "n_students", "pct"
    )
    ca_cols <- c(
      "academic_year", "cds_code", "county_code", "county_name",
      "charter_status", "agg_level", "reporting_category", "total_enrollment"
    )
    helper_cols <- c(
      "is_state", "is_county", "is_district", "is_school", "is_charter"
    )

    # Build column order
    all_possible <- c(prd_cols, ca_cols, helper_cols)
    col_order <- all_possible[all_possible %in% names(result)]
    remaining <- setdiff(names(result), col_order)
    col_order <- c(col_order, remaining)

    result <- result |>
      dplyr::select(dplyr::all_of(col_order))
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
