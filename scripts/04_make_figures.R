# scripts/04_make_figures.R
#
# Saves a copy of the dashboard's two figures as they look when the
# dashboard first opens (towns of similar population, public works only,
# latest year), so a reader can compare their own run against output/.
# Also records the version of R and of each package.
#
# Run from the project folder: open ewing-public-works-dashboard.Rproj first.
# Reads:  output/public_works_per_mile.csv   (made by 03_join_and_check.R)
# Writes: output/figure1_rank.png
#         output/figure2_trend.png
#         docs/session_info.txt

# Load packages, functions and data ----------------------------------------

library(tidyverse)
source("scripts/figure_functions.R")

per_mile <- read_csv(
  "output/public_works_per_mile.csv",
  col_types = cols(
    muni_code = col_character(),
    municipality = col_character(),
    county = col_character(),
    town_label = col_character(),
    what_counted = col_character(),
    similar_population = col_logical(),
    .default = col_double()
  )
)

# The dashboard's opening view ----------------------------------------------

counted <- "Public works"
latest_year <- max(per_mile$year)

source_note <- paste0(
  "Sources: NJ DCA User Friendly Budget Database (file dated Sept. 1, 2026);\n",
  "NJDOT Mileage by Municipality and Jurisdiction (March 2019)."
)

# Every town with a usable number, for this way of counting.
usable <- per_mile |>
  filter(what_counted == counted, !is.na(dollars_per_mile))

similar <- usable |>
  filter(similar_population)

# Figure 1 -----------------------------------------------------------------

rank_rows <- similar |>
  filter(year == latest_year)

group_median <- median(rank_rows$dollars_per_mile)

state_median <- usable |>
  filter(year == latest_year) |>
  pull(dollars_per_mile) |>
  median()

nrow(rank_rows) # towns of similar population with a budget on file
group_median
state_median

figure1 <- plot_rank(
  rank_rows,
  group_median = group_median,
  state_median = state_median,
  group_name = "towns of similar population",
  title = paste0("Ewing and towns of similar population, ", latest_year),
  subtitle = "Public works budget per mile of municipal road",
  caption = source_note
)

ggsave(
  "output/figure1_rank.png",
  figure1,
  width = 9, height = 10, dpi = 150, bg = "white"
)

# Figure 2 -----------------------------------------------------------------

trend_rows <- bind_rows(
  usable |>
    filter(muni_code == ewing_code) |>
    mutate(line = "Ewing township") |>
    select(year, line, dollars_per_mile),
  similar |>
    group_by(year) |>
    summarize(dollars_per_mile = median(dollars_per_mile)) |>
    mutate(line = "Similar-size towns (median)"),
  usable |>
    group_by(year) |>
    summarize(dollars_per_mile = median(dollars_per_mile)) |>
    mutate(line = "All NJ towns (median)")
)

trend_rows |>
  pivot_wider(names_from = line, values_from = dollars_per_mile) |>
  print(n = Inf)

figure2 <- plot_trend(
  trend_rows,
  title = "Ewing and the two medians, 2016 to 2026",
  subtitle = paste(
    "Public works budget per mile of municipal road,",
    "not adjusted for inflation"
  ),
  caption = source_note
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
