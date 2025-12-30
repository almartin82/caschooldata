# caschooldata: Fetch and Process California School Data

The caschooldata package provides functions for downloading and
processing school data from the California Department of Education
(CDE). It offers a consistent, tidy interface for working with
California public school enrollment data.

## Main Functions

- [`fetch_enr`](https://almartin82.github.io/caschooldata/reference/fetch_enr.md):
  Download and process enrollment data

- [`fetch_enr_multi`](https://almartin82.github.io/caschooldata/reference/fetch_enr_multi.md):
  Download enrollment for multiple years

- [`tidy_enr`](https://almartin82.github.io/caschooldata/reference/tidy_enr.md):
  Convert wide enrollment to tidy format

- [`id_enr_aggs`](https://almartin82.github.io/caschooldata/reference/id_enr_aggs.md):
  Identify aggregation levels in data

- [`parse_cds_code`](https://almartin82.github.io/caschooldata/reference/parse_cds_code.md):
  Parse CDS codes into components

## Cache Functions

- [`cache_status`](https://almartin82.github.io/caschooldata/reference/cache_status.md):
  Check cached data status

- [`clear_enr_cache`](https://almartin82.github.io/caschooldata/reference/clear_enr_cache.md):
  Clear cached data

## Data Source

Data is sourced from the California Department of Education (CDE)
DataQuest: <https://dq.cde.ca.gov/dataquest/>

Enrollment data files are from the Census Day enrollment collection,
which provides a snapshot of enrollment on the first Wednesday in
October.

## CDS Codes

California uses a 14-digit County-District-School (CDS) code system:

- 2 digits: County code (01-58, representing California's 58 counties)

- 5 digits: District code

- 7 digits: School code

## See also

Useful links:

- <https://almartin82.github.io/caschooldata/>

- <https://github.com/almartin82/caschooldata>

- Report bugs at <https://github.com/almartin82/caschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
