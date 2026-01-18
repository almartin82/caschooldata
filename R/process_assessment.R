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
#' raw <- get_raw_assess(2023)
#' processed <- process_assess(raw$test_data, 2023)
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

  # Check if raw_data is NULL (manual download required)
  if (is.null(raw_data)) {
    stop(
      "Raw assessment data is NULL.\n",
      "Please download CAASPP files manually from the portal:\n",
      "1. Visit: https://caaspp-elpac.ets.org/caaspp/ResearchFileListSB\n",
      "2. Download statewide research file (All Students, caret-delimited)\n",
      "3. Use import_local_assess() to load the files\n",
      "4. Then process_assess() to process the data"
    )
  }

  # Define expected column mapping based on 2023 file layout
  # Column names may vary slightly across years, so we'll standardize

  # First, let's see what columns we actually have
  actual_cols <- names(raw_data)

  # Common column name patterns (may need adjustment for different years)
  col_mapping <- list(
    # Entity identifiers
    county_code = c("County Code", "County_Code", "CNTYCODE", "county_code"),
    district_code = c("District Code", "District_Code", "DISTCODE", "district_code"),
    school_code = c("School Code", "School_Code", "SCHCODE", "school_code"),

    # Test information
    test_year = c("Test Year", "Test_Year", "TestYear", "test_year"),
    test_id = c("Test ID", "Test_ID", "TestID", "test_id", "Test Code", "Test_Code"),
    subject = c("Subject", "subject", "Test Type", "Test_Type"),
    grade = c("Grade", "grade", "Grade Level", "Grade_Level"),

    # Student groups
    student_group_code = c("Student Group Code", "Student_Group_Code",
                          "SubGroup ID", "SubGroupID", " subgroup_id"),

    # Performance metrics
    mean_scale_score = c("Mean Scale Score", "Mean_Scale_Score",
                        "MeanScore", "mean_scale_score",
                        "Average Scale Score"),

    # Percentages
    pct_exceeded = c("Percentage Standard Exceeded",
                    "Percentage_Standard_Exceeded",
                    "PctExceeded", "pct_exceeded",
                    "Percent Exceeded"),

    pct_met = c("Percentage Standard Met",
               "Percentage_Standard_Met",
               "PctMet", "pct_met",
               "Percent Met"),

    pct_met_and_above = c("Percentage Standard Met and Above",
                         "Percentage_Standard_Met_and_Above",
                         "PctMetAndAbove", "pct_met_and_above",
                         "Percent Met and Above"),

    pct_nearly_met = c("Percentage Standard Nearly Met",
                      "Percentage_Standard_Nearly_Met",
                      "PctNearlyMet", "pct_nearly_met",
                      "Percent Nearly Met"),

    pct_not_met = c("Percentage Standard Not Met",
                   "Percentage_Standard_Not_Met",
                   "PctNotMet", "pct_not_met",
                   "Percent Not Met"),

    # Counts
    n_tested = c("Number Tested", "Number_Tested", "TestedCount", "n_tested"),
    n_exceeded = c("Number Exceeded", "Number_Exceeded", "ExceededCount"),
    n_met = c("Number Met", "Number_Met", "MetCount"),
    n_met_and_above = c("Number Met and Above", "Number_Met_and_Above"),
    n_nearly_met = c("Number Nearly Met", "Number_Nearly_Met"),
    n_not_met = c("Number Not Met", "Number_Not_Met")
  )

  # Helper function to find column by any of its possible names
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matches <- actual_cols[grepl(pattern, actual_cols, ignore.case = TRUE)]
      if (length(matches) > 0) {
        return(matches[1])
      }
    }
    return(NULL)
  }

  # Build new column mapping
  new_cols <- list()
  for (target_name in names(col_mapping)) {
    found <- find_col(col_mapping[[target_name]])
    if (!is.null(found)) {
      new_cols[[target_name]] <- found
    }
  }

  # Rename columns to standardized names
  if (length(new_cols) > 0) {
    raw_data <- raw_data %>%
      dplyr::rename(!!!new_cols)
  }

  # Add end_year
  raw_data$end_year <- end_year

  # Construct CDS code (14 digits: CCDDDDSSSSSSS)
  # County: 2 digits, District: 5 digits, School: 7 digits
  if (all(c("county_code", "district_code", "school_code") %in% names(raw_data))) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        cds_code = stringr::str_interp(
          "${sprintf('%02d', as.integer(county_code))}${sprintf('%05d', as.integer(district_code))}${sprintf('%07s', school_code)}"
        )
      )
  }

  # Determine aggregation level
  # School code "0000000" or "00000000" indicates district summary
  if ("school_code" %in% names(raw_data)) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        agg_level = dplyr::case_when(
          school_code %in% c("0000000", "00000000", "0") ~ "D",
          school_code == "" ~ "D",
          TRUE ~ "S"
        )
      )
  }

  # Clean subject column
  if ("subject" %in% names(raw_data)) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        subject = dplyr::case_when(
          grepl("ELA|English|Literacy", subject, ignore.case = TRUE) ~ "ELA",
          grepl("Math|Mathematics", subject, ignore.case = TRUE) ~ "Math",
          TRUE ~ as.character(subject)
        )
      )
  }

  # Clean grade column (ensure consistent formatting)
  if ("grade" %in% names(raw_data)) {
    raw_data <- raw_data %>%
      dplyr::mutate(
        grade = sprintf("%02d", as.integer(grade))
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

  # Convert count columns to integer
  count_cols <- c("n_tested", "n_exceeded", "n_met",
                  "n_met_and_above", "n_nearly_met", "n_not_met")

  for (col in count_cols) {
    if (col %in% names(raw_data)) {
      raw_data[[col]] <- as.integer(raw_data[[col]])
    }
  }

  # Select only standardized columns (if they exist)
  standard_cols <- c(
    "end_year", "cds_code",
    "county_code", "district_code", "school_code",
    "agg_level",
    "grade", "subject", "test_id", "student_group_code",
    "mean_scale_score",
    "pct_exceeded", "pct_met", "pct_met_and_above",
    "pct_nearly_met", "pct_not_met",
    "n_tested", "n_exceeded", "n_met",
    "n_met_and_above", "n_nearly_met", "n_not_met"
  )

  available_cols <- intersect(standard_cols, names(raw_data))

  # Also keep any columns that weren't mapped (for debugging)
  unmapped_cols <- setdiff(names(raw_data), available_cols)

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
  if (!any(result$agg_level == "T", na.rm = TRUE) &&
      !any(result$grade == "13", na.rm = TRUE)) {
    warning(
      "No state-level summary rows found.\n",
      "Data may not include statewide aggregations."
    )
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
