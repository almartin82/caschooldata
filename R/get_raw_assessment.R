# ==============================================================================
# Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading California CAASPP assessment
# data from the CAASPP/ELPAC Research Files Portal.
#
# ==============================================================================

#' @importFrom utils unzip
NULL

#' Get URL version suffix for a given year
#'
#' The CAASPP portal uses different version suffixes for different years.
#' This function returns the correct version for each year.
#'
#' @param end_year School year end
#' @return Version suffix string (e.g., "v1", "v2", "v3", "v4")
#' @keywords internal
get_caaspp_version <- function(end_year) {
  # Version mapping based on actual portal URLs (as of January 2026)
  version_map <- c(
    "2015" = "v3",
    "2016" = "v3",
    "2017" = "v2",
    "2018" = "v3",
    "2019" = "v4",
    "2020" = "v1",  # Limited data due to COVID
    "2021" = "v2",
    "2022" = "v1",
    "2023" = "v1",
    "2024" = "v1",
    "2025" = "v1"
  )
  unname(version_map[as.character(end_year)])
}


#' Build CAASPP research file URL
#'
#' Constructs the direct download URL for CAASPP research files.
#'
#' @param end_year School year end
#' @param file_type One of "1" (All Students), "all" (All Student Groups),
#'   "all_ela" (All Groups ELA only), "all_math" (All Groups Math only)
#' @param format One of "csv" (caret-delimited) or "ascii" (fixed-width)
#' @return URL string
#' @keywords internal
build_caaspp_url <- function(end_year,
                             file_type = c("1", "all", "all_ela", "all_math"),
                             format = c("csv", "ascii")) {
  file_type <- match.arg(file_type)
  format <- match.arg(format)

  version <- get_caaspp_version(end_year)
  base_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles"

  # Build file name based on file type
  if (file_type == "1") {
    filename <- sprintf("sb_ca%d_1_%s_%s.zip", end_year, format, version)
  } else if (file_type == "all") {
    filename <- sprintf("sb_ca%d_all_%s_%s.zip", end_year, format, version)
  } else if (file_type == "all_ela") {
    filename <- sprintf("sb_ca%d_all_%s_ela_%s.zip", end_year, format, version)
  } else {  # all_math
    filename <- sprintf("sb_ca%d_all_%s_math_%s.zip", end_year, format, version)
  }

  paste0(base_url, "/", filename)
}


#' Build CAASPP entities file URL
#'
#' @param end_year School year end
#' @param format One of "csv" or "ascii"
#' @return URL string
#' @keywords internal
build_entities_url <- function(end_year, format = c("csv", "ascii")) {
  format <- match.arg(format)
  base_url <- "https://caaspp-elpac.ets.org/caaspp/researchfiles"
  filename <- sprintf("sb_ca%dentities_%s.zip", end_year, format)
  paste0(base_url, "/", filename)
}


#' Get raw CAASPP assessment data
#'
#' Downloads raw CAASPP Smarter Balanced assessment research files from the
#' ETS CAASPP portal. Data includes test results for grades 3-8 and 11 in
#' ELA and Mathematics.
#'
#' @param end_year School year end (e.g., 2023 for 2022-23 school year).
#'   Supports 2015-2025.
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
#'   \item 2020: No statewide testing (COVID-19)
#'   \item 2021: Limited data due to pandemic
#'   \item 2022-2025: Full post-pandemic data
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
#' # Download 2024 CAASPP data (both ELA and Math)
#' raw_2024 <- get_raw_assess(2024)
#'
#' # Download only ELA results
#' raw_2024_ela <- get_raw_assess(2024, subject = "ELA")
#'
#' # Download with student group breakdowns
#' raw_2024_groups <- get_raw_assess(2024, student_group = "GROUPS")
#'
#' # Access test results and entity names
#' test_data <- raw_2024$test_data
#' entities <- raw_2024$entities
#' }
get_raw_assess <- function(end_year,
                           subject = c("Both", "ELA", "Math"),
                           student_group = c("ALL", "GROUPS")) {

  subject <- match.arg(subject)
  student_group <- match.arg(student_group)

  # Validate year
  available_years <- get_available_assess_years()$all_years
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be one of: ", paste(available_years, collapse = ", "), ".\n",
      "Note: CAASPP assessments started in 2014-15 (end_year=2015).\n",
      "2020 had no statewide testing due to COVID-19."
    ))
  }

  # Special handling for 2020 (COVID year)
  if (end_year == 2020) {
    stop(
      "2020 CAASPP data is not available.\n",
      "California did not administer statewide assessments in Spring 2020 ",
      "due to the COVID-19 pandemic.\n",
      "Use 2019 for pre-pandemic or 2021+ for post-pandemic data."
    )
  }

  # Determine file type based on parameters
  if (student_group == "ALL") {
    file_type <- "1"  # All Students combined file
  } else if (subject == "ELA") {
    file_type <- "all_ela"
  } else if (subject == "Math") {
    file_type <- "all_math"
  } else {
    file_type <- "all"  # All student groups, both subjects
  }

  # Build URLs
  data_url <- build_caaspp_url(end_year, file_type = file_type, format = "csv")
  entities_url <- build_entities_url(end_year, format = "csv")

  message(paste0(
    "Downloading CAASPP ", end_year, " assessment data...\n",
    "  Subject: ", subject, "\n",
    "  Student Groups: ", student_group
  ))

  # Create temp directory
  temp_dir <- tempdir()

  # Download and extract data file
  data_zip <- file.path(temp_dir, paste0("caaspp_data_", end_year, ".zip"))
  entities_zip <- file.path(temp_dir, paste0("caaspp_entities_", end_year, ".zip"))

  tryCatch({
    # Download data file
    message("  Downloading test data...")
    utils::download.file(data_url, data_zip, mode = "wb", quiet = TRUE)

    # Download entities file
    message("  Downloading entities...")
    utils::download.file(entities_url, entities_zip, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    stop(
      "Failed to download CAASPP files.\n",
      "Error: ", e$message, "\n",
      "Data URL: ", data_url, "\n",
      "Entities URL: ", entities_url, "\n\n",
      "If URLs have changed, visit the CAASPP portal manually:\n",
      "https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB"
    )
  })

  # Extract and read data file
  message("  Extracting and parsing...")
  unzip(data_zip, exdir = temp_dir)
  unzip(entities_zip, exdir = temp_dir)

  # Find the extracted text files
  data_files <- list.files(temp_dir, pattern = sprintf("sb_ca%d.*csv.*\\.txt$", end_year),
                          full.names = TRUE)
  entity_files <- list.files(temp_dir, pattern = sprintf("sb_ca%dentities.*\\.txt$", end_year),
                            full.names = TRUE)

  if (length(data_files) == 0) {
    stop("Could not find extracted data file in temp directory")
  }
  if (length(entity_files) == 0) {
    stop("Could not find extracted entities file in temp directory")
  }

  # Read the caret-delimited files
  test_data <- readr::read_delim(
    data_files[1],
    delim = "^",
    col_types = readr::cols(.default = "c"),
    na = c("", "*", "N/A"),
    show_col_types = FALSE
  )

  entities <- readr::read_delim(
    entity_files[1],
    delim = "^",
    col_types = readr::cols(.default = "c"),
    show_col_types = FALSE
  )

  message(paste0(
    "  Downloaded: ", nrow(test_data), " assessment records, ",
    nrow(entities), " entities"
  ))

  # Clean up temp files
  unlink(data_zip)
  unlink(entities_zip)
  unlink(data_files)
  unlink(entity_files)

  # Return result
  result <- list(
    test_data = test_data,
    entities = entities,
    year = end_year,
    source_url = data_url,
    entities_url = entities_url,
    subject = subject,
    student_group = student_group,
    status = "success"
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
#'   test_data_path = "~/Downloads/sb_ca2024_1_csv_v1.txt",
#'   entities_path = "~/Downloads/sb_ca2024entities_csv.txt",
#'   end_year = 2024
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
    delim = "^",  # Caret-delimited (^)
    col_types = readr::cols(.default = "c"),
    na = c("", "*", "N/A"),
    show_col_types = FALSE
  )

  message("Reading entities from: ", entities_path)
  entities <- readr::read_delim(
    entities_path,
    delim = "^",  # Caret-delimited (^)
    col_types = readr::cols(.default = "c"),
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


#' Check if CAASPP URL is accessible
#'
#' Tests if a CAASPP research file URL is accessible.
#'
#' @param url URL to test
#' @return TRUE if accessible, FALSE otherwise
#' @keywords internal
check_caaspp_url <- function(url) {
  tryCatch({
    response <- httr::HEAD(url, httr::timeout(10))
    httr::status_code(response) == 200
  }, error = function(e) {
    FALSE
  })
}


#' Get available CAASPP assessment years
#'
#' Returns a vector of years for which CAASPP assessment data is available.
#'
#' @return Named list with:
#'   \itemize{
#'     \item \code{min_year}: First available year (2015)
#'     \item \code{max_year}: Last available year (2025)
#'     \item \code{all_years}: All available years (excluding 2020)
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
  # All years with CAASPP data (excluding 2020 - COVID)
  all_years <- c(2015:2019, 2021:2025)

  list(
    min_year = 2015,
    max_year = 2025,
    all_years = all_years,
    covid_year = 2020,
    note = paste(
      "CAASPP assessments started in 2014-15 (end_year=2015).",
      "2020 had no statewide testing due to COVID-19.",
      "2021 data has limited participation due to pandemic."
    )
  )
}
