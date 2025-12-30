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
#' and handles any year-specific format differences.
#'
#' @param raw_data Raw data frame from get_raw_enr()
#' @param end_year The school year end for context
#' @return Processed data frame with standard schema
#' @keywords internal
process_enr <- function(raw_data, end_year) {

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
