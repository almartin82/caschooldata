# Generate figures for README
# Showcases varied time horizons and data dimensions

devtools::load_all()
library(dplyr)
library(tidyr)
library(ggplot2)

fig_dir <- "man/figures"

# Theme for all plots
theme_readme <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank()
    )
}

# Fetch data for different time ranges
message("Fetching enrollment data...")
# Full historical range for long-term trends
enr_full <- fetch_enr_multi(c(1985, 1990, 1995, 2000, 2005, 2010, 2015, 2020, 2025))
# Recent years for detailed analysis
enr_recent <- fetch_enr_multi(2018:2025)

# Filter to aggregate totals only (modern Census Day files have separate rows for
# charter_status = ALL/N/Y which would cause double-counting if summed together)
enr_full <- enr_full %>%
  filter(charter_status %in% c("ALL", "All") | is.na(charter_status))
enr_recent <- enr_recent %>%
  filter(charter_status %in% c("ALL", "All") | is.na(charter_status))

# ------------------------------------------------------------------------------
# 1. THE 40-YEAR ARC (1985-2025) - Total enrollment
# ------------------------------------------------------------------------------
message("Creating 40-year enrollment arc...")

state_40yr <- enr_full %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA") %>%
  arrange(end_year)

p1 <- ggplot(state_40yr, aes(x = end_year, y = n_students / 1e6)) +
  geom_line(color = "#2563eb", linewidth = 1.5) +
  geom_point(color = "#2563eb", size = 4) +
  geom_area(alpha = 0.1, fill = "#2563eb") +
  annotate("text", x = 2003, y = 6.4, label = "Peak: 6.3M", size = 3.5, color = "gray30") +
  annotate("text", x = 2025, y = 5.6, label = "Now: 5.8M", size = 3.5, color = "gray30") +
  scale_x_continuous(breaks = seq(1985, 2025, 10)) +
  scale_y_continuous(limits = c(4, 6.8), labels = function(x) paste0(x, "M")) +
  labs(
    title = "California's 40-Year Enrollment Arc",
    subtitle = "Rise, peak, and decline of K-12 public school enrollment",
    x = NULL, y = NULL
  ) +
  theme_readme()

ggsave(file.path(fig_dir, "enrollment-40yr.png"), p1, width = 8, height = 4, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 2. DEMOGRAPHIC TRANSFORMATION (30 years, 1995-2025)
# ------------------------------------------------------------------------------
message("Creating demographic transformation chart...")

demo_30yr <- enr_full %>%
  filter(is_state, grade_level == "TOTAL", grepl("^RE_", reporting_category),
         end_year >= 1995) %>%
  group_by(end_year, subgroup) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  group_by(end_year) %>%
  mutate(pct = n_students / sum(n_students) * 100) %>%
  ungroup() %>%
  filter(subgroup %in% c("hispanic", "white", "asian"))

p2 <- ggplot(demo_30yr, aes(x = end_year, y = pct, color = subgroup)) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3) +
  geom_hline(yintercept = 50, linetype = "dashed", color = "gray50", alpha = 0.7) +
  annotate("text", x = 2018, y = 52, label = "50% threshold", size = 3, color = "gray50") +
  scale_color_manual(
    values = c("hispanic" = "#ea580c", "white" = "#2563eb", "asian" = "#16a34a"),
    labels = c("Hispanic", "White", "Asian")
  ) +
  scale_x_continuous(breaks = seq(1995, 2025, 5)) +
  scale_y_continuous(limits = c(0, 60), labels = function(x) paste0(x, "%")) +
  labs(
    title = "The Demographic Crossover",
    subtitle = "Hispanic students became the majority around 2010",
    x = NULL, y = NULL, color = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "demographics-30yr.png"), p2, width = 8, height = 5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 3. KINDERGARTEN vs 12TH GRADE (15 years, 2010-2025)
# ------------------------------------------------------------------------------
message("Creating K vs 12 comparison...")

k_vs_12 <- enr_full %>%
  filter(is_state, reporting_category == "TA", grade_level %in% c("K", "12"),
         end_year >= 2005) %>%
  select(end_year, grade_level, n_students) %>%
  group_by(end_year) %>%
  mutate(first_k = first(n_students[grade_level == "K"])) %>%
  ungroup() %>%
  group_by(grade_level) %>%
  mutate(index = n_students / first(n_students) * 100) %>%
  ungroup()

p3 <- ggplot(k_vs_12, aes(x = end_year, y = index, color = grade_level)) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3) +
  scale_color_manual(
    values = c("K" = "#ea580c", "12" = "#7c3aed"),
    labels = c("Kindergarten", "12th Grade")
  ) +
  scale_x_continuous(breaks = seq(2005, 2025, 5)) +
  labs(
    title = "Pipeline Preview: K Today, 12th Tomorrow",
    subtitle = "Kindergarten decline foreshadows future high school enrollment",
    x = NULL, y = "Enrollment Index (2005 = 100)", color = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "k-vs-12.png"), p3, width = 8, height = 4.5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 4. COVID IMPACT BY GRADE BAND (5 years, 2020-2025)
# ------------------------------------------------------------------------------
message("Creating COVID impact chart...")

covid_grades <- enr_recent %>%
  filter(is_state, reporting_category == "TA",
         grade_level %in% c("K", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")) %>%
  mutate(
    band = case_when(
      grade_level %in% c("K", "01", "02", "03", "04", "05") ~ "Elementary (K-5)",
      grade_level %in% c("06", "07", "08") ~ "Middle (6-8)",
      TRUE ~ "High (9-12)"
    )
  ) %>%
  group_by(end_year, band) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  filter(end_year >= 2019) %>%
  group_by(band) %>%
  mutate(
    change_from_2019 = (n_students - first(n_students)) / first(n_students) * 100
  )

p4 <- ggplot(covid_grades, aes(x = end_year, y = change_from_2019, fill = band)) +
  geom_col(position = "dodge", alpha = 0.85) +
  geom_hline(yintercept = 0, linewidth = 0.8) +
  scale_fill_manual(values = c("Elementary (K-5)" = "#16a34a", "Middle (6-8)" = "#ea580c", "High (9-12)" = "#7c3aed")) +
  scale_y_continuous(labels = function(x) paste0(ifelse(x > 0, "+", ""), x, "%")) +
  labs(
    title = "COVID's Uneven Impact by Grade Level",
    subtitle = "Change from 2018-19 baseline (pre-pandemic)",
    x = NULL, y = NULL, fill = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "covid-grades.png"), p4, width = 8, height = 4.5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 5. TOP 5 COUNTIES (8 years, 2018-2025)
# ------------------------------------------------------------------------------
message("Creating top counties chart...")

top5_counties <- enr_recent %>%
  filter(is_county, grade_level == "TOTAL", reporting_category == "TA", end_year == 2025) %>%
  arrange(desc(n_students)) %>%
  head(5) %>%
  pull(county_name)

county_trend <- enr_recent %>%
  filter(is_county, grade_level == "TOTAL", reporting_category == "TA",
         county_name %in% top5_counties) %>%
  group_by(end_year, county_name) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p5 <- ggplot(county_trend, aes(x = end_year, y = n_students / 1e6, color = county_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_brewer(palette = "Set1") +
  scale_y_continuous(labels = function(x) paste0(x, "M")) +
  labs(
    title = "California's Largest Counties",
    subtitle = "LA County alone has more students than most states",
    x = NULL, y = NULL, color = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "top-counties.png"), p5, width = 8, height = 5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 6. BAY AREA vs SOCAL (8 years)
# ------------------------------------------------------------------------------
message("Creating Bay Area vs SoCal chart...")

regional <- enr_recent %>%
  filter(is_county, grade_level == "TOTAL", reporting_category == "TA") %>%
  mutate(
    region = case_when(
      county_name %in% c("San Francisco", "Santa Clara", "Alameda", "San Mateo", "Contra Costa", "Marin") ~ "Bay Area",
      county_name %in% c("Los Angeles", "Orange", "San Diego") ~ "SoCal Metro",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(region)) %>%
  group_by(end_year, region) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  group_by(region) %>%
  mutate(index = n_students / first(n_students) * 100)

p6 <- ggplot(regional, aes(x = end_year, y = index, color = region)) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Bay Area" = "#dc2626", "SoCal Metro" = "#2563eb")) +
  labs(
    title = "Bay Area Exodus vs SoCal Stability",
    subtitle = "Indexed to 2018 = 100. Bay Area losing students faster.",
    x = NULL, y = "Enrollment Index", color = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "bayarea-socal.png"), p6, width = 8, height = 4.5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 7. GENDER BY GRADE LEVEL (latest year)
# ------------------------------------------------------------------------------
message("Creating gender by grade chart...")

gender_grade <- enr_recent %>%
  filter(is_state, end_year == 2025,
         reporting_category %in% c("GN_M", "GN_F"),
         grade_level %in% c("K", "03", "06", "09", "12")) %>%
  group_by(grade_level) %>%
  mutate(pct = n_students / sum(n_students) * 100) %>%
  ungroup() %>%
  mutate(grade_level = factor(grade_level, levels = c("K", "03", "06", "09", "12")))

p7 <- ggplot(gender_grade, aes(x = grade_level, y = pct, fill = subgroup)) +
  geom_col(position = "stack") +
  geom_hline(yintercept = 50, color = "white", linewidth = 1, linetype = "dashed") +
  scale_fill_manual(values = c("female" = "#ec4899", "male" = "#3b82f6"), labels = c("Female", "Male")) +
  scale_x_discrete(labels = c("K", "3rd", "6th", "9th", "12th")) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "Gender Balance Across Grade Levels",
    subtitle = "Slight male majority holds steady from K through 12th",
    x = NULL, y = NULL, fill = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "gender-grades.png"), p7, width = 8, height = 4.5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 8. STUDENT GROUPS (2024-2025 only)
# ------------------------------------------------------------------------------
message("Creating student groups chart...")

student_groups <- enr_recent %>%
  filter(is_state, grade_level == "TOTAL", grepl("^SG_", reporting_category), end_year == 2025) %>%
  group_by(subgroup) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  filter(n_students > 0) %>%
  arrange(desc(n_students)) %>%
  mutate(
    label = case_when(
      subgroup == "english_learner" ~ "English Learners",
      subgroup == "socioeconomically_disadvantaged" ~ "Low Income",
      subgroup == "students_with_disabilities" ~ "Students w/ Disabilities",
      subgroup == "homeless" ~ "Homeless",
      subgroup == "foster_youth" ~ "Foster Youth",
      subgroup == "migrant" ~ "Migrant",
      TRUE ~ subgroup
    ),
    label = factor(label, levels = rev(label))
  )

if (nrow(student_groups) > 0) {
  p8 <- ggplot(student_groups, aes(x = label, y = n_students / 1e6, fill = label)) +
    geom_col() +
    geom_text(aes(label = scales::comma(n_students)), hjust = -0.1, size = 3.5) +
    coord_flip() +
    scale_y_continuous(limits = c(0, max(student_groups$n_students) / 1e6 * 1.25),
                       labels = function(x) paste0(x, "M")) +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "Student Populations with Special Needs",
      subtitle = "3.5M+ low-income students, 1M+ English Learners",
      x = NULL, y = NULL
    ) +
    theme_readme() +
    theme(legend.position = "none")

  ggsave(file.path(fig_dir, "student-groups.png"), p8, width = 8, height = 5, dpi = 150, bg = "white")
}

# ------------------------------------------------------------------------------
# 9. LAUSD LONG-TERM DECLINE (20 years)
# ------------------------------------------------------------------------------
message("Creating LAUSD chart...")

lausd <- enr_full %>%
  filter(is_district, grepl("Los Angeles Unified", district_name, ignore.case = TRUE),
         grade_level == "TOTAL", reporting_category == "TA") %>%
  filter(!is.na(n_students)) %>%
  arrange(end_year)

if (nrow(lausd) > 0) {
  p9 <- ggplot(lausd, aes(x = end_year, y = n_students / 1000)) +
    geom_line(color = "#dc2626", linewidth = 1.5) +
    geom_point(color = "#dc2626", size = 3) +
    geom_area(alpha = 0.1, fill = "#dc2626") +
    scale_x_continuous(breaks = seq(1985, 2025, 10)) +
    scale_y_continuous(labels = function(x) paste0(x, "K")) +
    labs(
      title = "LAUSD: America's Shrinking Giant",
      subtitle = "From 700K+ to under 400K in two decades",
      x = NULL, y = NULL
    ) +
    theme_readme()

  ggsave(file.path(fig_dir, "lausd-longterm.png"), p9, width = 8, height = 4, dpi = 150, bg = "white")
}

# ------------------------------------------------------------------------------
# 10. RACE BY REGION (latest year)
# ------------------------------------------------------------------------------
message("Creating race by region chart...")

race_region <- enr_recent %>%
  filter(is_county, grade_level == "TOTAL", grepl("^RE_", reporting_category), end_year == 2025,
         subgroup %in% c("hispanic", "white", "asian", "black")) %>%
  mutate(
    region = case_when(
      county_name %in% c("San Francisco", "Santa Clara", "Alameda", "San Mateo") ~ "Bay Area",
      county_name == "Los Angeles" ~ "Los Angeles",
      county_name %in% c("Fresno", "Kern", "Tulare") ~ "Central Valley",
      county_name == "San Diego" ~ "San Diego",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(region)) %>%
  group_by(region, subgroup) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  group_by(region) %>%
  mutate(pct = n_students / sum(n_students) * 100) %>%
  ungroup()

p10 <- ggplot(race_region, aes(x = region, y = pct, fill = subgroup)) +
  geom_col(position = "stack") +
  scale_fill_manual(
    values = c("hispanic" = "#ea580c", "white" = "#3b82f6", "asian" = "#16a34a", "black" = "#7c3aed"),
    labels = c("Asian", "Black", "Hispanic", "White")
  ) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "California's Regional Diversity",
    subtitle = "Demographic mix varies dramatically by region",
    x = NULL, y = NULL, fill = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "race-by-region.png"), p10, width = 8, height = 5, dpi = 150, bg = "white")

message("Done! Figures saved to ", fig_dir)
