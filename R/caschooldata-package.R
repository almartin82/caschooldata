# Declare global variables to avoid R CMD check NOTE
utils::globalVariables(c(
  ".", "agg_level", "cds_code", "charter_status", "grade_level",
  "is_county", "is_district", "is_state", "n_students",
  "reporting_category", "subgroup", "total_enrollment",
  # Column names from raw data (uppercase)
  "ACADEMIC_YEAR", "ENR_TYPE", "COUNTY", "DISTRICT", "SCHOOL",
  "DISTRICT_NAME", "SCHOOL_NAME", "RACE_ETHNICITY", "CDS_CODE",
  "ENR_TOTAL", "GR_KN", "GR_1", "GR_2", "GR_3", "GR_4", "GR_5",
  "GR_6", "GR_7", "GR_8", "GR_9", "GR_10", "GR_11", "GR_12", "GENDER",
  # Column names after processing (lowercase)
  "county_name", "district_name", "school_name",
  "county_code", "district_code", "school_code",
  "grade_k", "grade_01", "grade_02", "grade_03", "grade_04",
  "grade_05", "grade_06", "grade_07", "grade_08", "grade_09",
  "grade_10", "grade_11", "grade_12", "grade_tk", "academic_year"
))

#' caschooldata: Fetch and Process California School Data
#'
#' The caschooldata package provides functions for downloading and processing
#' school data from the California Department of Education (CDE). It offers
#' a consistent, tidy interface for working with California public school
#' enrollment data.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{fetch_enr}}: Download and process enrollment data
#'   \item \code{\link{fetch_enr_multi}}: Download enrollment for multiple years
#'   \item \code{\link{get_available_years}}: Get available data years (1982-2025)
#'   \item \code{\link{tidy_enr}}: Convert wide enrollment to tidy format
#'   \item \code{\link{id_enr_aggs}}: Identify aggregation levels in data
#'   \item \code{\link{parse_cds_code}}: Parse CDS codes into components
#' }
#'
#' @section Cache Functions:
#' \itemize{
#'   \item \code{\link{cache_status}}: Check cached data status
#'   \item \code{\link{clear_enr_cache}}: Clear cached data
#' }
#'
#' @section Data Source:
#' Data is sourced from the California Department of Education (CDE) DataQuest:
#' \url{https://dq.cde.ca.gov/dataquest/}
#'
#' Enrollment data files are from the Census Day enrollment collection, which
#' provides a snapshot of enrollment on the first Wednesday in October.
#'
#' @section CDS Codes:
#' California uses a 14-digit County-District-School (CDS) code system:
#' \itemize{
#'   \item 2 digits: County code (01-58, representing California's 58 counties)
#'   \item 5 digits: District code
#'   \item 7 digits: School code
#' }
#'
#' @docType package
#' @name caschooldata-package
#' @aliases caschooldata
#' @keywords internal
"_PACKAGE"
