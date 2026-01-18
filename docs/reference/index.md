# Package index

## Fetch Data

Download enrollment data from CDE

- [`fetch_enr()`](https://almartin82.github.io/caschooldata/reference/fetch_enr.md)
  : Fetch California enrollment data
- [`fetch_enr_multi()`](https://almartin82.github.io/caschooldata/reference/fetch_enr_multi.md)
  : Fetch enrollment for multiple years
- [`fetch_graduation()`](https://almartin82.github.io/caschooldata/reference/fetch_graduation.md)
  : Fetch California graduation rate data
- [`fetch_graduation_multi()`](https://almartin82.github.io/caschooldata/reference/fetch_graduation_multi.md)
  : Fetch graduation rate data for multiple years
- [`fetch_assess()`](https://almartin82.github.io/caschooldata/reference/fetch_assess.md)
  : Fetch California CAASPP assessment data
- [`fetch_assess_multi()`](https://almartin82.github.io/caschooldata/reference/fetch_assess_multi.md)
  : Fetch CAASPP assessment data for multiple years
- [`get_available_years()`](https://almartin82.github.io/caschooldata/reference/get_available_years.md)
  : Get available years for California enrollment data
- [`get_available_grad_years()`](https://almartin82.github.io/caschooldata/reference/get_available_grad_years.md)
  : Get available graduation years
- [`get_available_assess_years()`](https://almartin82.github.io/caschooldata/reference/get_available_assess_years.md)
  : Get available CAASPP assessment years
- [`get_raw_assess()`](https://almartin82.github.io/caschooldata/reference/get_raw_assess.md)
  : Get raw CAASPP assessment data
- [`import_local_assess()`](https://almartin82.github.io/caschooldata/reference/import_local_assess.md)
  : Import locally downloaded CAASPP assessment files

## Process & Tidy

Transform data into analysis-ready formats

- [`tidy_enr()`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md)
  : Convert enrollment data to tidy format
- [`tidy_assess()`](https://almartin82.github.io/caschooldata/reference/tidy_assess.md)
  : Tidy CAASPP assessment data
- [`process_assess()`](https://almartin82.github.io/caschooldata/reference/process_assess.md)
  : Process raw CAASPP assessment data
- [`id_enr_aggs()`](https://almartin82.github.io/caschooldata/reference/id_enr_aggs.md)
  : Identify aggregation rows in enrollment data
- [`id_assess_aggs()`](https://almartin82.github.io/caschooldata/reference/id_assess_aggs.md)
  : Identify assessment aggregations
- [`enr_grade_aggs()`](https://almartin82.github.io/caschooldata/reference/enr_grade_aggs.md)
  : Create grade-level aggregates
- [`parse_cds_code()`](https://almartin82.github.io/caschooldata/reference/parse_cds_code.md)
  : Parse CDS code into components
- [`calc_assess_trend()`](https://almartin82.github.io/caschooldata/reference/calc_assess_trend.md)
  : Calculate assessment trends over time
- [`summarize_proficiency()`](https://almartin82.github.io/caschooldata/reference/summarize_proficiency.md)
  : Calculate assessment proficiency summary

## Print Methods

Print methods for data objects

- [`print(`*`<ca_assess_data>`*`)`](https://almartin82.github.io/caschooldata/reference/print.ca_assess_data.md)
  : Print CAASPP assessment data
- [`print(`*`<ca_assess_tidy>`*`)`](https://almartin82.github.io/caschooldata/reference/print.ca_assess_tidy.md)
  : Print tidy CAASPP assessment data

## Cache Management

Manage locally cached data

- [`cache_status()`](https://almartin82.github.io/caschooldata/reference/cache_status.md)
  : Get cache status
- [`clear_enr_cache()`](https://almartin82.github.io/caschooldata/reference/clear_enr_cache.md)
  : Clear the caschooldata cache
- [`clear_grad_cache()`](https://almartin82.github.io/caschooldata/reference/clear_grad_cache.md)
  : Clear graduation rate cache
