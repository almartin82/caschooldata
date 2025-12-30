# Generate figures for README
# Run this script to regenerate the charts

devtools::load_all()
library(dplyr)
library(tidyr)
library(ggplot2)

# Set output directory
fig_dir <- "man/figures"

# Fetch all data
message("Fetching enrollment data...")
enr <- fetch_enr_multi(2018:2025)

# Theme for all plots
theme_readme <- function() {

theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank()
    )
}

# ------------------------------------------------------------------------------
# 1. Statewide decline
# ------------------------------------------------------------------------------
message("Creating statewide trend chart...")

state_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", reporting_category == "TA") %>%
  arrange(end_year) %>%
  filter(!is.na(n_students))

p1 <- ggplot(state_trend, aes(x = end_year, y = n_students / 1e6)) +
  geom_line(color = "#2563eb", linewidth = 1.5) +
  geom_point(color = "#2563eb", size = 3) +
  geom_area(alpha = 0.1, fill = "#2563eb") +
  scale_y_continuous(labels = function(x) paste0(x, "M")) +
  labs(
    title = "California Lost 400,000+ Students Since 2020",
    subtitle = "K-12 public school enrollment, 2017-18 through 2024-25",
    x = NULL, y = NULL
  ) +
  theme_readme()

ggsave(file.path(fig_dir, "enrollment-trend.png"), p1, width = 8, height = 4, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 2. LAUSD decline
# ------------------------------------------------------------------------------
message("Creating LAUSD chart...")

lausd <- enr %>%
  filter(
    is_district,
    grade_level == "TOTAL",
    reporting_category == "TA",
    grepl("Los Angeles Unified", district_name, ignore.case = TRUE)
  ) %>%
  arrange(end_year) %>%
  filter(!is.na(n_students))

p2 <- ggplot(lausd, aes(x = end_year, y = n_students / 1000)) +
  geom_col(fill = "#dc2626", alpha = 0.8) +
  geom_text(aes(label = paste0(round(n_students/1000), "K")), vjust = -0.5, size = 3.5) +
  scale_y_continuous(limits = c(0, max(lausd$n_students, na.rm = TRUE) / 1000 * 1.15), labels = function(x) paste0(x, "K")) +
  labs(
    title = "LAUSD: A District in Freefall",
    subtitle = "Los Angeles Unified enrollment has dropped every single year",
    x = NULL, y = NULL
  ) +
  theme_readme()

ggsave(file.path(fig_dir, "lausd-trend.png"), p2, width = 8, height = 4, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 3. Top 5 districts
# ------------------------------------------------------------------------------
message("Creating top 5 districts chart...")

top5_names <- enr %>%
  filter(is_district, end_year == max(end_year), grade_level == "TOTAL", reporting_category == "TA") %>%
  arrange(desc(n_students)) %>%
  head(5) %>%
  pull(district_name)

top5 <- enr %>%
  filter(is_district, grade_level == "TOTAL", reporting_category == "TA", district_name %in% top5_names) %>%
  filter(!is.na(n_students)) %>%
  mutate(district_short = gsub(" Unified.*| School District.*", "", district_name))

p3 <- ggplot(top5, aes(x = end_year, y = n_students / 1000, color = district_short)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_brewer(palette = "Set1") +
  scale_y_continuous(labels = function(x) paste0(x, "K")) +
  labs(
    title = "California's Big 5 Districts Are All Shrinking",
    subtitle = "Combined loss exceeds 100,000 students",
    x = NULL, y = NULL, color = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "top5-districts.png"), p3, width = 8, height = 5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 4. Demographics
# ------------------------------------------------------------------------------
message("Creating demographics chart...")

race_latest <- enr %>%
  filter(is_state, grade_level == "TOTAL", grepl("^RE_", reporting_category), end_year == max(end_year)) %>%
  group_by(subgroup) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  mutate(pct = n_students / sum(n_students) * 100) %>%
  arrange(desc(pct)) %>%
  mutate(subgroup = factor(subgroup, levels = rev(unique(subgroup))))

p4 <- ggplot(race_latest, aes(x = subgroup, y = pct, fill = subgroup)) +
  geom_col() +
  geom_text(aes(label = sprintf("%.0f%%", pct)), hjust = -0.2, size = 3.5) +
  coord_flip() +
  scale_y_continuous(limits = c(0, 65)) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Hispanic Students Are Now the Majority",
    subtitle = "Race/ethnicity breakdown of California public school students",
    x = NULL, y = "Percent"
  ) +
  theme_readme() +
  theme(legend.position = "none")

ggsave(file.path(fig_dir, "demographics.png"), p4, width = 8, height = 5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 5. Winners and losers
# ------------------------------------------------------------------------------
message("Creating district changes chart...")

district_change <- enr %>%
  filter(is_district, grade_level == "TOTAL", reporting_category == "TA", end_year %in% c(2020, 2025)) %>%
  group_by(district_name, county_name, end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = end_year, values_from = n_students, names_prefix = "y") %>%
  filter(!is.na(y2020), y2020 > 2000) %>%
  mutate(pct_change = (y2025 - y2020) / y2020 * 100) %>%
  arrange(pct_change)

top_growers <- head(arrange(district_change, desc(pct_change)), 8)
top_decliners <- head(district_change, 8)
extremes <- bind_rows(
  mutate(top_decliners, type = "Biggest Declines"),
  mutate(top_growers, type = "Biggest Growth")
) %>%
  mutate(district_short = gsub(" Unified.*| School District.*| Elementary.*", "", district_name))

p5 <- ggplot(extremes, aes(x = reorder(district_short, pct_change), y = pct_change, fill = pct_change > 0)) +
  geom_col() +
  geom_text(aes(label = sprintf("%+.0f%%", pct_change), hjust = ifelse(pct_change > 0, -0.1, 1.1)), size = 3) +
  coord_flip() +
  scale_fill_manual(values = c("TRUE" = "#16a34a", "FALSE" = "#dc2626")) +
  labs(
    title = "Tale of Two Californias",
    subtitle = "Some districts grew 20%+ while others lost a quarter of students (2020-2025)",
    x = NULL, y = "Percent change"
  ) +
  theme_readme() +
  theme(legend.position = "none")

ggsave(file.path(fig_dir, "district-changes.png"), p5, width = 8, height = 6, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 6. Grade bands
# ------------------------------------------------------------------------------
message("Creating grade bands chart...")

grade_bands <- enr %>%
  filter(is_state, reporting_category == "TA", grade_level %in% c("K", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")) %>%
  mutate(
    band = case_when(
      grade_level %in% c("K", "01", "02", "03", "04", "05") ~ "Elementary (K-5)",
      grade_level %in% c("06", "07", "08") ~ "Middle (6-8)",
      TRUE ~ "High (9-12)"
    )
  ) %>%
  group_by(end_year, band) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  group_by(band) %>%
  mutate(index = n_students / first(n_students) * 100)

p6 <- ggplot(grade_bands, aes(x = end_year, y = index, color = band)) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("Elementary (K-5)" = "#16a34a", "Middle (6-8)" = "#ea580c", "High (9-12)" = "#7c3aed")) +
  labs(
    title = "High School Enrollment Dropped First",
    subtitle = "Indexed to 2018 = 100. The decline started at the top and is working down.",
    x = NULL, y = "Index (2018 = 100)", color = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "grade-bands.png"), p6, width = 8, height = 4.5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 7. Bay Area
# ------------------------------------------------------------------------------
message("Creating county changes chart...")

county_change <- enr %>%
  filter(is_county, grade_level == "TOTAL", reporting_category == "TA", end_year %in% c(2020, 2025)) %>%
  group_by(county_name, end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = end_year, values_from = n_students, names_prefix = "y") %>%
  filter(!is.na(y2020)) %>%
  mutate(
    pct_change = (y2025 - y2020) / y2020 * 100,
    region = case_when(
      county_name %in% c("San Francisco", "Santa Clara", "Alameda", "San Mateo", "Contra Costa", "Marin") ~ "Bay Area",
      county_name %in% c("Los Angeles", "Orange", "San Diego", "Riverside", "San Bernardino") ~ "SoCal Metro",
      TRUE ~ "Other"
    )
  ) %>%
  arrange(pct_change)

p7 <- ggplot(county_change, aes(x = pct_change, fill = region)) +
  geom_histogram(bins = 25, color = "white", alpha = 0.85) +
  geom_vline(xintercept = 0, linetype = "dashed", linewidth = 1) +
  scale_fill_manual(values = c("Bay Area" = "#dc2626", "SoCal Metro" = "#2563eb", "Other" = "#9ca3af")) +
  labs(
    title = "The Bay Area Exodus",
    subtitle = "Bay Area counties cluster at the far left—the biggest percentage losses",
    x = "Enrollment change 2020-2025 (%)", y = "Number of counties", fill = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "county-changes.png"), p7, width = 8, height = 4.5, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 8. Kindergarten
# ------------------------------------------------------------------------------
message("Creating kindergarten chart...")
k_trend <- enr %>%
  filter(is_state, reporting_category == "TA", grade_level == "K") %>%
  arrange(end_year)

p8 <- ggplot(k_trend, aes(x = end_year, y = n_students / 1000)) +
  geom_line(color = "#ea580c", linewidth = 1.5) +
  geom_point(color = "#ea580c", size = 3) +
  geom_area(alpha = 0.15, fill = "#ea580c") +
  scale_y_continuous(labels = function(x) paste0(x, "K")) +
  labs(
    title = "Kindergarten: The Canary in the Coal Mine",
    subtitle = "Today's K enrollment predicts tomorrow's total enrollment",
    x = NULL, y = NULL
  ) +
  theme_readme()

ggsave(file.path(fig_dir, "kindergarten.png"), p8, width = 8, height = 4, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 9. Gender stability
# ------------------------------------------------------------------------------
message("Creating gender chart...")

gender <- enr %>%
  filter(is_state, grade_level == "TOTAL", reporting_category %in% c("GN_F", "GN_M")) %>%
  group_by(end_year) %>%
  mutate(pct = n_students / sum(n_students) * 100) %>%
  ungroup()

p9 <- ggplot(gender, aes(x = end_year, y = pct, fill = subgroup)) +
  geom_area(alpha = 0.8) +
  geom_hline(yintercept = 50, color = "white", linewidth = 1, linetype = "dashed") +
  scale_fill_manual(values = c("female" = "#ec4899", "male" = "#3b82f6"), labels = c("Female", "Male")) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "One Thing That Hasn't Changed: Gender Ratio",
    subtitle = "Male/female split has held steady at ~51/49 through all the turbulence",
    x = NULL, y = NULL, fill = NULL
  ) +
  theme_readme() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "gender.png"), p9, width = 8, height = 4, dpi = 150, bg = "white")

# ------------------------------------------------------------------------------
# 10. English Learners (2024+ only)
# ------------------------------------------------------------------------------
message("Creating student groups chart...")

student_groups <- enr %>%
  filter(is_state, grade_level == "TOTAL", grepl("^SG_", reporting_category), end_year == max(end_year)) %>%
  group_by(subgroup) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(n_students)) %>%
  mutate(
    subgroup_label = case_when(
      subgroup == "english_learner" ~ "English Learners",
      subgroup == "socioeconomically_disadvantaged" ~ "Low Income",
      subgroup == "students_with_disabilities" ~ "Students w/ Disabilities",
      subgroup == "homeless" ~ "Homeless",
      subgroup == "foster_youth" ~ "Foster Youth",
      subgroup == "migrant" ~ "Migrant",
      TRUE ~ subgroup
    ),
    subgroup_label = factor(subgroup_label, levels = rev(unique(subgroup_label)))
  )

if (nrow(student_groups) > 0) {
  p10 <- ggplot(student_groups, aes(x = subgroup_label, y = n_students / 1e6, fill = subgroup_label)) +
    geom_col() +
    geom_text(aes(label = scales::comma(n_students)), hjust = -0.1, size = 3.5) +
    coord_flip() +
    scale_y_continuous(limits = c(0, max(student_groups$n_students) / 1e6 * 1.3), labels = function(x) paste0(x, "M")) +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "1 in 5 Students is an English Learner",
      subtitle = "Student group populations reveal the diversity of needs in CA schools",
      x = NULL, y = "Students"
    ) +
    theme_readme() +
    theme(legend.position = "none")

  ggsave(file.path(fig_dir, "student-groups.png"), p10, width = 8, height = 5, dpi = 150, bg = "white")
}

message("Done! Figures saved to ", fig_dir)
