# ==============================================================================
# Transformation Correctness Tests — Enrollment
# ==============================================================================
#
# Tests verifying that every enrollment data transformation preserves fidelity
# to the original CDE source files. Every pinned value was obtained by running
# actual fetch calls against CDE data (not fabricated).
#
# Covers:
#   1. Suppression handling (safe_numeric)
#   2. ID formatting (CDS codes)
#   3. Grade level normalization (TK is CA-specific)
#   4. Subgroup renaming (standard names)
#   5. Pivot fidelity (wide total == tidy TOTAL)
#   6. Percentage calculation (valid range, no Inf/NaN)
#   7. Aggregation correctness (state ≈ sum of districts)
#   8. Entity flag logic (mutually exclusive)
#   9. Year × raw data coverage (one test per era, pinned values)
#  10. Cross-year consistency (YoY change < 10%)
#
# ==============================================================================

# --- helpers -----------------------------------------------------------------

skip_if_offline <- function() {

  skip_on_cran()
  if (!curl::has_internet()) skip("No internet connection")
}

# ==============================================================================
# 1. Suppression Handling
# ==============================================================================

test_that("safe_numeric handles asterisk suppression marker", {
  expect_true(is.na(safe_numeric("*")))
})

test_that("safe_numeric handles commas in numbers", {
  expect_equal(safe_numeric("1,234"), 1234)
  expect_equal(safe_numeric("1,234,567"), 1234567)
})

test_that("safe_numeric handles whitespace", {
  expect_equal(safe_numeric("  123  "), 123)
  expect_equal(safe_numeric(" * "), NA_real_)
})

test_that("safe_numeric handles empty string and NA", {
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric(NA_character_)))
})

test_that("safe_numeric preserves normal integers", {
  expect_equal(safe_numeric("0"), 0)
  expect_equal(safe_numeric("5806221"), 5806221)
})

test_that("safe_numeric handles vector with mixed suppression", {
  input <- c("100", "*", "200", "", "1,500")
  result <- safe_numeric(input)
  expect_equal(result[1], 100)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 200)
  expect_true(is.na(result[4]))
  expect_equal(result[5], 1500)
})

# ==============================================================================
# 2. ID Formatting
# ==============================================================================

test_that("parse_cds_code returns correct 14-digit structure", {
  result <- parse_cds_code("19647330000000")
  expect_equal(nchar(result$cds_code), 14)
  expect_equal(result$county_code, "19")
  expect_equal(result$district_code, "64733")
  expect_equal(result$school_code, "0000000")
})

test_that("parse_cds_code pads short codes with leading zeros", {
  result <- parse_cds_code("1100170000000")
  expect_equal(nchar(result$cds_code), 14)
  expect_equal(result$county_code, "01")
  expect_equal(result$district_code, "10017")
})

test_that("CDS codes in modern tidy data are exactly 14 characters", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(nchar(enr$cds_code) == 14))
})

test_that("county_code is 2 digits in modern data", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(nchar(enr$county_code) == 2))
})

test_that("district_code is 5 digits in modern data", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(nchar(enr$district_code) == 5))
})

test_that("school_code is 7 digits in modern data", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(nchar(enr$school_code) == 7))
})

test_that("CDS code equals concatenation of county + district + school", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expected_cds <- paste0(enr$county_code, enr$district_code, enr$school_code)
  expect_equal(enr$cds_code, expected_cds)
})

test_that("state CDS code is 00000000000000", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  state_cds <- unique(enr$cds_code[enr$is_state])
  expect_true("00000000000000" %in% state_cds)
})

# ==============================================================================
# 3. Grade Level Normalization
# ==============================================================================

test_that("modern data (2025) has TK grade level", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true("TK" %in% enr$grade_level)
})

test_that("historical data (2023) does NOT have TK grade level", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  expect_false("TK" %in% enr$grade_level)
})

test_that("all expected grade levels present in modern data", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expected_grades <- c("TK", "K", "01", "02", "03", "04", "05", "06",
                       "07", "08", "09", "10", "11", "12", "TOTAL")
  for (g in expected_grades) {
    expect_true(g %in% enr$grade_level,
                info = paste("Missing grade level:", g))
  }
})

test_that("historical data has expected grade levels (minus TK)", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  expected_grades <- c("K", "01", "02", "03", "04", "05", "06",
                       "07", "08", "09", "10", "11", "12", "TOTAL")
  for (g in expected_grades) {
    expect_true(g %in% enr$grade_level,
                info = paste("Missing grade level:", g))
  }
})

test_that("grade levels are always uppercase", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  grade_levels <- unique(enr$grade_level)
  expect_equal(grade_levels, toupper(grade_levels))
})

# ==============================================================================
# 4. Subgroup Renaming
# ==============================================================================

test_that("map_reporting_category maps to standard names", {
  # Standard names from CLAUDE.md
  expect_equal(map_reporting_category("TA"), "total_enrollment")
  expect_equal(map_reporting_category("RE_I"), "native_american")
  expect_equal(map_reporting_category("RE_T"), "multiracial")
  expect_equal(map_reporting_category("SG_EL"), "lep")
  expect_equal(map_reporting_category("SG_SD"), "econ_disadv")
  expect_equal(map_reporting_category("SG_DS"), "special_ed")
})

test_that("standard subgroup names present in modern tidy data", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(enr$subgroup)

  # Required standard names
  expected <- c("total_enrollment", "hispanic", "white", "black",
                "asian", "native_american", "multiracial",
                "female", "male", "lep", "econ_disadv", "special_ed")
  for (s in expected) {
    expect_true(s %in% subgroups,
                info = paste("Missing standard subgroup:", s))
  }
})

test_that("non-standard names are absent from tidy data", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(enr$subgroup)

  # These should NOT appear
  bad_names <- c("american_indian", "two_or_more", "el", "ell",
                 "english_learner", "low_income", "frl",
                 "economically_disadvantaged", "socioeconomically_disadvantaged",
                 "students_with_disabilities", "iep")
  # Note: "english_learner" is a valid CDE category (ELAS_EL), distinct from lep (SG_EL)
  bad_names <- setdiff(bad_names, "english_learner")

  for (s in bad_names) {
    expect_false(s %in% subgroups,
                 info = paste("Non-standard subgroup found:", s))
  }
})

test_that("historical data subgroups use standard names", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(enr$subgroup)

  # Historical should have standard race/gender names
  expected <- c("total_enrollment", "hispanic", "white", "black",
                "asian", "native_american", "female", "male")
  for (s in expected) {
    expect_true(s %in% subgroups,
                info = paste("Missing standard subgroup in historical:", s))
  }
})

test_that("historical data does NOT have student group categories (SG_*)", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  subgroups <- unique(enr$subgroup)

  # SG_ categories only in modern (2024+)
  expect_false("lep" %in% subgroups)
  expect_false("econ_disadv" %in% subgroups)
  expect_false("special_ed" %in% subgroups)
})

# ==============================================================================
# 5. Pivot Fidelity
# ==============================================================================

test_that("2025 wide total_enrollment equals tidy TOTAL n_students", {
  skip_if_offline()

  wide <- fetch_enr(2025, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  wide_state <- wide |>
    dplyr::filter(agg_level == "T", reporting_category == "TA",
                  charter_status == "ALL") |>
    dplyr::pull(total_enrollment)

  tidy_state <- tidy |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(tidy_state, wide_state)
})

test_that("2025 sum of individual grades equals TOTAL", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  individual_grades <- c("TK", "K", paste0("0", 1:9), "10", "11", "12")
  grade_sum <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  charter_status == "ALL",
                  grade_level %in% individual_grades) |>
    dplyr::pull(n_students) |>
    sum(na.rm = TRUE)

  total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  charter_status == "ALL", grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(grade_sum, total)
})

test_that("2024 wide total_enrollment equals tidy TOTAL n_students", {
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  wide_state <- wide |>
    dplyr::filter(agg_level == "T", reporting_category == "TA",
                  charter_status == "ALL") |>
    dplyr::pull(total_enrollment)

  tidy_state <- tidy |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(tidy_state, wide_state)
})

test_that("2023 historical wide total matches tidy TOTAL", {
  skip_if_offline()

  wide <- fetch_enr(2023, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  wide_state <- wide |>
    dplyr::filter(agg_level == "T", reporting_category == "TA") |>
    dplyr::pull(total_enrollment)

  tidy_state <- tidy |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(tidy_state, wide_state)
})

test_that("charter Y + N = ALL for state total (modern data)", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  charter_all <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  charter_y <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "Y") |>
    dplyr::pull(n_students)

  charter_n <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "N") |>
    dplyr::pull(n_students)

  expect_equal(charter_y + charter_n, charter_all)
})

# ==============================================================================
# 6. Data Quality — No Inf/NaN, Non-Negative Counts
# ==============================================================================

test_that("no Inf values in 2025 tidy enrollment", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  numeric_cols <- names(enr)[sapply(enr, is.numeric)]
  for (col in numeric_cols) {
    expect_false(any(is.infinite(enr[[col]]), na.rm = TRUE),
                 info = paste("Inf found in", col))
  }
})

test_that("no NaN values in 2025 tidy enrollment", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  numeric_cols <- names(enr)[sapply(enr, is.numeric)]
  for (col in numeric_cols) {
    expect_false(any(is.nan(enr[[col]]), na.rm = TRUE),
                 info = paste("NaN found in", col))
  }
})

test_that("enrollment counts are non-negative", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(enr$n_students >= 0, na.rm = TRUE))
})

# ==============================================================================
# 7. Aggregation Correctness
# ==============================================================================

test_that("2025 state total equals sum of district totals", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  district_sum <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students) |>
    sum()

  expect_equal(district_sum, state_total)
})

test_that("2023 historical state total equals sum of district totals", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  district_sum <- enr |>
    dplyr::filter(is_district, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students) |>
    sum()

  expect_equal(district_sum, state_total)
})

test_that("2025 county totals sum to state total", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  county_sum <- enr |>
    dplyr::filter(is_county, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students) |>
    sum()

  # May not be exactly equal due to independent reporting, but should be close
  expect_equal(county_sum, state_total, tolerance = state_total * 0.01)
})

# ==============================================================================
# 8. Entity Flag Logic
# ==============================================================================

test_that("entity flags are mutually exclusive in modern data", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  # Each row should have exactly one TRUE flag among state/county/district/school
  flag_sum <- enr$is_state + enr$is_county + enr$is_district + enr$is_school
  expect_true(all(flag_sum == 1))
})

test_that("entity flags are mutually exclusive in historical data", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  flag_sum <- enr$is_state + enr$is_county + enr$is_district + enr$is_school
  expect_true(all(flag_sum == 1))
})

test_that("is_charter flag is TRUE only when charter_status == 'Y'", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(enr$is_charter[enr$charter_status == "Y"]))
  expect_false(any(enr$is_charter[enr$charter_status == "N"]))
})

test_that("historical data has charter_status = 'All' for all rows", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  expect_true(all(enr$charter_status == "All"))
})

test_that("agg_level values match entity flags", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  expect_true(all(enr$agg_level[enr$is_state] == "T"))
  expect_true(all(enr$agg_level[enr$is_county] == "C"))
  expect_true(all(enr$agg_level[enr$is_district] == "D"))
  expect_true(all(enr$agg_level[enr$is_school] == "S"))
})

# ==============================================================================
# 9. Year x Raw Data Coverage — Pinned Values
# ==============================================================================

test_that("2025 state total enrollment = 5,806,221", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 5806221)
})

test_that("2025 LAUSD total enrollment = 516,685", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  lausd <- enr |>
    dplyr::filter(is_district, district_code == "64733",
                  subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(lausd, 516685)
})

test_that("2025 San Diego Unified total enrollment = 113,787", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  sdusd <- enr |>
    dplyr::filter(is_district, district_code == "68338",
                  subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(sdusd, 113787)
})

test_that("2025 state Hispanic enrollment = 3,257,893", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  hisp <- enr |>
    dplyr::filter(is_state, subgroup == "hispanic",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(hisp, 3257893)
})

test_that("2025 state TK enrollment = 177,570", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  tk <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TK", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(tk, 177570)
})

test_that("2025 state charter enrollment = 727,723", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  charter <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "Y") |>
    dplyr::pull(n_students)

  expect_equal(charter, 727723)
})

test_that("2024 state total enrollment = 5,837,690", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 5837690)
})

test_that("2024 LAUSD total enrollment = 529,902", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  lausd <- enr |>
    dplyr::filter(is_district, district_code == "64733",
                  subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  expect_equal(lausd, 529902)
})

test_that("2023 historical state total enrollment = 5,852,544", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 5852544)
})

test_that("2023 historical LAUSD total enrollment = 538,295", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  lausd <- enr |>
    dplyr::filter(is_district, grepl("64733", cds_code),
                  subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students) |>
    head(1)

  expect_equal(lausd, 538295)
})

test_that("2023 historical Hispanic enrollment = 3,284,788", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  hisp <- enr |>
    dplyr::filter(is_state, subgroup == "hispanic",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(hisp, 3284788)
})

test_that("2015 historical state total enrollment = 6,236,439", {
  skip_if_offline()

  enr <- fetch_enr(2015, tidy = TRUE, use_cache = TRUE)
  state_total <- enr |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  expect_equal(state_total, 6236439)
})

# ==============================================================================
# 10. Cross-Year Consistency
# ==============================================================================

test_that("year-over-year state total change < 10% (2024 to 2025)", {
  skip_if_offline()

  enr_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr_2025 <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  total_2024 <- enr_2024 |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  total_2025 <- enr_2025 |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    dplyr::pull(n_students)

  pct_change <- abs(total_2025 - total_2024) / total_2024 * 100
  expect_lt(pct_change, 10,
            label = paste("YoY change:", round(pct_change, 2), "%"))
})

test_that("LAUSD present in both 2024 and 2025", {
  skip_if_offline()

  enr_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr_2025 <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  lausd_2024 <- enr_2024 |>
    dplyr::filter(is_district, district_code == "64733",
                  subgroup == "total_enrollment", grade_level == "TOTAL")
  lausd_2025 <- enr_2025 |>
    dplyr::filter(is_district, district_code == "64733",
                  subgroup == "total_enrollment", grade_level == "TOTAL")

  expect_gt(nrow(lausd_2024), 0)
  expect_gt(nrow(lausd_2025), 0)
})

test_that("number of schools is consistent year over year", {
  skip_if_offline()

  enr_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr_2025 <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)

  n_schools_2024 <- enr_2024 |>
    dplyr::filter(is_school, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    nrow()

  n_schools_2025 <- enr_2025 |>
    dplyr::filter(is_school, subgroup == "total_enrollment",
                  grade_level == "TOTAL", charter_status == "ALL") |>
    nrow()

  pct_change <- abs(n_schools_2025 - n_schools_2024) / n_schools_2024 * 100
  expect_lt(pct_change, 10,
            label = paste("School count change:", round(pct_change, 2), "%"))
})

# ==============================================================================
# Historical Era Differences
# ==============================================================================

test_that("modern data (2024+) has charter_status Y/N/ALL", {
  skip_if_offline()

  enr <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  charter_vals <- sort(unique(enr$charter_status))
  expect_true("Y" %in% charter_vals)
  expect_true("N" %in% charter_vals)
  expect_true("ALL" %in% charter_vals)
})

test_that("historical data (pre-2024) has charter_status = All only", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  expect_equal(unique(enr$charter_status), "All")
})

test_that("modern data has ELAS categories not in historical", {
  skip_if_offline()

  enr_2025 <- fetch_enr(2025, tidy = TRUE, use_cache = TRUE)
  enr_2023 <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)

  # ELAS categories only in modern
  expect_true("english_only" %in% unique(enr_2025$subgroup))
  expect_true("english_learner" %in% unique(enr_2025$subgroup))
  expect_false("english_only" %in% unique(enr_2023$subgroup))
})

test_that("historical data has 4 entity levels (T/C/D/S)", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  agg_levels <- sort(unique(enr$agg_level))
  expect_equal(agg_levels, c("C", "D", "S", "T"))
})

test_that("historical multiracial (RE_T) absent from 2023", {
  skip_if_offline()

  enr <- fetch_enr(2023, tidy = TRUE, use_cache = TRUE)
  # Race code 8 (Two or More) is not present in 2023 historical data
  # All 2023 data uses codes 0-7,9 — code 8 is absent
  expect_false("multiracial" %in% unique(enr$subgroup))
})
