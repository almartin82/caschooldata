# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# California Department of Education (CDE) website.
#
# Data source: https://www.cde.ca.gov/SchoolDirectory/
#
# ==============================================================================

#' Fetch California school directory data
#'
#' Downloads and processes school directory data from the California Department
#' of Education SchoolDirectory. This includes all public schools and districts
#' with contact information and administrator names.
#'
#' @param end_year Currently unused. The directory data represents current
#'   schools and is not year-specific. Included for API consistency with
#'   other fetch functions.
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from CDE.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from CDE.
#' @return A tibble with school directory data. Columns include:
#'   \itemize{
#'     \item \code{cds_code}: 14-digit CDS identifier
#'     \item \code{county_code}: 2-digit county code
#'     \item \code{district_code}: 5-digit district code
#'     \item \code{school_code}: 7-digit school code
#'     \item \code{school_name}: School name (or district name for district-level rows)
#'     \item \code{district_name}: District name
#'     \item \code{county_name}: County name
#'     \item \code{school_type}: Type of school (e.g., "Elementary", "High School")
#'     \item \code{street}: Street address
#'     \item \code{city}: City
#'     \item \code{state}: State (always "CA")
#'     \item \code{zip}: ZIP code
#'     \item \code{phone}: Phone number
#'     \item \code{admin_name}: Administrator name (principal for schools,
#'       superintendent for districts)
#'     \item \code{agg_level}: Aggregation level ("S" = School, "D" = District)
#'     \item \code{status}: School status (e.g., "Active", "Closed")
#'     \item \code{charter_status}: Charter indicator (Y/N)
#'     \item \code{latitude}: Geographic latitude
#'     \item \code{longitude}: Geographic longitude
#'   }
#' @details
#' The directory data is downloaded as an Excel file from the CDE SchoolDirectory
#' page. This data represents the current state of California schools and districts
#' and is updated periodically by CDE.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original CDE column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to active schools only
#' library(dplyr)
#' active_schools <- dir_data |>
#'   filter(agg_level == "S", status == "Active")
#'
#' # Find all schools in a district
#' lausd_schools <- dir_data |>
#'   filter(district_code == "64733", agg_level == "S")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from CDE
  raw <- get_raw_directory()

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from CDE
#'
#' Downloads the raw school directory Excel file from the California
#' Department of Education website.
#'
#' @return Raw data frame as downloaded from CDE
#' @keywords internal
get_raw_directory <- function() {

  # Build download URL
  url <- build_directory_url()

  message("Downloading school directory data from CDE...")

  # Download file to temp location
  tname <- tempfile(pattern = "cde_directory", tmpdir = tempdir(), fileext = ".xlsx")

  # Set longer timeout for large files
  old_timeout <- getOption("timeout")
  options(timeout = 300)  # 5 minutes

  tryCatch({
    downloader::download(url, dest = tname, mode = "wb", quiet = TRUE)
  }, error = function(e) {
    options(timeout = old_timeout)
    stop(paste("Failed to download school directory data from CDE:", e$message))
  })

  options(timeout = old_timeout)

  # Check if download was successful (file should be reasonably large)
  file_info <- file.info(tname)
  if (file_info$size < 100000) {
    stop("Download failed - file too small, may be error page")
  }

  message(paste("Downloaded", round(file_info$size / 1024 / 1024, 1), "MB file"))

  # Read Excel file
  # The file contains school and district records with administrator info
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required to read Excel files. Install it with install.packages('readxl')")
  }

  df <- readxl::read_excel(
    tname,
    col_types = "text",  # Read all as text to preserve leading zeros
    .name_repair = "unique"
  )

  message(paste("Loaded", nrow(df), "records"))

  # Convert to tibble for consistency
  dplyr::as_tibble(df)
}


#' Build CDE school directory download URL
#'
#' Constructs the download URL for the school directory Excel file.
#'
#' @return URL string
#' @keywords internal
build_directory_url <- function() {
  # CDE SchoolDirectory download URL
  # tp=xlsx for Excel format, ict=Y includes admin names
  "https://www.cde.ca.gov/SchoolDirectory/report?rid=dl1&tp=xlsx&ict=Y"
}


#' Process raw school directory data to standard schema
#'
#' Takes raw school directory data from CDE and standardizes column names,
#' types, and adds derived columns.
#'
#' @param raw_data Raw data frame from get_raw_directory()
#' @return Processed data frame with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  cols <- names(raw_data)

  # Helper to find columns with flexible matching
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build the standardized result data frame
  n_rows <- nrow(raw_data)
  result <- dplyr::tibble(.rows = n_rows)

  # CDSCode - 14-digit identifier
  cds_col <- find_col(c("^CDSCode$", "^CDS.?Code$", "^CDS$"))
  if (!is.null(cds_col)) {
    # Ensure 14-digit format with leading zeros
    result$cds_code <- sprintf("%014s", raw_data[[cds_col]])
    result$cds_code <- gsub(" ", "0", result$cds_code)
  }

  # Extract county, district, school codes from CDS
  if ("cds_code" %in% names(result)) {
    result$county_code <- substr(result$cds_code, 1, 2)
    result$district_code <- substr(result$cds_code, 3, 7)
    result$school_code <- substr(result$cds_code, 8, 14)
  }

  # County Name
  county_col <- find_col(c("^County$", "^CountyName$", "^County.?Name$"))
  if (!is.null(county_col)) {
    result$county_name <- trimws(raw_data[[county_col]])
  }

  # District Name
  district_col <- find_col(c("^District$", "^DistrictName$", "^District.?Name$", "^DOC$"))
  if (!is.null(district_col)) {
    result$district_name <- trimws(raw_data[[district_col]])
  }

  # School Name
  school_col <- find_col(c("^School$", "^SchoolName$", "^School.?Name$"))
  if (!is.null(school_col)) {
    result$school_name <- trimws(raw_data[[school_col]])
  }

  # School Type / Entity Type
  type_col <- find_col(c("^SOC$", "^SchoolType$", "^School.?Type$", "^EntityType$", "^EILName$"))
  if (!is.null(type_col)) {
    result$school_type <- trimws(raw_data[[type_col]])
  }

  # Status (Active, Closed, etc.)
  status_col <- find_col(c("^StatusType$", "^Status$", "^StatusCode$"))
  if (!is.null(status_col)) {
    result$status <- trimws(raw_data[[status_col]])
  }

  # Charter Status
  charter_col <- find_col(c("^Charter$", "^CharterNum$", "^Charter.?Number$"))
  if (!is.null(charter_col)) {
    # If there's a charter number, it's a charter school
    charter_vals <- raw_data[[charter_col]]
    result$charter_status <- ifelse(
      is.na(charter_vals) | charter_vals == "" | charter_vals == "0",
      "N",
      "Y"
    )
  } else {
    result$charter_status <- NA_character_
  }

  # Address fields
  street_col <- find_col(c("^Street$", "^StreetAbr$", "^Address$", "^MailStreet$"))
  if (!is.null(street_col)) {
    result$street <- trimws(raw_data[[street_col]])
  }

  city_col <- find_col(c("^City$", "^MailCity$"))
  if (!is.null(city_col)) {
    result$city <- trimws(raw_data[[city_col]])
  }

  state_col <- find_col(c("^State$", "^MailState$"))
  if (!is.null(state_col)) {
    result$state <- trimws(raw_data[[state_col]])
  } else {
    result$state <- "CA"
  }

  zip_col <- find_col(c("^Zip$", "^ZipCode$", "^MailZip$"))
  if (!is.null(zip_col)) {
    result$zip <- trimws(raw_data[[zip_col]])
  }

  # Phone
  phone_col <- find_col(c("^Phone$", "^Telephone$", "^PhoneNumber$"))
  if (!is.null(phone_col)) {
    result$phone <- trimws(raw_data[[phone_col]])
  }

  # Administrator Name - combine first and last name if available
  admin_fname_col <- find_col(c("^AdmFName$", "^AdminFirstName$", "^PrincipalFirstName$"))
  admin_lname_col <- find_col(c("^AdmLName$", "^AdminLastName$", "^PrincipalLastName$"))

  if (!is.null(admin_fname_col) && !is.null(admin_lname_col)) {
    fname <- trimws(raw_data[[admin_fname_col]])
    lname <- trimws(raw_data[[admin_lname_col]])
    # Combine first and last name
    result$admin_name <- ifelse(
      is.na(fname) | fname == "",
      ifelse(is.na(lname) | lname == "", NA_character_, lname),
      ifelse(is.na(lname) | lname == "", fname, paste(fname, lname))
    )
  } else {
    # Try single admin name column
    admin_col <- find_col(c("^Administrator$", "^Principal$", "^AdminName$"))
    if (!is.null(admin_col)) {
      result$admin_name <- trimws(raw_data[[admin_col]])
    }
  }

  # Latitude and Longitude
  lat_col <- find_col(c("^Latitude$", "^Lat$"))
  if (!is.null(lat_col)) {
    result$latitude <- as.numeric(raw_data[[lat_col]])
  }

  lon_col <- find_col(c("^Longitude$", "^Long$", "^Lon$"))
  if (!is.null(lon_col)) {
    result$longitude <- as.numeric(raw_data[[lon_col]])
  }

  # Determine aggregation level from school code
  # School code of "0000000" indicates a district-level record
  if ("school_code" %in% names(result)) {
    result$agg_level <- ifelse(result$school_code == "0000000", "D", "S")
  }

  # Website
  website_col <- find_col(c("^Website$", "^WebSite$", "^URL$", "^Web$"))
  if (!is.null(website_col)) {
    result$website <- trimws(raw_data[[website_col]])
  }

  # Email
  email_col <- find_col(c("^AdmEmail$", "^Email$", "^EmailAddress$"))
  if (!is.null(email_col)) {
    result$email <- trimws(raw_data[[email_col]])
  }

  # OpenDate / ClosedDate for understanding school lifecycle
  open_col <- find_col(c("^OpenDate$", "^DateOpened$"))
  if (!is.null(open_col)) {
    result$open_date <- raw_data[[open_col]]
  }

  closed_col <- find_col(c("^ClosedDate$", "^DateClosed$"))
  if (!is.null(closed_col)) {
    result$closed_date <- raw_data[[closed_col]]
  }

  # Reorder columns for consistency
  preferred_order <- c(
    "cds_code", "county_code", "district_code", "school_code",
    "agg_level", "county_name", "district_name", "school_name",
    "school_type", "status", "charter_status",
    "street", "city", "state", "zip", "phone",
    "admin_name", "email", "website",
    "latitude", "longitude",
    "open_date", "closed_date"
  )

  existing_cols <- preferred_order[preferred_order %in% names(result)]
  other_cols <- setdiff(names(result), preferred_order)

  result <- result |>
    dplyr::select(dplyr::all_of(c(existing_cols, other_cols)))

  result
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @param max_age Maximum age in days (default 30). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 30) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
