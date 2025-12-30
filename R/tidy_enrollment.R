# ==============================================================================
# Enrollment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for converting enrollment data from wide format
# to tidy (long) format.
#
# ==============================================================================

#' Convert enrollment data to tidy format
#'
#' Pivots enrollment data from wide format (one column per demographic group)
#' to long format with a subgroup column.
#'
#' @param wide_data Data frame in wide format from process_enr()
#' @return Tidy data frame with subgroup column
#' @export
#' @examples
#' \dontrun{
#' # Get wide format and then tidy
#' wide <- fetch_enr(2024, tidy = FALSE)
#' tidy <- tidy_enr(wide)
#' }
tidy_enr <- function(wide_data) {

  # TODO: Identify which columns are enrollment counts vs identifiers

  # TODO: Pivot longer on enrollment columns

  # TODO: Create subgroup column from original column names

  # TODO: Ensure proper column ordering

  # TODO: Return tidy data frame

  stop("tidy_enr() not yet implemented for California data")
}


#' Identify aggregation rows in enrollment data
#'
#' Marks rows that represent aggregated data (state, county, or district totals)
#' vs individual school data based on CDS code patterns.
#'
#' @param data Tidy enrollment data frame
#' @return Data frame with agg_level column added
#' @export
id_enr_aggs <- function(data) {

  # TODO: Identify state-level rows (all zeros or special code)

  # TODO: Identify county-level rows (district and school portions zero)

  # TODO: Identify district-level rows (school portion zero)

  # TODO: Mark remaining as school-level

  # TODO: Add agg_level column

  # TODO: Return data with agg_level

  stop("id_enr_aggs() not yet implemented for California data")
}
