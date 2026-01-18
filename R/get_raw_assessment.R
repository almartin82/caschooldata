# ==============================================================================
# Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading California CAASPP assessment
# data from the CAASPP/ELPAC Research Files Portal.
#
# ==============================================================================

#' Get raw CAASPP assessment data
#'
#' Downloads raw CAASPP Smarter Balanced assessment research files from the
#' ETS CAASPP portal. Data includes test results for grades 3-8 and 11 in
#' ELA and Mathematics.
#'
#' @param end_year School year end (e.g., 2023 for 2022-23 school year).
#'   Supports 2015-2024.
#' @param subject Assessment subject: "ELA", "Math", or "Both" (default).
#' @param student_group "ALL" (default) for all students, or "GROUPS" for all
#'   student group breakdowns.
#'
#' @return List containing:
#'   \itemize{
#'     \item \code{test_data}: Data frame with assessment results
#'     \item \code{entities}: Data frame with entity names and codes
#'     \item \code{year}: School year
#'     \item \code{source_url}: URL where data was downloaded
#'   }
#'
#' @details
#' ## Available Years:
#' \itemize{
#'   \item 2015-2019: Pre-COVID baseline data
#'   \item 2020: Assessment year (COVID-19 disruptions)
#'   \item 2021: Limited data due to pandemic
#'   \item 2022-2024: Full post-pandemic data
#' }
#'
#' ## File Format:
#' Statewide research files in caret-delimited format. Files include:
#' \itemize{
#'   \item All counties, districts, and schools
#'   \item Grade-level aggregations (3, 4, 5, 6, 7, 8, 11)
#'   \item Performance levels (Exceeded, Met, Nearly Met, Not Met)
#'   \item Mean scale scores
#'   \item Student group breakdowns (if student_group = "GROUPS")
#' }
#'
#' ## Data Source:
#' CAASPP Research Files Portal (ETS):
#' https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB
#'
#' @seealso
#' \code{\link{process_assess}} for processing raw data
#' \code{\link{fetch_assess}} for the complete fetch pipeline
#'
#' @export
#' @examples
#' \dontrun{
#' # Download 2023 CAASPP data (both ELA and Math)
#' raw_2023 <- get_raw_assess(2023)
#'
#' # Download only ELA results
#' raw_2023_ela <- get_raw_assess(2023, subject = "ELA")
#'
#' # Download with student group breakdowns
#' raw_2023_groups <- get_raw_assess(2023, student_group = "GROUPS")
#'
#' # Access test results and entity names
#' test_data <- raw_2023$test_data
#' entities <- raw_2023$entities
#' }
get_raw_assess <- function(end_year,
                           subject = c("Both", "ELA", "Math"),
                           student_group = c("ALL", "GROUPS")) {

  subject <- match.arg(subject)
  student_group <- match.arg(student_group)

  # Validate year
  available_years <- 2015:2024
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between 2015 and 2024.\n",
      "Note: CAASPP assessments started in 2014-15 (end_year=2015).\n",
      "2020 data may be limited due to COVID-19 disruptions."
    ))
  }

  # Map end_year to CAASPP test year
  # end_year 2023 = 2022-23 school year = test year 2023
  test_year <- end_year

  # Build base URL for research files portal
  base_url <- "https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB"
  portal_url <- paste0(
    base_url,
    "?ps=true&lstTestYear=", test_year,
    "&lstTestType=B",  # B = Smarter Balanced
    "&lstCounty=00",   # 00 = statewide
    "&lstDistrict=00000"  # 00000 = all districts
  )

  # NOTE: The CAASPP portal uses JavaScript to generate download links,
  # making direct URL discovery challenging. This function provides
  # documentation and the manual download workflow.
  #
  # For automated downloads, we use import_local_*() fallback or
  # implement URL pattern discovery.

  message(paste0(
    "\n",
    "CAASPP Assessment Data Download\n",
    "==============================\n",
    "Year: ", end_year, " (", end_year-1, "-", end_year, " school year)\n",
    "Subject: ", subject, "\n",
    "Student Groups: ", student_group, "\n\n",
    "DATA SOURCE: CAASPP Research Files Portal (ETS)\n",
    "Portal URL: ", portal_url, "\n\n",
    "MANUAL DOWNLOAD INSTRUCTIONS:\n",
    "1. Visit the portal URL above\n",
    "2. Under 'Statewide Files', download:\n",
    "   - 'California Statewide research file, All Students, caret-delimited'\n",
    "3. Under 'Entity Files', download:\n",
    "   - Entity file for ", test_year, "\n",
    "4. Save both files to a local directory\n\n",
    "AUTOMATED DOWNLOAD:\n",
    "Direct URL patterns are not publicly documented.\n",
    "Use import_local_assess() to load manually downloaded files.\n\n",
    "For more information, see:\n",
    "https://github.com/almartin82/caschooldata/blob/main/",
    "ASSESSMENT-EXPANSION-RESEARCH.md\n"
  ))

  # Attempt to construct download URLs based on observed patterns
  # These patterns may change and should be verified

  # File naming pattern (hypothetical, needs verification):
  # sb_ca_{test_year}_allstudents_csv.txt
  # entities_{test_year}.txt

  file_pattern <- list(
    test_data = paste0("sb_ca_", test_year, "_allstudents_csv"),
    entities = paste0("entities_", test_year)
  )

  # Return metadata (actual download requires manual intervention
  # or URL pattern verification)
  result <- list(
    test_data = NULL,
    entities = NULL,
    year = end_year,
    test_year = test_year,
    subject = subject,
    student_group = student_group,
    portal_url = portal_url,
    file_pattern = file_pattern,
    status = "manual_download_required"
  )

  result
}


#' Import locally downloaded CAASPP assessment files
#'
#' Imports CAASPP research files that have been manually downloaded from the
#' CAASPP portal. Use this function when automated downloads are not available.
#'
#' @param test_data_path Path to the caret-delimited test data file
#' @param entities_path Path to the entities file
#' @param end_year School year end (for metadata)
#'
#' @return List containing parsed test_data and entities data frames
#'
#' @export
#' @examples
#' \dontrun{
#' # Import manually downloaded files
#' local_data <- import_local_assess(
#'   test_data_path = "~/Downloads/sb_ca_2023_allstudents_csv.txt",
#'   entities_path = "~/Downloads/entities_2023.txt",
#'   end_year = 2023
#' )
#'
#' test_data <- local_data$test_data
#' entities <- local_data$entities
#' }
import_local_assess <- function(test_data_path,
                                 entities_path,
                                 end_year) {

  if (!file.exists(test_data_path)) {
    stop("Test data file not found: ", test_data_path)
  }

  if (!file.exists(entities_path)) {
    stop("Entities file not found: ", entities_path)
  }

  message("Reading test data from: ", test_data_path)
  test_data <- readr::read_delim(
    test_data_path,
    delim = "|",  # Caret-delimited
    na = c("", "*", "N/A", "*"),
    show_col_types = FALSE
  )

  message("Reading entities from: ", entities_path)
  entities <- readr::read_delim(
    entities_path,
    delim = "|",
    show_col_types = FALSE
  )

  # Add metadata
  result <- list(
    test_data = test_data,
    entities = entities,
    year = end_year,
    source = "local_file"
  )

  message("\nImport successful:")
  message("  - Test data: ", nrow(test_data), " rows, ", ncol(test_data), " cols")
  message("  - Entities: ", nrow(entities), " rows, ", ncol(entities), " cols")

  result
}


#' Download CAASPP research file (direct URL attempt)
#'
#' Attempts to download a CAASPP research file using a constructed URL.
#' This is an internal helper function that may fail if URL patterns change.
#'
#' @param url Direct download URL
#' @param destfile Destination file path
#' @param quiet If TRUE, suppress download progress messages
#'
#' @return Invisible TRUE if successful, stops with error if failed
#'
#' @keywords internal
download_caaspp_file <- function(url, destfile, quiet = FALSE) {

  # Check if URL is accessible
  response <- httr::HEAD(url)

  if (httr::http_error(response)) {
    stop(
      "Unable to download from URL: ", url, "\n",
      "Status: ", httr::status_code(response), "\n\n",
      "The URL may be incorrect or require authentication.\n",
      "Please download manually from the CAASPP portal."
    )
  }

  # Download file
  utils::download.file(url, destfile = destfile, quiet = quiet, mode = "wb")

  invisible(TRUE)
}
