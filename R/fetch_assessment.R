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
#' @param end_year School year end (e.g., 2023 for 2022-23 school year).
#'   Supports 2015-2024. Note: 2020 data may be limited due to COVID-19.
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
#'   \item 2020: Limited data (COVID-19 disruptions)
#'   \item 2021: Reduced participation
#'   \item 2022-2024: Full post-pandemic data
#' }
#'
#' ## Data Source:
#' California CAASPP Smarter Balanced Assessments
#' Portal: https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB
#'
#' ## Manual Download Required:
#' The CAASPP portal does not provide publicly documented direct download URLs.
#' Users must:
#' \enumerate{
#'   \item Visit the CAASPP Research Files portal
#'   \item Download statewide research files (caret-delimited format)
#'   \item Use \code{\link{import_local_assess}()} to load the files
#'   \item This function will then process the data
#' }
#'
#' See \code{vignette("assessment")} for detailed examples.
#'
#' @export
#' @examples
#' \dontrun{
#' library(caschooldata)
#' library(dplyr)
#'
#' # After manually downloading CAASPP files:
#' local_files <- import_local_assess(
#'   test_data_path = "~/Downloads/sb_ca_2023_allstudents_csv.txt",
#'   entities_path = "~/Downloads/entities_2023.txt",
#'   end_year = 2023
#' )
#'
#' # Fetch processed assessment data
#' assess_2023 <- fetch_assess(
#'   end_year = 2023,
#'   local_data = local_files,
#'   tidy = TRUE
#' )
#'
#' # State-level 11th grade proficiency
#' state_11_prof <- assess_2023 %>%
#'   filter(agg_level == "T",
#'          grade == "11",
#'          metric_type == "pct_met_and_above")
#'
#' # District-level comparison
#' district_ela <- assess_2023 %>%
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
  available_years <- 2015:2024
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between 2015 and 2024.\n",
      "CAASPP assessments started in 2014-15 (end_year=2015).\n",
      "2020 data may be limited due to COVID-19 disruptions."
    ))
  }

  # Check if local_data is provided
  if (!is.null(local_data)) {
    # Use locally imported data
    message("Using locally imported assessment data")
    processed <- process_assess(local_data$test_data, end_year)
  } else {
    # Attempt to download (will provide manual instructions)
    message("\nCAASPP assessment data requires manual download from the ETS portal.")
    message("Attempting to locate cached data or provide download instructions...\n")

    # Check cache first
    cache_type <- if (tidy) "assess_tidy" else "assess_wide"
    if (use_cache && cache_exists(end_year, cache_type)) {
      message(paste("Using cached assessment data for", end_year))
      return(read_cache(end_year, cache_type))
    }

    # Try to download (will fail with instructions)
    raw <- get_raw_assess(
      end_year = end_year,
      subject = subject,
      student_group = student_group
    )

    if (is.null(raw$test_data)) {
      stop(
        "No test data found. Please download CAASPP files manually:\n\n",
        "1. Visit: ", raw$portal_url, "\n",
        "2. Download 'California Statewide research file, All Students, ",
        "caret-delimited'\n",
        "3. Download the Entity file for ", raw$test_year, "\n",
        "4. Use import_local_assess() to load the files\n",
        "5. Pass the result to fetch_assess(local_data = ...)\n\n",
        "For detailed instructions, see:\n",
        "https://github.com/almartin82/caschooldata/blob/main/",
        "ASSESSMENT-EXPANSION-RESEARCH.md"
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
  if (use_cache && is.null(local_data)) {
    cache_type <- if (tidy) "assess_tidy" else "assess_wide"
    write_cache(result, end_year, cache_type)
  }

  result
}


#' Fetch CAASPP assessment data for multiple years
#'
#' Convenience function to download assessment data for multiple years at once.
#'
#' @param years Vector of school year ends (e.g., c(2019, 2020, 2021))
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
#' # Get 2019-2023 assessment data
#' assess_multi <- fetch_assess_multi(
#'   years = 2019:2023,
#'   tidy = TRUE
#' )
#'
#' # Calculate 5-year trend
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

  results <- purrr::map_df(years, function(y) {
    local_data <- if (!is.null(local_data_list) && y %in% names(local_data_list)) {
      local_data_list[[y]]
    } else {
      NULL
    }

    fetch_assess(
      end_year = y,
      tidy = tidy,
      subject = subject,
      student_group = student_group,
      local_data = local_data,
      use_cache = use_cache
    )
  })

  results
}


#' Get available CAASPP assessment years
#'
#' Returns a vector of years for which CAASPP assessment data is available.
#'
#' @return Named list with:
#'   \itemize{
#'     \item \code{min_year}: First available year (2015)
#'     \item \code{max_year}: Last available year (2024)
#'     \item \code{all_years}: All available years
#'     \item \code{note}: Special notes about data availability
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Check available assessment years
#' years <- get_available_assess_years()
#' print(years)
#'
#' # Fetch all available years
#' all_assess <- fetch_assess_multi(years$all_years)
#' }
get_available_assess_years <- function() {

  list(
    min_year = 2015,
    max_year = 2024,
    all_years = 2015:2024,
    note = "CAASPP assessments started in 2014-15 (end_year=2015). ",
           "2020 data may be limited due to COVID-19 disruptions."
  )
}
