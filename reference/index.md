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
- [`get_available_years()`](https://almartin82.github.io/caschooldata/reference/get_available_years.md)
  : Get available years for California enrollment data
- [`get_available_grad_years()`](https://almartin82.github.io/caschooldata/reference/get_available_grad_years.md)
  : Get available graduation years

## Process & Tidy

Transform data into analysis-ready formats

- [`tidy_enr()`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md)
  : Convert enrollment data to tidy format
- [`id_enr_aggs()`](https://almartin82.github.io/caschooldata/reference/id_enr_aggs.md)
  : Identify aggregation rows in enrollment data
- [`enr_grade_aggs()`](https://almartin82.github.io/caschooldata/reference/enr_grade_aggs.md)
  : Create grade-level aggregates
- [`parse_cds_code()`](https://almartin82.github.io/caschooldata/reference/parse_cds_code.md)
  : Parse CDS code into components

## Cache Management

Manage locally cached data

- [`cache_status()`](https://almartin82.github.io/caschooldata/reference/cache_status.md)
  : Get cache status
- [`clear_enr_cache()`](https://almartin82.github.io/caschooldata/reference/clear_enr_cache.md)
  : Clear the caschooldata cache
- [`clear_grad_cache()`](https://almartin82.github.io/caschooldata/reference/clear_grad_cache.md)
  : Clear graduation rate cache
