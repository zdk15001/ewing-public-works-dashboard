# scripts/02_import_mileage.R
#
# Reads the NJDOT "Mileage by Municipality and Jurisdiction" tables, which
# NJDOT publishes only as PDFs (one per county, dated March 2019), and
# saves one table with one row per municipality.
#
# Run from the project folder: open ewing-public-works-dashboard.Rproj first.
# Reads:  data/njdot_mileage/mileage_*.pdf   (raw; never edited)
# Writes: output/road_miles_by_town.csv

# Load packages -----------------------------------------------------------

library(tidyverse)
library(pdftools)

# List the county files ---------------------------------------------------

# mileage_State.pdf has one row per county, not per town. We leave it out
# here and use it at the bottom to check our county totals.
county_files <- list.files(
  "data/njdot_mileage",
  pattern = "^mileage_.*\\.pdf$",
  full.names = TRUE
) |>
  str_subset("mileage_State", negate = TRUE)

length(county_files) # expect 21, one per county

# What a row of the table looks like ---------------------------------------

# pdf_text() gives back each page as one long piece of text. A table row
# looks like this:
#
#   Ewing Twp        12.65      0.20     29.61    109.68     152.14
#
# In English: a name, then two or more spaces, then five numbers that each
# have two decimals (NJDOT, Authority, County, Municipal, Total). Titles,
# column headers and page numbers do not fit that pattern, so they drop
# out on their own.
number <- "([\\d,]+\\.\\d{2})"
row_pattern <- paste0(
  "^\\s*(.+?)\\s{2,}",
  number, "\\s+", number, "\\s+", number, "\\s+", number, "\\s+", number,
  "\\s*$"
)

# One function that reads one county PDF ----------------------------------

read_one_county <- function(file) {
  lines <- pdf_text(file) |>
    str_split("\n") |>
    unlist()

  # The second line of every file is the county name, e.g. "Mercer County".
  county <- lines |>
    str_squish() |>
    str_subset("^[A-Za-z ]+ County$") |>
    first() |>
    str_remove(" County$")

  matches <- str_match(lines, row_pattern)

  tibble(
    county = county,
    name_njdot = str_squish(matches[, 2]),
    njdot_miles = parse_number(matches[, 3]),
    authority_miles = parse_number(matches[, 4]),
    county_miles = parse_number(matches[, 5]),
    municipal_miles = parse_number(matches[, 6]),
    total_miles = parse_number(matches[, 7])
  ) |>
    filter(!is.na(name_njdot)) # lines that were not table rows
}

# Read all 21 counties and stack them --------------------------------------

mileage_raw <- map(county_files, read_one_county) |>
  list_rbind()

# Each county table ends with a "County Total" row. Set those aside: they
# are not towns, but they let us check that we read every town.
county_totals <- mileage_raw |>
  filter(name_njdot == "County Total")

road_miles <- mileage_raw |>
  filter(name_njdot != "County Total")

# Checks -------------------------------------------------------------------

glimpse(road_miles)

nrow(county_totals) # expect 21

# Check 1: in every row, the four kinds of road add up to the total.
# NJDOT rounds each number to two decimals, so allow a cent of rounding.
road_miles |>
  filter(
    abs(njdot_miles + authority_miles + county_miles + municipal_miles -
      total_miles) > 0.011
  ) # expect 0 rows

# Check 2: in every county, the towns we read add up to NJDOT's own
# "County Total" row. If we had skipped a town, this would show it.
road_miles |>
  group_by(county) |>
  summarize(
    towns = n(),
    municipal_miles_added_up = sum(municipal_miles),
    total_miles_added_up = sum(total_miles)
  ) |>
  left_join(
    county_totals |>
      select(
        county,
        municipal_miles_njdot = municipal_miles,
        total_miles_njdot = total_miles
      ),
    by = "county"
  ) |>
  mutate(
    municipal_gap = round(municipal_miles_added_up - municipal_miles_njdot, 2),
    total_gap = round(total_miles_added_up - total_miles_njdot, 2)
  ) |> # expect every gap to be 0
  print(n = Inf, width = Inf)

# Check 3: our county totals match the separate statewide PDF.
state_table <- read_one_county("data/njdot_mileage/mileage_State.pdf") |>
  select(county = name_njdot, total_miles_state_pdf = total_miles)

county_totals |>
  select(county, total_miles) |>
  full_join(state_table, by = "county") |>
  filter(is.na(total_miles) | abs(total_miles - total_miles_state_pdf) > 0.011)
# expect 1 row: "State Total", which is in the statewide PDF only

# Ewing Township. Compare to data/njdot_mileage/mileage_Mercer.pdf by eye.
road_miles |>
  filter(county == "Mercer", name_njdot == "Ewing Twp")

# Save ---------------------------------------------------------------------

write_csv(road_miles, "output/road_miles_by_town.csv")
