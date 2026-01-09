# ==============================================================================
# Graduation Rate Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw graduation data from CDE
# into a standardized schema.
#
# ==============================================================================

#' Process raw graduation data into standard schema
#'
#' Transforms raw CDE graduation data into the standardized schema used by
#' the package. Converts record types, parses CDS codes, maps student groups,
#' and standardizes column names.
#'
#' @param raw_data Data frame from get_raw_graduation()
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_graduation <- function(raw_data, end_year) {

  # Helper to safely get a column value
  safe_col <- function(df, col_name) {
    if (col_name %in% names(df)) {
      return(df[[col_name]])
    }
    return(rep(NA_character_, nrow(df)))
  }

  # Normalize column names (lowercase, remove spaces)
  names(raw_data) <- tolower(gsub(" ", "", names(raw_data)))

  # Extract columns with flexible name matching
  cds <- safe_col(raw_data, "cds")
  rtype <- safe_col(raw_data, "rtype")
  schoolname <- safe_col(raw_data, "schoolname")
  districtname <- safe_col(raw_data, "districtname")
  countyname <- safe_col(raw_data, "countyname")
  studentgroup <- safe_col(raw_data, "studentgroup")

  # Counts and rates
  currnumer <- safe_col(raw_data, "currnumer")  # Graduates
  currdenom <- safe_col(raw_data, "currdenom")  # Cohort
  currstatus <- safe_col(raw_data, "currstatus")  # Grad rate (0-100)

  # Convert to numeric
  currnumer <- as.numeric(currnumer)
  currdenom <- as.numeric(currdenom)
  currstatus <- as.numeric(currstatus)

  # Determine type from rtype (S=School, D=District, X=State)
  type <- ifelse(rtype == "X", "State",
           ifelse(rtype == "D", "District",
           ifelse(rtype == "S", "School",
           ifelse(is.na(rtype) & cds == "00000000000000", "State",
           ifelse(is.na(rtype) & substr(cds, 8, 14) == "0000000", "District",
           "School")))))

  # Build processed data frame
  processed <- data.frame(
    end_year = end_year,
    type = type,

    # District information (extract from CDS code)
    # CDS format: First 7 chars = district, last 7 chars = school
    district_id = ifelse(type == "State", NA_character_, substr(cds, 1, 7)),
    district_name = ifelse(type == "State", NA_character_, districtname),

    # School information (only for School type)
    school_id = ifelse(type == "School", cds, NA_character_),
    school_name = ifelse(type == "School", schoolname, NA_character_),

    # Subgroup
    subgroup = studentgroup,

    # Counts
    cohort_count = currdenom,
    graduate_count = currnumer,

    # Graduation rate (convert from 0-100 to 0-1)
    grad_rate = currstatus / 100,

    stringsAsFactors = FALSE
  )

  # Standardize subgroup names
  processed$subgroup <- dplyr::case_when(
    processed$subgroup == "ALL" ~ "all",
    processed$subgroup == "AA" ~ "black",
    processed$subgroup == "AI" ~ "native_american",
    processed$subgroup == "AS" ~ "asian",
    processed$subgroup == "FI" ~ "filipino",
    processed$subgroup == "HI" ~ "hispanic",
    processed$subgroup == "PI" ~ "pacific_islander",
    processed$subgroup == "WH" ~ "white",
    processed$subgroup == "MR" ~ "multiracial",
    processed$subgroup == "EL" ~ "english_learner",
    processed$subgroup == "LTEL" ~ "long_term_english_learner",
    processed$subgroup == "SED" ~ "low_income",
    processed$subgroup == "SWD" ~ "special_ed",
    processed$subgroup == "FOS" ~ "foster_care",
    processed$subgroup == "HOM" ~ "homeless",
    is.na(processed$subgroup) ~ NA_character_,
    TRUE ~ tolower(processed$subgroup)
  )

  # Add aggregation level flags
  processed$is_state <- processed$type == "State"
  processed$is_district <- processed$type == "District"
  processed$is_school <- processed$type == "School"

  # Select final columns (14-column standard schema)
  processed$metric <- "combined"  # CA uses combined 4-year and 5-year rate

  # Select and order columns
  result <- processed[, c(
    "end_year", "type",
    "district_id", "district_name",
    "school_id", "school_name",
    "subgroup", "metric",
    "grad_rate", "cohort_count", "graduate_count",
    "is_state", "is_district", "is_school"
  )]

  # Remove rows with missing grad_rate (data quality)
  result <- result[!is.na(result$grad_rate), ]

  result
}
