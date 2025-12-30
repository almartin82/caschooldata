# ==============================================================================
# Enrollment Data Tidying Functions
# ==============================================================================
#
# This file contains functions for converting enrollment data from wide format
# to tidy (long) format and identifying aggregation levels.
#
# ==============================================================================

#' Convert enrollment data to tidy format
#'
#' Pivots enrollment data from wide format (one column per grade) to long format
#' with a grade column. Also handles the reporting_category column which already
#' contains demographic subgroups.
#'
#' @param wide_data Data frame in wide format from process_enr()
#' @return Tidy data frame with grade and subgroup columns
#' @export
#' @examples
#' \dontrun{
#' # Get wide format and then tidy
#' wide <- fetch_enr(2024, tidy = FALSE)
#' tidy <- tidy_enr(wide)
#' }
tidy_enr <- function(wide_data) {

  # CDE data already has subgroups in reporting_category column
  # We need to pivot grade columns to long format

  # Invariant columns (identifiers that stay the same)
  invariants <- c(
    "end_year", "academic_year", "agg_level",
    "cds_code", "county_code", "district_code", "school_code",
    "county_name", "district_name", "school_name",
    "charter_status", "reporting_category", "total_enrollment"
  )
  invariants <- invariants[invariants %in% names(wide_data)]

  # Grade-level columns to pivot
  grade_cols <- grep("^grade_", names(wide_data), value = TRUE)

  if (length(grade_cols) == 0) {
    # No grade columns to pivot - just add grade_level = "TOTAL"
    result <- wide_data %>%
      dplyr::mutate(
        grade_level = "TOTAL",
        n_students = total_enrollment
      )
    return(result)
  }

  # Grade level mapping from column names to display values
  grade_level_map <- c(
    "grade_tk" = "TK",
    "grade_k" = "K",
    "grade_01" = "01",
    "grade_02" = "02",
    "grade_03" = "03",
    "grade_04" = "04",
    "grade_05" = "05",
    "grade_06" = "06",
    "grade_07" = "07",
    "grade_08" = "08",
    "grade_09" = "09",
    "grade_10" = "10",
    "grade_11" = "11",
    "grade_12" = "12"
  )

  # Create total enrollment rows (grade_level = "TOTAL")
  total_rows <- wide_data %>%
    dplyr::select(dplyr::all_of(invariants)) %>%
    dplyr::mutate(
      grade_level = "TOTAL",
      n_students = total_enrollment
    )

  # Pivot grade columns to long format
  grade_rows <- purrr::map_df(grade_cols, function(.x) {
    gl <- grade_level_map[.x]
    if (is.na(gl)) gl <- gsub("^grade_", "", .x)

    wide_data %>%
      dplyr::select(dplyr::all_of(c(invariants, .x))) %>%
      dplyr::rename(n_students = dplyr::all_of(.x)) %>%
      dplyr::mutate(grade_level = gl)
  })

  # Combine total and grade-level rows
  result <- dplyr::bind_rows(total_rows, grade_rows) %>%
    dplyr::filter(!is.na(n_students))

  # Map reporting_category to human-readable subgroup names
  result <- result %>%
    dplyr::mutate(
      subgroup = map_reporting_category(reporting_category)
    )

  # Reorder columns
  col_order <- c(
    "end_year", "academic_year", "agg_level",
    "cds_code", "county_code", "district_code", "school_code",
    "county_name", "district_name", "school_name",
    "charter_status", "grade_level", "reporting_category", "subgroup",
    "n_students", "total_enrollment"
  )
  col_order <- col_order[col_order %in% names(result)]
  result <- result %>%
    dplyr::select(dplyr::all_of(col_order), dplyr::everything())

  result
}


#' Map CDE reporting category codes to human-readable names
#'
#' Converts CDE reporting category codes (e.g., "RE_H", "GN_F") to
#' human-readable subgroup names.
#'
#' @param code Character vector of reporting category codes
#' @return Character vector of human-readable subgroup names
#' @keywords internal
map_reporting_category <- function(code) {

  # CDE Reporting Category codes:
  # TA = Total
  # RE_* = Race/Ethnicity
  # GN_* = Gender
  # SG_* = Student Groups
  # AR_* = Age Range
  # ELAS_* = English Language Acquisition Status

  category_map <- c(
    # Total
    "TA" = "total",

    # Race/Ethnicity
    "RE_A" = "asian",
    "RE_B" = "black",
    "RE_D" = "not_reported",
    "RE_F" = "filipino",
    "RE_H" = "hispanic",
    "RE_I" = "native_american",
    "RE_P" = "pacific_islander",
    "RE_T" = "multiracial",
    "RE_W" = "white",

    # Gender
    "GN_F" = "female",
    "GN_M" = "male",
    "GN_X" = "nonbinary",
    "GN_Z" = "gender_missing",

    # Student Groups
    "SG_EL" = "english_learner",
    "SG_DS" = "students_with_disabilities",
    "SG_SD" = "socioeconomically_disadvantaged",
    "SG_MG" = "migrant",
    "SG_FS" = "foster_youth",
    "SG_HM" = "homeless",

    # English Language Acquisition Status
    "ELAS_ADEL" = "adult_el",
    "ELAS_EL" = "english_learner",
    "ELAS_EO" = "english_only",
    "ELAS_IFEP" = "initial_fluent_english",
    "ELAS_MISS" = "elas_missing",
    "ELAS_RFEP" = "reclassified_fluent_english",
    "ELAS_TBD" = "elas_to_be_determined",

    # Age Ranges
    "AR_03" = "age_0_3",
    "AR_0418" = "age_4_18",
    "AR_1922" = "age_19_22",
    "AR_2329" = "age_23_29",
    "AR_3039" = "age_30_39",
    "AR_4049" = "age_40_49",
    "AR_50P" = "age_50_plus"
  )

  # Map codes to names, keeping original if not found
  result <- category_map[code]
  result[is.na(result)] <- code[is.na(result)]

  as.character(result)
}


#' Identify aggregation rows in enrollment data
#'
#' Adds boolean flags to identify state, county, district, and school level
#' records based on CDS code patterns or the agg_level column.
#'
#' @param data Tidy enrollment data frame
#' @return Data frame with is_state, is_county, is_district, is_school columns added
#' @export
id_enr_aggs <- function(data) {

  # CDE data includes agg_level column: T, C, D, S
  # Also can derive from CDS code patterns

  if ("agg_level" %in% names(data)) {
    data <- data %>%
      dplyr::mutate(
        is_state = agg_level == "T",
        is_county = agg_level == "C",
        is_district = agg_level == "D",
        is_school = agg_level == "S",
        is_charter = charter_status == "Y"
      )
  } else if ("cds_code" %in% names(data)) {
    # Derive from CDS code
    data <- data %>%
      dplyr::mutate(
        is_state = substr(cds_code, 1, 2) == "00" &
                   substr(cds_code, 3, 7) == "00000" &
                   substr(cds_code, 8, 14) == "0000000",
        is_county = !is_state &
                    substr(cds_code, 3, 7) == "00000" &
                    substr(cds_code, 8, 14) == "0000000",
        is_district = !is_state & !is_county &
                      substr(cds_code, 8, 14) == "0000000",
        is_school = !is_state & !is_county & !is_district,
        is_charter = if ("charter_status" %in% names(.)) charter_status == "Y" else NA
      )
  }

  data
}


#' Create grade-level aggregates
#'
#' Creates aggregations for common grade groupings: K-8, 9-12 (HS), K-12.
#'
#' @param df A tidy enrollment data frame
#' @return Data frame with aggregated enrollment for grade bands
#' @export
enr_grade_aggs <- function(df) {

  # Group by invariants (everything except grade_level and counts)
  group_vars <- c(
    "end_year", "academic_year", "agg_level",
    "cds_code", "county_code", "district_code", "school_code",
    "county_name", "district_name", "school_name",
    "charter_status", "reporting_category", "subgroup",
    "is_state", "is_county", "is_district", "is_school", "is_charter"
  )
  group_vars <- group_vars[group_vars %in% names(df)]

  # Filter to total subgroup only for aggregation
  df_totals <- df %>%
    dplyr::filter(reporting_category == "TA" | subgroup == "total")

  # K-8 aggregate (includes TK and K)
  k8_agg <- df_totals %>%
    dplyr::filter(
      grade_level %in% c("TK", "K", "01", "02", "03", "04", "05", "06", "07", "08")
    ) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(grade_level = "K8")

  # High school (9-12) aggregate
  hs_agg <- df_totals %>%
    dplyr::filter(
      grade_level %in% c("09", "10", "11", "12")
    ) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(grade_level = "HS")

  # K-12 aggregate (includes TK)
  k12_agg <- df_totals %>%
    dplyr::filter(
      grade_level %in% c("TK", "K", "01", "02", "03", "04", "05", "06", "07", "08",
                         "09", "10", "11", "12")
    ) %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarize(
      n_students = sum(n_students, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(grade_level = "K12")

  dplyr::bind_rows(k8_agg, hs_agg, k12_agg)
}
