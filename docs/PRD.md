# caschooldata - Product Requirements Document

## Overview

**caschooldata** is an R package for fetching and processing school data from the California Department of Education (CDE). It provides a consistent, tidy interface for working with California public school enrollment data, demographics, and related datasets.

## Data Source

### California Department of Education (CDE) DataQuest
- **Primary URL**: https://dq.cde.ca.gov/dataquest/
- **Data Files**: https://www.cde.ca.gov/ds/
- **Organization**: California Department of Education
- **Update Frequency**: Annual (typically released in fall for prior school year)

## Identifier System

### CDS (County-District-School) Code
California uses a 14-digit CDS code system:
- **2 digits**: County code (01-58, representing California's 58 counties)
- **5 digits**: District code
- **7 digits**: School code

**Example**: `01611920130229`
- County: `01` (Alameda County)
- District: `61192` (Alameda Unified)
- School: `0130229` (specific school)

**Aggregation Levels**:
- State level: All zeros or specific state code
- County level: District and school portions are zeros
- District level: School portion is zeros
- School level: Full 14-digit code

## Scale

- **Counties**: 58
- **Districts**: ~2,061 (includes unified, elementary, high school, and other types)
- **Schools**: ~10,000+ public schools
- **Charter Schools**: ~1,300+

## Key Data Files

### Tier 1: Core Enrollment Data (Priority)

1. **Enrollment by Grade**
   - Source: https://www.cde.ca.gov/ds/ad/filesenr.asp
   - Grades: K-12 plus ungraded/adult education
   - Granularity: School level
   - Historical: 1981-present
   - **OPSC/SFP Forcing Function**: Office of Public School Construction / School Facility Program requires enrollment projections for modernization and new construction funding. This creates a strong incentive for accurate enrollment forecasting.

2. **Enrollment by Demographics**
   - Race/ethnicity breakdowns
   - English Learner status
   - Free/Reduced Price Meals eligibility
   - Migrant status

### Tier 2: Supplementary Data

3. **School Directory**
   - CDS codes, names, addresses
   - School types (elementary, middle, high, K-8, etc.)
   - Charter status
   - Virtual/non-classroom-based status

4. **District Directory**
   - District types (unified, elementary, high school, county office)
   - Contact information
   - Geographic boundaries

5. **Staff Demographics**
   - Teacher counts
   - Credentials and experience

### Tier 3: Extended Data

6. **Academic Performance**
   - CAASPP (California Assessment of Student Performance and Progress)
   - Dashboard indicators

7. **Graduation/Dropout Rates**
   - 4-year and 5-year cohort rates
   - By demographic subgroups

## Technical Requirements

### Data Access Patterns

CDE provides data primarily as downloadable files:
- **Format**: Text files (tab-delimited), Excel files
- **Access**: Direct download URLs with consistent naming patterns
- **No API**: Unlike some states, CDE does not provide a public API

### File Naming Conventions

Enrollment files typically follow patterns like:
- `enr{YY}.txt` or `enr{YYYY}.txt` for enrollment
- Files are academic year based (e.g., 2023-24 school year)

### Data Processing Pipeline

```
fetch_enr()
    |
    v
get_raw_enr() --> download raw file from CDE
    |
    v
process_enr() --> standardize column names, types, handle historical format changes
    |
    v
tidy_enr() --> pivot to long format with subgroup column
    |
    v
cache results --> store processed data for quick retrieval
```

## Caching Strategy

- Cache location: `rappdirs::user_cache_dir("caschooldata")`
- Cache invalidation: Manual or time-based
- Formats cached: Both wide and tidy versions

## API Design

### Primary Function

```r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

**Parameters**:
- `end_year`: Integer. The ending year of the school year (e.g., 2024 for 2023-24)
- `tidy`: Logical. Return long format (TRUE) or wide format (FALSE)
- `use_cache`: Logical. Use cached data if available (TRUE) or force fresh download (FALSE)

**Returns**: A tibble with enrollment data

### Column Schema (Tidy Format)

| Column | Type | Description |
|--------|------|-------------|
| cds_code | character | 14-digit CDS identifier |
| county_code | character | 2-digit county code |
| district_code | character | 5-digit district code |
| school_code | character | 7-digit school code |
| end_year | integer | Academic year end (e.g., 2024) |
| grade | character | Grade level (K, 01-12, UG) |
| subgroup | character | Demographic category |
| enrollment | integer | Student count |

## Historical Data Considerations

- **Format changes**: CDE has modified file formats over time
- **Code changes**: Some schools/districts have been reorganized
- **Coverage**: Earlier years may have less granular demographic data

## Dependencies

- `dplyr`: Data manipulation
- `readr`: Reading text files
- `readxl`: Reading Excel files (some CDE files)
- `stringr`: String manipulation for CDS codes
- `tidyr`: Pivoting and reshaping
- `downloader`: Robust file downloads
- `rappdirs`: Cross-platform cache directory

## Future Enhancements

1. **Additional data types**: Staff data, test scores, graduation rates
2. **Forecasting integration**: Cohort survival analysis for enrollment projections
3. **Geographic data**: School boundary integration
4. **Comparison tools**: Cross-district and cross-year analysis helpers

## References

- CDE DataQuest: https://dq.cde.ca.gov/dataquest/
- CDE Data & Statistics: https://www.cde.ca.gov/ds/
- CDS Code Structure: https://www.cde.ca.gov/ds/si/ds/
- OPSC SFP Program: https://www.dgs.ca.gov/OPSC/Resources/Page-Content/Office-of-Public-School-Construction-Resources-List-Folder/School-Facility-Program
