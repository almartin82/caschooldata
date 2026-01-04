# Get available years for California enrollment data

Returns a vector of end years for which enrollment data is available
from the California Department of Education. This includes both modern
Census Day files (2024+) and historical enrollment files (1982-2023).

## Usage

``` r
get_available_years()
```

## Value

Integer vector of available end years (1982-2024)

## Examples

``` r
get_available_years()
#>  [1] 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996
#> [16] 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011
#> [31] 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024

# Check if a specific year is available
2024 %in% get_available_years()
#> [1] TRUE
```
