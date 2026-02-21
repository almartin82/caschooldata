## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---

## Valid Filter Values (tidy enrollment via `fetch_enr(tidy = TRUE)`)

### subgroup
California uses CDE `reporting_category` codes mapped to human-readable subgroup names via `map_reporting_category()`:

**Total:** `total` (code: `TA`)

**Race/Ethnicity:** `asian` (`RE_A`), `black` (`RE_B`), `not_reported` (`RE_D`), `filipino` (`RE_F`), `hispanic` (`RE_H`), `native_american` (`RE_I`), `pacific_islander` (`RE_P`), `multiracial` (`RE_T`), `white` (`RE_W`)

**Gender:** `female` (`GN_F`), `male` (`GN_M`), `nonbinary` (`GN_X`), `gender_missing` (`GN_Z`)

**Student Groups:** `english_learner` (`SG_EL`), `students_with_disabilities` (`SG_DS`), `socioeconomically_disadvantaged` (`SG_SD`), `migrant` (`SG_MG`), `foster_youth` (`SG_FS`), `homeless` (`SG_HM`)

**English Language Acquisition Status:** `adult_el` (`ELAS_ADEL`), `english_learner` (`ELAS_EL`), `english_only` (`ELAS_EO`), `initial_fluent_english` (`ELAS_IFEP`), `elas_missing` (`ELAS_MISS`), `reclassified_fluent_english` (`ELAS_RFEP`), `elas_to_be_determined` (`ELAS_TBD`)

**Age Ranges:** `age_0_3` (`AR_03`), `age_4_18` (`AR_0418`), `age_19_22` (`AR_1922`), `age_23_29` (`AR_2329`), `age_30_39` (`AR_3039`), `age_40_49` (`AR_4049`), `age_50_plus` (`AR_50P`)

**Common trap:** California has both `subgroup` (human-readable) and `reporting_category` (raw code) columns. Filter on `subgroup`, not `reporting_category`. Also, `filipino` is a separate category from `asian`.

### grade_level
`TK`, `K`, `01`, `02`, `03`, `04`, `05`, `06`, `07`, `08`, `09`, `10`, `11`, `12`, `TOTAL`

Grade aggregates from `enr_grade_aggs()`: `K8` (includes TK), `HS`, `K12` (includes TK)

**Common trap:** California has Transitional Kindergarten (`TK`) as a separate grade level. This is NOT the same as `K`. `K8` and `K12` aggregates include `TK`.

### entity flags
`is_state`, `is_county`, `is_district`, `is_school`, `is_charter`

- `is_state`: `agg_level == "T"`
- `is_county`: `agg_level == "C"`
- `is_district`: `agg_level == "D"`
- `is_school`: `agg_level == "S"`
- `is_charter`: `charter_status == "Y"`

**Common trap:** California has a `is_county` level that most other states do not. Also uses `is_school` (not `is_campus`).

---


# Claude Code Instructions

## GIT COMMIT POLICY
- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them
- Keep commit messages focused on what changed, not how it was written

---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pycaschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pycaschooldata && pytest tests/test_pycaschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pycaschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

## README Images from Vignettes (REQUIRED)

**NEVER use `man/figures/` or `generate_readme_figs.R` for README images.**

README images MUST come from pkgdown-generated vignette output so they auto-update on merge:

```markdown
![Chart name](https://almartin82.github.io/{package}/articles/{vignette}_files/figure-html/{chunk-name}-1.png)
```

**Why:** Vignette figures regenerate automatically when pkgdown builds. Manual `man/figures/` requires running a separate script and is easy to forget, causing stale/broken images.
