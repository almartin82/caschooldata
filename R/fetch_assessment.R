# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains user-facing functions for fetching California CAASPP
# assessment data. These functions combine download, processing, and tidying
# into a simple interface.
#
# ==============================================================================

#' @importFrom rlang .data
#' @importFrom utils head
NULL

#' Fetch California CAASPP assessment data
#'
#' Downloads and processes CAASPP Smarter Balanced assessment data from the
#' California Department of Education. Includes test results for grades 3-8
#' and 11 in ELA and Mathematics.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year).
#'   Supports 2015-2025. Note: 2020 had no statewide testing due to COVID-19.
#' @param tidy If TRUE (default), returns data in long (tidy) format with
#'   metric_type and metric_value columns. If FALSE, returns wide format
#'   with separate columns for each metric.
#' @param subject Assessment subject to fetch: "Both" (default), "ELA", or "Math"
#' @param student_group "ALL" (default) for all students aggregate, or "GROUPS"
#'   for all student group breakdowns (demographics, EL status, etc.)
#' @param local_data Optional local data from \code{\link{import_local_assess}()}
#'   to use instead of downloading. Use this when you have manually downloaded
#'   CAASPP files from the portal.
#' @param use_cache If TRUE (default), uses locally cached data when available
#'
#' @return A tibble with assessment data. In tidy format, includes columns:
#'   \itemize{
#'     \item \code{end_year}: School year end (integer)
#'     \item \code{cds_code}: 14-digit CDS identifier
#'     \item \code{county_code}, \code{district_code}, \code{school_code}: CDS components
#'     \item \code{agg_level}: Aggregation level (S=School, D=District, C=County, T=State)
#'     \item \code{grade}: Grade level (03, 04, 05, 06, 07, 08, 11, or 13 for all grades)
#'     \item \code{subject}: Assessment subject (ELA or Math)
#'     \item \code{metric_type}: Type of metric (only in tidy format)
#'     \item \code{metric_value}: Value of the metric (only in tidy format)
#'   }
#'
#' @details
#' ## Available Years:
#' \itemize{
#'   \item 2015-2019: Pre-COVID baseline data
#'   \item 2020: No statewide testing (COVID-19)
#'   \item 2021: Reduced participation
#'   \item 2022-2025: Full post-pandemic data
#' }
#'
#' ## Data Source:
#' California CAASPP Smarter Balanced Assessments
#' Portal: https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB
#'
#' @export
#' @examples
#' \dontrun{
#' library(caschooldata)
#' library(dplyr)
#'
#' # Fetch 2024 assessment data
#' assess_2024 <- fetch_assess(end_year = 2024, tidy = TRUE)
#'
#' # State-level 11th grade proficiency
#' state_11_prof <- assess_2024 %>%
#'   filter(agg_level == "T",
#'          grade == "11",
#'          metric_type == "pct_met_and_above")
#'
#' # District-level comparison
#' district_ela <- assess_2024 %>%
#'   filter(agg_level == "D",
#'          grade == "11",
#'          subject == "ELA",
#'          metric_type == "pct_met_and_above") %>%
#'   arrange(desc(metric_value))
#' }
fetch_assess <- function(end_year,
                         tidy = TRUE,
                         subject = c("Both", "ELA", "Math"),
                         student_group = c("ALL", "GROUPS"),
                         local_data = NULL,
                         use_cache = TRUE) {

  subject <- match.arg(subject)
  student_group <- match.arg(student_group)

  # Validate year
  available_years <- get_available_assess_years()$all_years
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be one of: ", paste(available_years, collapse = ", "), ".\n",
      "CAASPP assessments started in 2014-15 (end_year=2015).\n",
      "2020 had no statewide testing due to COVID-19."
    ))
  }

  # Check cache first
  cache_type <- if (tidy) "assess_tidy" else "assess_wide"
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Check if local_data is provided
  if (!is.null(local_data)) {
    # Use locally imported data
    message("Using locally imported assessment data")
    processed <- process_assess(local_data$test_data, end_year)
  } else {
    # Download directly from CAASPP portal
    raw <- get_raw_assess(
      end_year = end_year,
      subject = subject,
      student_group = student_group
    )

    if (is.null(raw$test_data) || nrow(raw$test_data) == 0) {
      stop(
        "Failed to download CAASPP data for ", end_year, ".\n",
        "Please try again or download manually from:\n",
        "https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB"
      )
    }

    processed <- process_assess(raw$test_data, end_year)
  }

  # Optionally tidy (pivot to long format)
  if (tidy) {
    result <- tidy_assess(processed) %>%
      id_assess_aggs()
  } else {
    result <- processed
  }

  # Cache the result
  if (use_cache) {
    write_cache(result, end_year, cache_type)
  }

  result
}


#' Fetch CAASPP assessment data for multiple years
#'
#' Convenience function to download assessment data for multiple years at once.
#' Note: 2020 is automatically excluded (no statewide testing due to COVID-19).
#'
#' @param years Vector of school year ends (e.g., c(2019, 2021, 2022))
#' @param tidy If TRUE (default), returns tidy format
#' @param subject Assessment subject: "Both" (default), "ELA", or "Math"
#' @param student_group "ALL" (default) or "GROUPS"
#' @param local_data_list Named list of local data for each year
#' @param use_cache If TRUE (default), uses cache when available
#'
#' @return Combined tibble with data for all requested years
#'
#' @export
#' @examples
#' \dontrun{
#' # Get 2019-2024 assessment data (2020 automatically excluded)
#' assess_multi <- fetch_assess_multi(
#'   years = 2019:2024,
#'   tidy = TRUE
#' )
#'
#' # Calculate multi-year trend
#' library(dplyr)
#'
#' state_trend <- assess_multi %>%
#'   filter(agg_level == "T",
#'          grade == "11",
#'          subject == "ELA",
#'          metric_type == "pct_met_and_above") %>%
#'   select(end_year, metric_value) %>%
#'   mutate(
#'     change = metric_value - lag(metric_value),
#'     pct_change = (metric_value / lag(metric_value) - 1) * 100
#'   )
#' }
fetch_assess_multi <- function(years,
                               tidy = TRUE,
                               subject = c("Both", "ELA", "Math"),
                               student_group = c("ALL", "GROUPS"),
                               local_data_list = NULL,
                               use_cache = TRUE) {

  subject <- match.arg(subject)
  student_group <- match.arg(student_group)

  # Get available years
  available <- get_available_assess_years()

  # Remove 2020 if present (COVID year - no statewide testing)
  if (2020 %in% years) {
    warning("2020 excluded: No statewide CAASPP testing due to COVID-19.")
    years <- years[years != 2020]
  }

  # Validate years
  invalid_years <- years[!years %in% available$all_years]
  if (length(invalid_years) > 0) {
    stop(paste0(
      "Invalid years: ", paste(invalid_years, collapse = ", "), "\n",
      "Valid years are: ", paste(available$all_years, collapse = ", ")
    ))
  }

  if (length(years) == 0) {
    stop("No valid years to fetch")
  }

  # Fetch each year
  results <- purrr::map(
    years,
    function(y) {
      message(paste("Fetching", y, "..."))
      local_data <- if (!is.null(local_data_list) && as.character(y) %in% names(local_data_list)) {
        local_data_list[[as.character(y)]]
      } else {
        NULL
      }

      tryCatch({
        fetch_assess(
          end_year = y,
          tidy = tidy,
          subject = subject,
          student_group = student_group,
          local_data = local_data,
          use_cache = use_cache
        )
      }, error = function(e) {
        warning(paste("Failed to fetch year", y, ":", e$message))
        data.frame()
      })
    }
  )

  # Combine, filtering out empty data frames
  results <- results[!sapply(results, function(x) nrow(x) == 0)]
  dplyr::bind_rows(results)
}


