# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing and standardizing enrollment data
# from the California Department of Education (CDE).
#
# ==============================================================================

#' Convert to numeric, handling suppression markers
#'
#' CDE uses asterisks (*) for suppressed data where cell size is 10 or fewer.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace, then convert to numeric
  x <- gsub(",", "", x)
  x <- trimws(x)
  # Replace * (suppressed) with NA
  x[x == "*"] <- NA
  suppressWarnings(as.numeric(x))
}


#' Process raw enrollment data to standard schema
#'
#' Takes raw enrollment data from CDE and standardizes column names, types,
#' and handles any year-specific format differences. Uses modern processing
#' for 2024+ Census Day files and historical processing for 2017-2023 files.
#'
#' @param raw_data Raw data frame from get_raw_enr()
#' @param end_year The school year end for context
#' @return Processed data frame with standard schema
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Modern format (2024+): Census Day files with aggregation levels and subgroups
  # Historical format (2017-2023): School-level files with race/gender breakdown
  if (end_year >= 2024) {
    process_enr_modern(raw_data, end_year)
  } else {
    process_enr_historical(raw_data, end_year)
  }
}


#' Process modern Census Day format (2024+) CDE data
#'
#' @param raw_data Raw data frame from get_raw_enr_modern()
#' @param end_year The school year end for context
#' @return Processed data frame with standard schema
#' @keywords internal
process_enr_modern <- function(raw_data, end_year) {

  # CDE Census Day Enrollment file columns:
  # Academic Year, Aggregate Level, County Code, District Code, School Code,
  # County Name, District Name, School Name, Charter (All/Y/N),
  # Reporting Category, TOTAL_ENR, GR_TK, GR_KN, GR_01 through GR_12

  cols <- names(raw_data)

  # Find column names (they may vary slightly by year)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build the standardized result data frame
  n_rows <- nrow(raw_data)
  result <- data.frame(
    end_year = rep(as.integer(end_year), n_rows),
    stringsAsFactors = FALSE
  )

  # Academic Year (e.g., "2023-24")
  year_col <- find_col(c("^Academic.?Year$", "^ACADEMIC_YEAR$"))
  if (!is.null(year_col)) {
    result$academic_year <- raw_data[[year_col]]
  }

  # Aggregate Level (T=State, C=County, D=District, S=School)
  agg_col <- find_col(c("^Aggregate.?Level$", "^AGG_LEVEL$"))
  if (!is.null(agg_col)) {
    result$agg_level <- raw_data[[agg_col]]
  }

  # County Code (2 digits)
  county_code_col <- find_col(c("^County.?Code$", "^COUNTY_CODE$"))
  if (!is.null(county_code_col)) {
    # Ensure 2-digit format with leading zeros
    result$county_code <- sprintf("%02s", raw_data[[county_code_col]])
    result$county_code <- gsub(" ", "0", result$county_code)
  }

  # District Code (5 digits)
  district_code_col <- find_col(c("^District.?Code$", "^DISTRICT_CODE$"))
  if (!is.null(district_code_col)) {
    # Ensure 5-digit format with leading zeros
    result$district_code <- sprintf("%05s", raw_data[[district_code_col]])
    result$district_code <- gsub(" ", "0", result$district_code)
  }

  # School Code (7 digits)
  school_code_col <- find_col(c("^School.?Code$", "^SCHOOL_CODE$"))
  if (!is.null(school_code_col)) {
    # Ensure 7-digit format with leading zeros
    result$school_code <- sprintf("%07s", raw_data[[school_code_col]])
    result$school_code <- gsub(" ", "0", result$school_code)
  }

  # Construct full 14-digit CDS code
  if (all(c("county_code", "district_code", "school_code") %in% names(result))) {
    result$cds_code <- paste0(result$county_code, result$district_code, result$school_code)
  }

  # County Name
  county_name_col <- find_col(c("^County.?Name$", "^COUNTY_NAME$", "^County$"))
  if (!is.null(county_name_col)) {
    result$county_name <- trimws(raw_data[[county_name_col]])
  }

  # District Name
  district_name_col <- find_col(c("^District.?Name$", "^DISTRICT_NAME$", "^District$"))
  if (!is.null(district_name_col)) {
    result$district_name <- trimws(raw_data[[district_name_col]])
  }

  # School Name
  school_name_col <- find_col(c("^School.?Name$", "^SCHOOL_NAME$", "^School$"))
  if (!is.null(school_name_col)) {
    result$school_name <- trimws(raw_data[[school_name_col]])
  }

  # Charter Status (All/Y/N)
  charter_col <- find_col(c("^Charter", "^CHARTER$"))
  if (!is.null(charter_col)) {
    result$charter_status <- raw_data[[charter_col]]
  }

  # Reporting Category (demographic subgroup)
  # TA = Total, RE_* = Race/Ethnicity, GN_* = Gender, SG_* = Student Groups, etc.
  reporting_col <- find_col(c("^Reporting.?Category$", "^REPORTING_CATEGORY$"))
  if (!is.null(reporting_col)) {
    result$reporting_category <- raw_data[[reporting_col]]
  }

  # Total Enrollment
  total_col <- find_col(c("^TOTAL_ENR$", "^TOTAL.ENR$", "^Total.?Enrollment$"))
  if (!is.null(total_col)) {
    result$total_enrollment <- safe_numeric(raw_data[[total_col]])
  }

  # Grade-level enrollment columns
  grade_cols <- list(
    grade_tk = c("^GR_TK$", "^GR.TK$"),
    grade_k = c("^GR_KN$", "^GR.KN$", "^GR_K$"),
    grade_01 = c("^GR_01$", "^GR.01$", "^GR_1$"),
    grade_02 = c("^GR_02$", "^GR.02$", "^GR_2$"),
    grade_03 = c("^GR_03$", "^GR.03$", "^GR_3$"),
    grade_04 = c("^GR_04$", "^GR.04$", "^GR_4$"),
    grade_05 = c("^GR_05$", "^GR.05$", "^GR_5$"),
    grade_06 = c("^GR_06$", "^GR.06$", "^GR_6$"),
    grade_07 = c("^GR_07$", "^GR.07$", "^GR_7$"),
    grade_08 = c("^GR_08$", "^GR.08$", "^GR_8$"),
    grade_09 = c("^GR_09$", "^GR.09$", "^GR_9$"),
    grade_10 = c("^GR_10$", "^GR.10$"),
    grade_11 = c("^GR_11$", "^GR.11$"),
    grade_12 = c("^GR_12$", "^GR.12$")
  )

  for (grade_name in names(grade_cols)) {
    grade_col <- find_col(grade_cols[[grade_name]])
    if (!is.null(grade_col)) {
      result[[grade_name]] <- safe_numeric(raw_data[[grade_col]])
    }
  }

  # Convert to tibble for consistency
  result <- dplyr::as_tibble(result)

  result
}


#' Process historical format (1982-2023) CDE data
#'
#' Historical files contain school-level data with race/ethnicity and gender
#' breakdown. This function aggregates the data to create reporting categories
#' similar to the modern format and synthesizes district/county/state aggregates.
#'
#' File format varies by era:
#' - 2015-2023: Has names, ENR_TYPE column, numeric race codes 0-9
#' - 2008-2014: Has names, no ENR_TYPE, numeric race codes 0-9
#' - 1994-2007: No names (just CDS_CODE), numeric race codes 1-8
#' - 1982-1993: Has names (DISTRICT_NAME, SCHOOL_NAME), letter race codes
#'
#' @param raw_data Raw data frame from get_raw_enr_historical()
#' @param end_year The school year end for context
#' @return Processed data frame with standard schema
#' @keywords internal
process_enr_historical <- function(raw_data, end_year) {

  # Race/ethnicity mapping depends on era
  # 2008+: Numeric codes 0-9
  # 1994-2007: Numeric codes 1-8
  # 1982-1993: Letter codes (A=American Indian, B=Black, F=Filipino, H=Hispanic,
  #            I=Indochinese, P=Pacific Islander, W=White, O=Other)
  #            Note: codes changed over time within this period

  if (end_year >= 2008) {
    # Modern numeric codes (0-9)
    race_map <- c(
      "0" = "RE_D",  # Not Reported
      "1" = "RE_I",  # American Indian
      "2" = "RE_A",  # Asian
      "3" = "RE_P",  # Pacific Islander
      "4" = "RE_F",  # Filipino
      "5" = "RE_H",  # Hispanic
      "6" = "RE_B",  # Black/African American
      "7" = "RE_W",  # White
      "8" = "RE_T",  # Two or More Races
      "9" = "RE_D"   # Not Reported
    )
  } else if (end_year >= 1994) {
    # 1994-2007 numeric codes (1-8, slightly different)
    race_map <- c(
      "1" = "RE_I",  # American Indian
      "2" = "RE_A",  # Asian
      "3" = "RE_P",  # Pacific Islander
      "4" = "RE_F",  # Filipino
      "5" = "RE_H",  # Hispanic
      "6" = "RE_B",  # Black/African American
      "7" = "RE_W",  # White
      "8" = "RE_T"   # Multiple/No Response (treated as Two or More)
    )
  } else {
    # 1982-1993 letter codes
    race_map <- c(
      "A" = "RE_I",  # American Indian (or Alaska Native)
      "B" = "RE_B",  # Black
      "C" = "RE_A",  # Chinese (grouped with Asian)
      "F" = "RE_F",  # Filipino
      "H" = "RE_H",  # Hispanic
      "I" = "RE_A",  # Indochinese (grouped with Asian)
      "J" = "RE_A",  # Japanese (grouped with Asian)
      "K" = "RE_A",  # Korean (grouped with Asian)
      "O" = "RE_D",  # Other (treated as Not Reported)
      "P" = "RE_P",  # Pacific Islander
      "W" = "RE_W"   # White
    )
  }

  # Map gender codes to reporting categories
  gender_map <- c(
    "M" = "GN_M",
    "F" = "GN_F",
    "X" = "GN_X",
    "Z" = "GN_Z"
  )

  # Filter to Combined enrollment (C) for years that have ENR_TYPE
  # 2015+ files have ENR_TYPE column; older files don't
  if ("ENR_TYPE" %in% names(raw_data)) {
    raw_data <- raw_data |>
      dplyr::filter(ENR_TYPE == "C")
  }

  # Handle different name column conventions
  # 2008+: COUNTY, DISTRICT, SCHOOL
  # 1982-1993: DISTRICT_NAME, SCHOOL_NAME (no COUNTY)
  # 1994-2007: No name columns at all
  if ("COUNTY" %in% names(raw_data)) {
    # 2008+ format
    raw_data <- raw_data |>
      dplyr::rename(county_name = COUNTY, district_name = DISTRICT, school_name = SCHOOL)
  } else if ("DISTRICT_NAME" %in% names(raw_data)) {
    # 1982-1993 format
    raw_data <- raw_data |>
      dplyr::rename(district_name = DISTRICT_NAME, school_name = SCHOOL_NAME) |>
      dplyr::mutate(county_name = NA_character_)
  } else {
    # 1994-2007 format - no names
    raw_data <- raw_data |>
      dplyr::mutate(
        county_name = NA_character_,
        district_name = NA_character_,
        school_name = NA_character_
      )
  }

  # Grade columns in historical format
  grade_cols_hist <- c("GR_KN", paste0("GR_", 1:12), "UNGR_ELM", "UNGR_SEC")

  # === SCHOOL-LEVEL PROCESSING ===

  # Convert numeric columns
  for (col in c(grade_cols_hist, "ENR_TOTAL", "ADULT")) {
    if (col %in% names(raw_data)) {
      raw_data[[col]] <- safe_numeric(raw_data[[col]])
    }
  }

  # Create school-level data by reporting category
  # First, aggregate by race/ethnicity (creating RE_* categories)
  school_by_race <- raw_data |>
    dplyr::mutate(
      reporting_category = race_map[RACE_ETHNICITY]
    ) |>
    dplyr::filter(!is.na(reporting_category)) |>
    dplyr::group_by(
      CDS_CODE, county_name, district_name, school_name, reporting_category
    ) |>
    dplyr::summarize(
      total_enrollment = sum(ENR_TOTAL, na.rm = TRUE),
      grade_k = sum(GR_KN, na.rm = TRUE),
      grade_01 = sum(GR_1, na.rm = TRUE),
      grade_02 = sum(GR_2, na.rm = TRUE),
      grade_03 = sum(GR_3, na.rm = TRUE),
      grade_04 = sum(GR_4, na.rm = TRUE),
      grade_05 = sum(GR_5, na.rm = TRUE),
      grade_06 = sum(GR_6, na.rm = TRUE),
      grade_07 = sum(GR_7, na.rm = TRUE),
      grade_08 = sum(GR_8, na.rm = TRUE),
      grade_09 = sum(GR_9, na.rm = TRUE),
      grade_10 = sum(GR_10, na.rm = TRUE),
      grade_11 = sum(GR_11, na.rm = TRUE),
      grade_12 = sum(GR_12, na.rm = TRUE),
      .groups = "drop"
    )

  # Create school-level data by gender (creating GN_* categories)
  school_by_gender <- raw_data |>
    dplyr::mutate(
      reporting_category = gender_map[GENDER]
    ) |>
    dplyr::filter(!is.na(reporting_category)) |>
    dplyr::group_by(
      CDS_CODE, county_name, district_name, school_name, reporting_category
    ) |>
    dplyr::summarize(
      total_enrollment = sum(ENR_TOTAL, na.rm = TRUE),
      grade_k = sum(GR_KN, na.rm = TRUE),
      grade_01 = sum(GR_1, na.rm = TRUE),
      grade_02 = sum(GR_2, na.rm = TRUE),
      grade_03 = sum(GR_3, na.rm = TRUE),
      grade_04 = sum(GR_4, na.rm = TRUE),
      grade_05 = sum(GR_5, na.rm = TRUE),
      grade_06 = sum(GR_6, na.rm = TRUE),
      grade_07 = sum(GR_7, na.rm = TRUE),
      grade_08 = sum(GR_8, na.rm = TRUE),
      grade_09 = sum(GR_9, na.rm = TRUE),
      grade_10 = sum(GR_10, na.rm = TRUE),
      grade_11 = sum(GR_11, na.rm = TRUE),
      grade_12 = sum(GR_12, na.rm = TRUE),
      .groups = "drop"
    )

  # Create school-level totals (TA category)
  school_totals <- raw_data |>
    dplyr::mutate(
      reporting_category = "TA"
    ) |>
    dplyr::group_by(
      CDS_CODE, county_name, district_name, school_name, reporting_category
    ) |>
    dplyr::summarize(
      total_enrollment = sum(ENR_TOTAL, na.rm = TRUE),
      grade_k = sum(GR_KN, na.rm = TRUE),
      grade_01 = sum(GR_1, na.rm = TRUE),
      grade_02 = sum(GR_2, na.rm = TRUE),
      grade_03 = sum(GR_3, na.rm = TRUE),
      grade_04 = sum(GR_4, na.rm = TRUE),
      grade_05 = sum(GR_5, na.rm = TRUE),
      grade_06 = sum(GR_6, na.rm = TRUE),
      grade_07 = sum(GR_7, na.rm = TRUE),
      grade_08 = sum(GR_8, na.rm = TRUE),
      grade_09 = sum(GR_9, na.rm = TRUE),
      grade_10 = sum(GR_10, na.rm = TRUE),
      grade_11 = sum(GR_11, na.rm = TRUE),
      grade_12 = sum(GR_12, na.rm = TRUE),
      .groups = "drop"
    )

  # Combine school-level data
  schools <- dplyr::bind_rows(school_totals, school_by_race, school_by_gender) |>
    dplyr::mutate(agg_level = "S")

  # === CREATE DISTRICT AGGREGATES ===
  districts <- schools |>
    dplyr::mutate(
      county_code = substr(CDS_CODE, 1, 2),
      district_code = substr(CDS_CODE, 3, 7)
    ) |>
    dplyr::group_by(county_code, district_code, county_name, district_name, reporting_category) |>
    dplyr::summarize(
      total_enrollment = sum(total_enrollment, na.rm = TRUE),
      grade_k = sum(grade_k, na.rm = TRUE),
      grade_01 = sum(grade_01, na.rm = TRUE),
      grade_02 = sum(grade_02, na.rm = TRUE),
      grade_03 = sum(grade_03, na.rm = TRUE),
      grade_04 = sum(grade_04, na.rm = TRUE),
      grade_05 = sum(grade_05, na.rm = TRUE),
      grade_06 = sum(grade_06, na.rm = TRUE),
      grade_07 = sum(grade_07, na.rm = TRUE),
      grade_08 = sum(grade_08, na.rm = TRUE),
      grade_09 = sum(grade_09, na.rm = TRUE),
      grade_10 = sum(grade_10, na.rm = TRUE),
      grade_11 = sum(grade_11, na.rm = TRUE),
      grade_12 = sum(grade_12, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      CDS_CODE = paste0(county_code, district_code, "0000000"),
      school_name = NA_character_,
      agg_level = "D"
    ) |>
    dplyr::select(-county_code, -district_code)

  # === CREATE COUNTY AGGREGATES ===
  counties <- schools |>
    dplyr::mutate(
      county_code = substr(CDS_CODE, 1, 2)
    ) |>
    dplyr::group_by(county_code, county_name, reporting_category) |>
    dplyr::summarize(
      total_enrollment = sum(total_enrollment, na.rm = TRUE),
      grade_k = sum(grade_k, na.rm = TRUE),
      grade_01 = sum(grade_01, na.rm = TRUE),
      grade_02 = sum(grade_02, na.rm = TRUE),
      grade_03 = sum(grade_03, na.rm = TRUE),
      grade_04 = sum(grade_04, na.rm = TRUE),
      grade_05 = sum(grade_05, na.rm = TRUE),
      grade_06 = sum(grade_06, na.rm = TRUE),
      grade_07 = sum(grade_07, na.rm = TRUE),
      grade_08 = sum(grade_08, na.rm = TRUE),
      grade_09 = sum(grade_09, na.rm = TRUE),
      grade_10 = sum(grade_10, na.rm = TRUE),
      grade_11 = sum(grade_11, na.rm = TRUE),
      grade_12 = sum(grade_12, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      CDS_CODE = paste0(county_code, "000000000000"),
      district_name = NA_character_,
      school_name = NA_character_,
      agg_level = "C"
    ) |>
    dplyr::select(-county_code)

  # === CREATE STATE AGGREGATE ===
  state <- schools |>
    dplyr::group_by(reporting_category) |>
    dplyr::summarize(
      total_enrollment = sum(total_enrollment, na.rm = TRUE),
      grade_k = sum(grade_k, na.rm = TRUE),
      grade_01 = sum(grade_01, na.rm = TRUE),
      grade_02 = sum(grade_02, na.rm = TRUE),
      grade_03 = sum(grade_03, na.rm = TRUE),
      grade_04 = sum(grade_04, na.rm = TRUE),
      grade_05 = sum(grade_05, na.rm = TRUE),
      grade_06 = sum(grade_06, na.rm = TRUE),
      grade_07 = sum(grade_07, na.rm = TRUE),
      grade_08 = sum(grade_08, na.rm = TRUE),
      grade_09 = sum(grade_09, na.rm = TRUE),
      grade_10 = sum(grade_10, na.rm = TRUE),
      grade_11 = sum(grade_11, na.rm = TRUE),
      grade_12 = sum(grade_12, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      CDS_CODE = "00000000000000",
      county_name = NA_character_,
      district_name = NA_character_,
      school_name = NA_character_,
      agg_level = "T"
    )

  # Combine all levels
  all_data <- dplyr::bind_rows(state, counties, districts, schools)

  # Build final result with standard schema
  result <- all_data |>
    dplyr::mutate(
      end_year = as.integer(end_year),
      academic_year = paste0(end_year - 1, "-", substr(end_year, 3, 4)),
      cds_code = CDS_CODE,
      county_code = substr(CDS_CODE, 1, 2),
      district_code = substr(CDS_CODE, 3, 7),
      school_code = substr(CDS_CODE, 8, 14),
      charter_status = "All",  # Not available in historical data
      # Note: Historical data does not have TK
      grade_tk = NA_integer_
    ) |>
    dplyr::select(
      end_year, academic_year, agg_level,
      cds_code, county_code, district_code, school_code,
      county_name, district_name, school_name,
      charter_status, reporting_category, total_enrollment,
      grade_tk, grade_k, grade_01, grade_02, grade_03, grade_04,
      grade_05, grade_06, grade_07, grade_08, grade_09, grade_10,
      grade_11, grade_12
    )

  # Convert to tibble for consistency
  result <- dplyr::as_tibble(result)

  result
}


#' Parse CDS code into components
#'
#' Splits a 14-digit CDS code into county, district, and school components.
#'
#' @param cds_code A 14-digit CDS code string or vector of codes
#' @return Data frame with county_code, district_code, school_code columns
#' @export
#' @examples
#' \dontrun{
#' # Parse a single CDS code
#' parse_cds_code("01611920130229")
#'
#' # Parse multiple codes
#' parse_cds_code(c("01611920130229", "19647330000000"))
#' }
parse_cds_code <- function(cds_code) {

  # Ensure codes are character and padded to 14 digits
  cds_code <- as.character(cds_code)
  cds_code <- sprintf("%014s", cds_code)
  cds_code <- gsub(" ", "0", cds_code)

  data.frame(
    cds_code = cds_code,
    county_code = substr(cds_code, 1, 2),
    district_code = substr(cds_code, 3, 7),
    school_code = substr(cds_code, 8, 14),
    stringsAsFactors = FALSE
  )
}


#' Identify aggregation level from CDS code
#'
#' Determines if a CDS code represents state, county, district, or school level
#' based on the pattern of zeros in the code.
#'
#' @param cds_code A 14-digit CDS code string or vector
#' @return Character vector with "state", "county", "district", or "school"
#' @keywords internal
identify_agg_level <- function(cds_code) {

  # Ensure codes are padded
  cds_code <- sprintf("%014s", as.character(cds_code))
  cds_code <- gsub(" ", "0", cds_code)

  county <- substr(cds_code, 1, 2)
  district <- substr(cds_code, 3, 7)
  school <- substr(cds_code, 8, 14)

  dplyr::case_when(
    county == "00" & district == "00000" & school == "0000000" ~ "state",
    district == "00000" & school == "0000000" ~ "county",
    school == "0000000" ~ "district",
    TRUE ~ "school"
  )
}
