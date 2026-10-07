# scripts/05_make_figures.R
#
# Saves a copy of the dashboard's two figures as they look when the
# dashboard first opens (towns of similar population, road upkeep
# spending), so a reader can compare their own run against output/.
# Also records the version of R and of each package.
#
# Run from the project folder: open ewing-public-works-dashboard.Rproj first.
# Reads:  output/dollars_per_mile.csv   (made by 04_join_and_check.R)
# Writes: output/figure1_rank.png
#         output/figure2_trend.png
#         docs/session_info.txt

# Load packages, functions and data ----------------------------------------

library(tidyverse)
source("scripts/figure_functions.R")

per_mile <- read_csv(
  "output/dollars_per_mile.csv",
  col_types = cols(
    muni_code = col_character(),
    municipality = col_character(),
    county = col_character(),
    town_label = col_character(),
    measure = col_character(),
    similar_population = col_logical(),
    .default = col_double()
  )
)

# Every town with a usable number, all measures and years.
usable <- per_mile |>
  filter(!is.na(dollars_per_mile))

# Figure 1: road upkeep spending, 2022 --------------------------------------

words <- measure_words |>
  filter(measure == road_upkeep)

road_rows <- usable |>
  filter(measure == road_upkeep)

road_year <- max(road_rows$year)

rank_rows <- road_rows |>
  filter(similar_population)

group_median <- median(rank_rows$dollars_per_mile)
state_median <- median(road_rows$dollars_per_mile)

nrow(rank_rows) # towns of similar population with a reported figure
nrow(road_rows) # all New Jersey towns with a reported figure
group_median
state_median

figure1 <- plot_rank(
  rank_rows,
  group_median = group_median,
  state_median = state_median,
  group_name = "towns of similar population",
  title = paste0("Ewing and towns of similar population, ", road_year),
  subtitle = words$subtitle,
  x_label = words$axis_label,
  state_name = paste("all NJ towns", words$towns_with),
  caption = paste0(
    "Sources: U.S. Census Bureau, 2022 Census of Governments, individual ",
    "unit file (reported values only);\n",
    "NJDOT Mileage by Municipality and Jurisdiction (March 2019)."
  )
)

ggsave(
  "output/figure1_rank.png",
  figure1,
  width = 9, height = 9, dpi = 150, bg = "white"
)

# Figure 2: the public works budget over time -------------------------------

# Actual road spending for every town exists for one year only, so the
# figure over time uses the broader budget measure.
trend_measure <- "Public works, budgeted"

trend_words <- measure_words |>
  filter(measure == trend_measure)

budget_rows <- usable |>
  filter(measure == trend_measure)

trend_rows <- bind_rows(
  budget_rows |>
    filter(muni_code == ewing_code) |>
    mutate(line = "Ewing township") |>
    select(year, line, dollars_per_mile),
  budget_rows |>
    filter(similar_population) |>
    group_by(year) |>
    summarize(dollars_per_mile = median(dollars_per_mile)) |>
    mutate(line = "Similar-size towns (median)"),
  budget_rows |>
    group_by(year) |>
    summarize(dollars_per_mile = median(dollars_per_mile)) |>
    mutate(line = "All NJ towns (median)")
)

trend_rows |>
  pivot_wider(names_from = line, values_from = dollars_per_mile) |>
  print(n = Inf)

figure2 <- plot_trend(
  trend_rows,
  title = "The budget over time, 2016 to 2026",
  subtitle = paste0(
    trend_words$subtitle, ", not adjusted for inflation"
  ),
  y_label = trend_words$axis_label,
  caption = paste0(
    "Sources: NJ DCA User Friendly Budget Database (file dated Sept. 1, ",
    "2026);\n",
    "NJDOT Mileage by Municipality and Jurisdiction (March 2019)."
  )
)

ggsave(
  "output/figure2_trend.png",
  figure2,
  width = 9, height = 5.5, dpi = 150, bg = "white"
)

# Record the R version and package versions ---------------------------------

# Every package the project uses, including the ones only app.R or the
# import scripts load.
packages_used <- c(
  "tidyverse", "readxl", "pdftools", "scales", "shiny"
)

package_versions <- map_chr(
  packages_used,
  \(package) as.character(packageVersion(package))
)

writeLines(
  c(
    paste("Last run:", Sys.Date()),
    R.version.string,
    paste("Platform:", R.version$platform),
    "",
    "Packages:",
    paste0("  ", packages_used, " ", package_versions)
  ),
  "docs/session_info.txt"
)
