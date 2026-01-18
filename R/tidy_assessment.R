# ==============================================================================
# Assessment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for converting processed CAASPP assessment data
# into tidy (long) format for easier analysis.
#
# ==============================================================================

#' @importFrom rlang .data
#' @importFrom utils head
NULL

#' Tidy CAASPP assessment data
#'
#' Converts processed CAASPP assessment data from wide format to tidy (long)
#' format. Pivots performance metrics into separate rows for easier analysis.
#'
#' @param processed_data Processed assessment data from process_assess()
#'
#' @return A tibble in tidy format with columns:
#'   \itemize{
#'     \item \code{end_year}: School year end
#'     \item \code{cds_code}: 14-digit CDS identifier
#'     \item \code{county_code}, \code{district_code}, \code{school_code}: CDS components
#'     \item \code{agg_level}: Aggregation level (S/D/C/T)
#'     \item \code{grade}: Grade level (03-11 or 13)
#'     \item \code{subject}: Assessment subject (ELA/Math)
#'     \item \code{metric_type}: Type of metric (mean_scale_score, pct_exceeded, etc.)
#'     \item \code{metric_value}: Value of the metric
#'   }
#'
#' @details
#' ## Tidy Format Structure:
#'
#' The tidy format converts performance metrics from separate columns into
#' rows, making it easier to:
#' \itemize{
#'   \item Filter and plot by metric type
#'   \item Compare metrics across years
#'   \item Calculate differences between metrics
#'   \item Join with other datasets
#' }
#'
#' ## Metric Types:
#' \itemize{
#'   \item \code{mean_scale_score}: Average scale score for the test
#'   \item \code{pct_exceeded}: Percentage of students who exceeded standard
#'   \item \code{pct_met}: Percentage of students who met standard
#'   \item \code{pct_met_and_above}: Percentage who met or exceeded standard
#'   \item \code{pct_nearly_met}: Percentage who nearly met standard
#'   \item \code{pct_not_met}: Percentage who did not meet standard
#'   \item \code{n_tested}: Number of students tested
#'   \item \code{n_exceeded}: Number of students who exceeded standard
#'   \item \code{n_met}: Number of students who met standard
#'   \item \code{n_met_and_above}: Number who met or exceeded standard
#'   \item \code{n_nearly_met}: Number of students who nearly met standard
#'   \item \code{n_not_met}: Number of students who did not meet standard
#' }
#'
#' @export
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Process and tidy assessment data
#' raw <- get_raw_assess(2023)
#' processed <- process_assess(raw$test_data, 2023)
#' tidy <- tidy_assess(processed)
#'
#' # Filter to state-level proficiency rates
#' state_proficiency <- tidy %>%
#'   filter(agg_level == "T",
#'          metric_type %in% c("pct_met_and_above", "pct_exceeded"))
#'
#' # Compare ELA vs Math performance
#' subject_comparison <- tidy %>%
#'   filter(agg_level == "T",
#'          grade == "11",
#'          metric_type == "pct_met_and_above") %>%
#'   select(grade, subject, metric_value)
#' }
tidy_assess <- function(processed_data) {

  # Identify identifier columns (not metrics)
  id_cols <- c(
    "end_year", "cds_code",
    "county_code", "district_code", "school_code",
    "agg_level", "grade", "subject", "test_id", "student_group_code"
  )

  # Identify metric columns
  metric_cols <- c(
    "mean_scale_score",
    "pct_exceeded", "pct_met", "pct_met_and_above",
    "pct_nearly_met", "pct_not_met",
    "n_tested", "n_exceeded", "n_met",
    "n_met_and_above", "n_nearly_met", "n_not_met"
  )

  # Use only columns that exist
  id_cols_present <- intersect(id_cols, names(processed_data))
  metric_cols_present <- intersect(metric_cols, names(processed_data))

  # Pivot longer to convert metric columns to rows
  tidy_data <- processed_data %>%
    tidyr::pivot_longer(
      cols = dplyr::all_of(metric_cols_present),
      names_to = "metric_type",
      values_to = "metric_value",
      values_drop_na = FALSE
    )

  # Reorder columns for easier viewing
  tidy_data <- tidy_data %>%
    dplyr::select(dplyr::all_of(
      c(id_cols_present, "metric_type", "metric_value")
    ))

  # Add class for printing
  class(tidy_data) <- c("ca_assess_tidy", class(tidy_data))

  tidy_data
}


#' Identify assessment aggregations
#'
#' Adds aggregation identifier columns to assessment data.
#' Creates is_state, is_county, is_district, is_school logical columns.
#'
#' @param data Assessment data (processed or tidy format)
#'
#' @return Data with additional aggregation identifier columns
#'
#' @details
#' Creates logical columns for easy filtering:
#' \itemize{
#'   \item \code{is_state}: TRUE for state-level aggregations
#'   \item \code{is_county}: TRUE for county-level aggregations
#'   \item \code{is_district}: TRUE for district-level aggregations
#'   \item \code{is_school}: TRUE for school-level aggregations
#' }
#'
#' Also creates \code{entity_name} column based on aggregation level.
#'
#' @export
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Add aggregation identifiers
#' tidy <- tidy_assess(processed_data) %>%
#'   id_assess_aggs()
#'
#' # Filter to school-level data
#' schools <- tidy %>%
#'   filter(is_school)
#'
#' # Filter to state-level data
#' state <- tidy %>%
#'   filter(is_state)
#' }
id_assess_aggs <- function(data) {

  if (!"agg_level" %in% names(data)) {
    stop("Data must include 'agg_level' column")
  }

  # Create aggregation identifier columns
  data <- data %>%
    dplyr::mutate(
      is_state = agg_level == "T",
      is_county = agg_level == "C",
      is_district = agg_level == "D",
      is_school = agg_level == "S"
    )

  data
}


#' Calculate assessment proficiency summary
#'
#' Creates a summary table of proficiency metrics for easy comparison.
#'
#' @param data Tidy assessment data
#' @param metric Performance metric to summarize (default: "pct_met_and_above")
#'
#' @return Summary tibble with proficiency rates by entity, grade, and subject
#'
#' @export
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Summarize state proficiency rates
#' tidy <- tidy_assess(processed_data) %>%
#'   id_assess_aggs()
#'
#' state_summary <- summarize_proficiency(tidy, "pct_met_and_above") %>%
#'   filter(is_state)
#'
#' # Compare 11th grade ELA vs Math
#' comparison <- tidy %>%
#'   filter(grade == "11",
#'          agg_level == "T") %>%
#'   summarize_proficiency("pct_met_and_above") %>%
#'   select(grade, subject, metric_value)
#' }
summarize_proficiency <- function(data, metric = "pct_met_and_above") {

  if (!"metric_type" %in% names(data)) {
    stop("Data must be in tidy format (use tidy_assess() first)")
  }

  # Filter to requested metric
  result <- data %>%
    dplyr::filter(metric_type == metric) %>%
    dplyr::select(-metric_type)

  result
}


#' Calculate assessment trends over time
#'
#' Computes year-over-year changes in assessment metrics.
#'
#' @param data Tidy assessment data with multiple years
#' @param metric Performance metric to analyze (default: "pct_met_and_above")
#'
#' @return Data with additional columns for year-over-year changes
#'
#' @export
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Calculate 5-year trend
#' multi_year <- fetch_assess_multi(2019:2023, tidy = TRUE) %>%
#'   id_assess_aggs() %>%
#'   filter(agg_level == "T",
#'          grade == "11",
#'          subject == "ELA")
#'
#' # Add trend calculations
#' trend <- calc_assess_trend(multi_year, "pct_met_and_above")
#'
#' # View change from 2019 to 2023
#' trend %>%
#'   filter(end_year %in% c(2019, 2023)) %>%
#'   select(end_year, metric_value, change, pct_change)
#' }
calc_assess_trend <- function(data, metric = "pct_met_and_above") {

  # Ensure data is in tidy format and filtered to metric
  if ("metric_type" %in% names(data)) {
    data <- data %>%
      dplyr::filter(metric_type == metric)
  }

  # Identify grouping columns (all except metric_value and year)
  group_cols <- setdiff(names(data), c("metric_value", "end_year"))

  # Calculate year-over-year changes
  result <- data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) %>%
    dplyr::arrange(end_year) %>%
    dplyr::mutate(
      change = metric_value - dplyr::lag(metric_value),
      pct_change = (metric_value / dplyr::lag(metric_value) - 1) * 100
    ) %>%
    dplyr::ungroup()

  result
}


#' Print tidy CAASPP assessment data
#'
#' @param x A ca_assess_tidy object
#' @param ... Additional arguments (ignored)
#'
#' @export
print.ca_assess_tidy <- function(x, ...) {

  cat("California CAASPP Assessment Data (Tidy Format)\n")
  cat("================================================\n\n")

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

  if ("metric_type" %in% names(x)) {
    metrics <- unique(x$metric_type)
    cat("\nMetrics (", length(metrics), " types):\n")
    cat("  ", paste(metrics, collapse = ", "), "\n")
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
