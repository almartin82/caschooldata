# ==============================================================================
# Caching Functions
# ==============================================================================
#
# This file contains functions for caching enrollment data locally to avoid
# repeated downloads from CDE.
#
# Cache location: rappdirs::user_cache_dir("caschooldata")
#
# ==============================================================================

#' Get the cache directory for caschooldata
#'
#' Returns the path to the cache directory, creating it if necessary.
#' Uses rappdirs for cross-platform cache location.
#'
#' @return Path to cache directory
#' @keywords internal
get_cache_dir <- function() {
  cache_dir <- rappdirs::user_cache_dir("caschooldata")

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  cache_dir
}


#' Get cached file path for a given year
#'
#' @param end_year School year end
#' @param type File type ("tidy", "wide", "grad_tidy", "grad_wide")
#' @return Path to cached file
#' @keywords internal
get_cache_path <- function(end_year, type = "tidy") {
  cache_dir <- get_cache_dir()

  # Determine prefix based on type
  if (grepl("^grad_", type)) {
    prefix <- "grad_"
  } else {
    prefix <- "enr_"
  }

  file.path(cache_dir, paste0(prefix, type, "_", end_year, ".rds"))
}

#' Build cache file path
#'
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy", "wide", "grad_tidy", "grad_wide")
#' @return File path string
#' @keywords internal
build_cache_path <- function(end_year, cache_type) {
  get_cache_path(end_year, cache_type)
}


#' Check if cached data exists
#'
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy" or "wide")
#' @param max_age Maximum age in days (default 30). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists <- function(end_year, cache_type, max_age = 30) {
  cache_path <- build_cache_path(end_year, cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read data from cache
#'
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy" or "wide")
#' @return Cached data frame
#' @keywords internal
read_cache <- function(end_year, cache_type) {
  cache_path <- build_cache_path(end_year, cache_type)
  readRDS(cache_path)
}


#' Write data to cache
#'
#' @param data Data frame to cache
#' @param end_year School year end
#' @param cache_type Type of cache ("tidy" or "wide")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache <- function(data, end_year, cache_type) {
  cache_path <- build_cache_path(end_year, cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear the caschooldata cache
#'
#' Removes all cached data files.
#'
#' @param end_year Optional. If provided, only clear cache for this year.
#'   If NULL (default), clears all cached data.
#' @param data_type Type of cache to clear: "enr" (enrollment), "grad" (graduation),
#'   or NULL (both).
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear all cached data
#' clear_enr_cache()
#'
#' # Clear only 2024 data
#' clear_enr_cache(2024)
#'
#' # Clear only graduation cache
#' clear_enr_cache(data_type = "grad")
#' }
clear_enr_cache <- function(end_year = NULL, data_type = NULL) {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  if (is.null(end_year)) {
    if (is.null(data_type)) {
      files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)
    } else {
      files <- list.files(cache_dir, pattern = paste0("^", data_type, "_"), full.names = TRUE)
    }
  } else {
    if (is.null(data_type)) {
      patterns <- paste0(c("enr", "grad"), "_", end_year)
      files <- unlist(lapply(patterns, function(p) {
        list.files(cache_dir, pattern = p, full.names = TRUE)
      }))
    } else {
      files <- list.files(cache_dir, pattern = paste0(data_type, "_", end_year), full.names = TRUE)
    }
  }

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached file(s)"))
  } else {
    message("No cached files to remove")
  }

  invisible(length(files))
}


#' Get cache status
#'
#' Reports which years have cached data available, including file sizes and ages.
#'
#' @return Data frame with cache information (invisibly). Columns include:
#'   \itemize{
#'     \item \code{end_year}: School year end
#'     \item \code{cache_type}: Type of cached data (tidy or wide)
#'     \item \code{size_mb}: File size in megabytes
#'     \item \code{age_days}: Days since file was created/modified
#'   }
#' @export
#' @examples
#' \dontrun{
#' cache_status()
#' }
cache_status <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache is empty")
    return(invisible(data.frame(
      end_year = integer(),
      data_type = character(),
      cache_type = character(),
      size_mb = numeric(),
      age_days = numeric(),
      stringsAsFactors = FALSE
    )))
  }

  files <- list.files(cache_dir, pattern = "\\.rds$", full.names = TRUE)

  if (length(files) == 0) {
    message("Cache is empty")
    return(invisible(data.frame(
      end_year = integer(),
      data_type = character(),
      cache_type = character(),
      size_mb = numeric(),
      age_days = numeric(),
      stringsAsFactors = FALSE
    )))
  }

  # Get file info
  info <- file.info(files)
  info$file <- basename(files)

  # Parse file names: enr_YYYY_type.rds OR grad_YYYY_type.rds
  parsed <- regmatches(info$file, regexec("^(enr|grad)_(\\d{4})_(\\w+)\\.rds$", info$file))

  result <- data.frame(
    end_year = as.integer(sapply(parsed, function(x) if (length(x) >= 3) x[3] else NA)),
    data_type = sapply(parsed, function(x) if (length(x) >= 2) x[2] else NA),
    cache_type = sapply(parsed, function(x) if (length(x) >= 4) x[4] else NA),
    size_mb = round(info$size / 1024 / 1024, 2),
    age_days = round(as.numeric(difftime(Sys.time(), info$mtime, units = "days")), 1),
    stringsAsFactors = FALSE
  )

  result <- result[order(result$data_type, result$end_year, result$cache_type), ]
  rownames(result) <- NULL

  print(result)
  invisible(result)
}
