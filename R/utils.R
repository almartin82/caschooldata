# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
NULL


#' Get available years for California enrollment data
#'
#' Returns a vector of end years for which enrollment data is available
#' from the California Department of Education. This includes both modern
#' Census Day files (2024+) and historical enrollment files (1982-2023).
#'
#' @return Integer vector of available end years (1982-2025)
#' @export
#' @examples
#' get_available_years()
#'
#' # Check if a specific year is available
#' 2024 %in% get_available_years()
get_available_years <- function() {
  # California enrollment data is available from 1982 to present

  # - Historical files (1982-2023): school-level data with race/gender breakdown
  # - Modern Census Day files (2024+): full demographic breakdowns with aggregation levels
  1982:2025
}
