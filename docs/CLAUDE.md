# Claude Code Instructions for caschooldata

## Commit and PR Guidelines

- Do NOT include “Generated with Claude Code” in commit messages
- Do NOT include “Co-Authored-By: Claude” in commit messages
- Do NOT mention Claude or AI assistance in PR descriptions
- Keep commit messages clean and professional

## Project Context

This is an R package for fetching and processing California school
enrollment data from CDE (California Department of Education).

### Key Files

- `R/fetch_enrollment.R` - Main
  [`fetch_enr()`](https://almartin82.github.io/caschooldata/reference/fetch_enr.md)
  function
- `R/get_raw_enrollment.R` - Downloads raw data from CDE
- `R/process_enrollment.R` - Transforms raw data to standard schema
- `R/tidy_enrollment.R` - Converts to long/tidy format
- `R/cache.R` - Local caching layer

### Data Sources

Data comes from the California Department of Education: - DataQuest:
<https://dq.cde.ca.gov/dataquest/> - Data files:
<https://www.cde.ca.gov/ds/> - Census Day enrollment (first Wednesday in
October) - Currently supports 2024-2025 data files

### CDS Code Format

California uses a 14-digit County-District-School (CDS) code: - 2
digits: County code (01-58, California’s 58 counties) - 5 digits:
District code - 7 digits: School code - Example: 01611920130229

### Related Package

This package follows patterns from
[ilschooldata](https://github.com/almartin82/ilschooldata).
