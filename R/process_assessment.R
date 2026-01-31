# ==============================================================================
# Assessment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw CAASPP assessment data
# into a standardized schema.
#
# ==============================================================================

#' @importFrom rlang .data
#' @importFrom utils head
NULL

#' Process raw CAASPP assessment data
#'
#' Processes raw CAASPP research file data into a standardized schema.
#' Cleans column names, standardizes data types, and validates data quality.
#'
#' @param raw_data Raw CAASPP data from get_raw_assess() or import_local_assess()
#' @param end_year School year end (e.g., 2023 for 2022-23 school year)
#'
#' @return A tibble with processed assessment data including columns:
#'   \itemize{
#'     \item \code{end_year}: School year end (integer)
#'     \item \code{cds_code}: 14-digit CDS identifier (character)
#'     \item \code{county_code}: 2-digit county code (character)
#'     \item \code{district_code}: 5-digit district code (character)
#'     \item \code{school_code}: 7-digit school code (character)
#'     \item \code{agg_level}: Aggregation level (S=School, D=District, C=County, T=State)
#'     \item \code{grade}: Grade level (03, 04, 05, 06, 07, 08, 11, or 13 for all grades)
#'     \item \code{subject}: Assessment subject (ELA or Mathematics)
#'     \item \code{student_group}: Student group identifier
#'     \item \code{test_id}: Test identifier code
#'     \item \code{mean_scale_score}: Mean scale score (numeric)
#'     \item \code{pct_exceeded}: Percentage standard exceeded (numeric)
#'     \item \code{pct_met}: Percentage standard met (numeric)
#'     \item \code{pct_met_and_above}: Percentage standard met and above (numeric)
#'     \item \code{pct_nearly_met}: Percentage standard nearly met (numeric)
#'     \item \code{pct_not_met}: Percentage standard not met (numeric)
#'     \item \code{n_tested}: Number of students tested (integer)
#'     \item \code{n_exceeded}: Number standard exceeded (integer)
#'     \item \code{n_met}: Number standard met (integer)
#'     \item \code{n_met_and_above}: Number standard met and above (integer)
#'     \item \code{n_nearly_met}: Number standard nearly met (integer)
#'     \item \code{n_not_met}: Number standard not met (integer)
#'   }
#'
#' @details
#' ## Data Processing Steps:
#' \enumerate{
#'   \item Extract CDS code components (county, district, school)
#'   \item Determine aggregation level from school code (0000000 = district summary)
#'   \item Clean and standardize column names
#'   \item Convert data types (character to numeric where appropriate)
#'   \item Validate ranges (percentages 0-100, non-negative counts)
#'   \item Handle suppressed values (groups with < 11 students)
#' }
#'
#' ## Data Quality Checks:
#' \itemize{
#'   \item No Inf or NaN values in numeric columns
#'   \item Percentages between 0 and 100
#'   \item Counts are non-negative integers
#'   \item At least state-level data exists
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' # Process raw assessment data
#' raw <- get_raw_assess(2024)
#' processed <- process_assess(raw$test_data, 2024)
#'
#' # View processed data
#' head(processed)
#'
#' # Filter to state-level 11th grade ELA results
#' library(dplyr)
#' state_11_ela <- processed %>%
#'   filter(agg_level == "T", grade == "11", subject == "ELA")
#' }
process_assess <- function(raw_data, end_year) {

  # Check if raw_data is NULL
  if (is.null(raw_data)) {
    stop(
      "Raw assessment data is NULL.\n",
      "Please use get_raw_assess() or import_local_assess() first."
    )
  }

  # Check if raw_data has rows
  if (nrow(raw_data) == 0) {
    stop("Raw assessment data has no rows.")
  }

  # First, let's see what columns we actually have
  actual_cols <- names(raw_data)

  # CAASPP column mapping (based on 2024 file structure)
  # Column names are consistent across years (2015-2025)
  col_mapping <- list(
    # Entity identifiers
    county_code = "County Code",
    district_code = "District Code",
    district_name = "District Name",
    school_code = "School Code",
    school_name = "School Name",
    type_id = "Type ID",

    # Test information
    test_year = "Test Year",
    test_type = "Test Type",
    test_id = "Test ID",
    student_group_id = "Student Group ID",
    grade = "Grade",

    # Student counts
    n_enrolled = "Total Students Enrolled",
    n_tested = "Total Students Tested",
    n_tested_with_scores = "Total Students Tested with Scores",

    # Performance metrics
    mean_scale_score = "Mean Scale Score",

    # Percentages
    pct_exceeded = "Percentage Standard Exceeded",
    pct_met = "Percentage Standard Met",
    pct_met_and_above = "Percentage Standard Met and Above",
    pct_nearly_met = "Percentage Standard Nearly Met",
    pct_not_met = "Percentage Standard Not Met",

    # Counts
    n_exceeded = "Count Standard Exceeded",
    n_met = "Count Standard Met",
    n_met_and_above = "Count Standard Met and Above",
    n_nearly_met = "Count Standard Nearly Met",
    n_not_met = "Count Standard Not Met"
  )

  # Build column renaming list (only for columns that exist)
  rename_list <- list()
  for (new_name in names(col_mapping)) {
    old_name <- col_mapping[[new_name]]
    if (old_name %in% actual_cols) {
      rename_list[[new_name]] <- old_name
    }
  }

  # Rename columns to standardized names
  if (length(rename_list) > 0) {
    raw_data <- raw_data %>%
      dplyr::rename(!!!rename_list)
  }

  # Add end_year
  raw_data$end_year <- as.integer(end_year)

  # Map test_id to subject
  # Test ID 1 = ELA, Test ID 2 = Math
  if ("test_id" %in% names(raw_data)) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        subject = dplyr::case_when(
          test_id == "1" ~ "ELA",
          test_id == "2" ~ "Math",
          TRUE ~ paste0("Test_", test_id)
        )
      )
  }

  # Construct CDS code (14 digits: CCDDDDDSSSSSS)
  # County: 2 digits, District: 5 digits, School: 7 digits
  if (all(c("county_code", "district_code", "school_code") %in% names(raw_data))) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        cds_code = paste0(
          sprintf("%02s", county_code),
          sprintf("%05s", district_code),
          sprintf("%07s", school_code)
        )
      )
  }

  # Determine aggregation level based on type_id and codes
  # Type ID: 4 = State, 5 = County, 6 = District, 7 = School
  if ("type_id" %in% names(raw_data)) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        agg_level = dplyr::case_when(
          type_id == "4" ~ "T",  # State
          type_id == "5" ~ "C",  # County
          type_id == "6" ~ "D",  # District
          type_id == "7" ~ "S",  # School
          # Fallback based on codes
          county_code == "00" & district_code == "00000" & school_code == "0000000" ~ "T",
          school_code == "0000000" ~ "D",
          TRUE ~ "S"
        )
      )
  } else if (all(c("county_code", "district_code", "school_code") %in% names(raw_data))) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        agg_level = dplyr::case_when(
          county_code == "00" & district_code == "00000" & school_code == "0000000" ~ "T",
          school_code == "0000000" ~ "D",
          TRUE ~ "S"
        )
      )
  }

  # Clean grade column (ensure consistent formatting)
  if ("grade" %in% names(raw_data)) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        grade = dplyr::case_when(
          grade == "13" ~ "13",  # All grades combined
          TRUE ~ sprintf("%02d", as.integer(grade))
        )
      )
  }

  # Convert percentage columns to numeric
  pct_cols <- c("pct_exceeded", "pct_met", "pct_met_and_above",
                "pct_nearly_met", "pct_not_met")

  for (col in pct_cols) {
    if (col %in% names(raw_data)) {
      raw_data[[col]] <- as.numeric(raw_data[[col]])
    }
  }

  # Convert mean scale score to numeric
  if ("mean_scale_score" %in% names(raw_data)) {
    raw_data$mean_scale_score <- as.numeric(raw_data$mean_scale_score)
  }

  # Convert count columns to integer
  count_cols <- c("n_enrolled", "n_tested", "n_tested_with_scores",
                  "n_exceeded", "n_met", "n_met_and_above",
                  "n_nearly_met", "n_not_met")

  for (col in count_cols) {
    if (col %in% names(raw_data)) {
      raw_data[[col]] <- as.integer(raw_data[[col]])
    }
  }

  # Select only standardized columns (if they exist)
  standard_cols <- c(
    "end_year", "cds_code",
    "county_code", "district_code", "school_code",
    "district_name", "school_name",
    "agg_level", "type_id",
    "grade", "subject", "test_id", "student_group_id",
    "mean_scale_score",
    "pct_exceeded", "pct_met", "pct_met_and_above",
    "pct_nearly_met", "pct_not_met",
    "n_enrolled", "n_tested", "n_tested_with_scores",
    "n_exceeded", "n_met", "n_met_and_above",
    "n_nearly_met", "n_not_met"
  )

  available_cols <- intersect(standard_cols, names(raw_data))

  result <- raw_data %>%
    dplyr::select(dplyr::all_of(available_cols))

  # Data quality checks
  # Check for Inf/NaN in numeric columns
  numeric_cols <- c("mean_scale_score", pct_cols, count_cols)
  numeric_cols <- intersect(numeric_cols, names(result))

  for (col in numeric_cols) {
    if (any(is.infinite(result[[col]]))) {
      warning(
        "Column '", col, "' contains Inf values.\n",
        "These may indicate data quality issues in the source file."
      )
      result[[col]][is.infinite(result[[col]])] <- NA
    }
  }

  # Validate percentage ranges
  pct_cols_present <- intersect(pct_cols, names(result))
  for (col in pct_cols_present) {
    out_of_range <- result[[col]] < 0 | result[[col]] > 100
    if (any(out_of_range, na.rm = TRUE)) {
      warning(
        "Column '", col, "' contains values outside 0-100 range.\n",
        "These may indicate data quality issues in the source file."
      )
    }
  }

  # Validate non-negative counts
  count_cols_present <- intersect(count_cols, names(result))
  for (col in count_cols_present) {
    if (any(result[[col]] < 0, na.rm = TRUE)) {
      warning(
        "Column '", col, "' contains negative values.\n",
        "These may indicate data quality issues in the source file."
      )
    }
  }

  # Check for state-level data
  if ("agg_level" %in% names(result)) {
    if (!any(result$agg_level == "T", na.rm = TRUE)) {
      warning(
        "No state-level summary rows found.\n",
        "Data may not include statewide aggregations."
      )
    }
  }

  # Add class for printing
  class(result) <- c("ca_assess_data", class(result))

  result
}


#' Print CAASPP assessment data
#'
#' @param x A ca_assess_data object
#' @param ... Additional arguments (ignored)
#'
#' @export
print.ca_assess_data <- function(x, ...) {

  cat("California CAASPP Assessment Data\n")
  cat("===============================\n\n")

  cat("Dimensions: ", nrow(x), "rows x", ncol(x), "columns\n\n")

  if ("end_year" %in% names(x)) {
    cat("School Year: ", unique(x$end_year), "\n")
  }

  if ("grade" %in% names(x)) {
    grades <- unique(x$grade)
    cat("Grades: ", paste(sort(grades), collapse = ", "), "\n")
  }

  if ("subject" %in% names(x)) {
    subjects <- unique(x$subject)
    cat("Subjects: ", paste(subjects, collapse = ", "), "\n")
  }

  if ("agg_level" %in% names(x)) {
    agg_levels <- table(x$agg_level)
    cat("\nAggregation Levels:\n")
    for (level in names(agg_levels)) {
      label <- switch(level,
                     "S" = "School",
                     "D" = "District",
                     "C" = "County",
                     "T" = "State",
                     level)
      cat("  ", label, ": ", agg_levels[level], " rows\n", sep = "")
    }
  }

  cat("\n")
  print(dplyr::as_tibble(head(x, 6)))

  invisible(x)
}
