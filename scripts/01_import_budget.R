# scripts/01_import_budget.R
#
# Reads the NJ DCA User Friendly Budget Database (one sheet per budget
# year, 2016 to 2026) and saves one table with one row per municipality
# per year.
#
# Run from the project folder: open ewing-public-works-dashboard.Rproj first.
# Reads:  data/dca_ufb_database.xlsm   (raw; never edited)
# Writes: output/budget_by_town_year.csv

# Load packages -----------------------------------------------------------

library(tidyverse)
library(readxl)

# The raw file and the columns we need ------------------------------------

ufb_path <- "data/dca_ufb_database.xlsm"

# Each yearly sheet has about 400 columns under three rows of headers, and
# the same header repeats: "Public Works" appears five times (last year's
# budget as modified, this year's total budget, this year's general
# budget, full-time employees, part-time employees). So we pick columns by
# Excel letter, and then check that the header in that column says what we
# expect.
#
# DQ is "Public Works" under the group "General Budget Appropriations".
# We use the general budget, not total appropriations (column CS), because
# the total includes utility funds such as a town-owned water or sewer
# system. See docs/decision_log.md, decision 2.
#
# DW is "Landfill / Solid Waste Disposal" in the same group. Some towns
# budget trash disposal there and some fold it into Public Works, so we
# keep both. See docs/decision_log.md, decision 3.
cols_wanted <- tribble(
  ~letter, ~name,                  ~header_should_say,
  "A",     "muni_code",            "Muni-code",
  "C",     "municipality",         "Municipality",
  "D",     "county",               "County",
  "F",     "no_ufb",               "No UFB Available",
  "I",     "population",           "Population",
  "DQ",    "public_works_budget",  "Public Works",
  "DW",    "solid_waste_budget",   "Landfill / Solid Waste Disposal"
) |>
  mutate(col_number = cellranger::letter_to_num(letter))

last_col <- max(cols_wanted$col_number)

# One function that reads one yearly sheet --------------------------------

read_one_year <- function(sheet) {
  year <- parse_number(sheet)

  # Rows 4 and 5 hold the group headers and the column headers.
  headers <- read_excel(
    ufb_path,
    sheet = sheet,
    range = cell_limits(c(4, 1), c(5, last_col)),
    col_names = FALSE,
    col_types = "text",
    .name_repair = "minimal"
  )
  group_headers <- as.character(headers[1, ])
  column_headers <- as.character(headers[2, ])

  # Check 1: every column we picked has the header we expect.
  found <- column_headers[cols_wanted$col_number]
  header_ok <- str_detect(found, fixed(cols_wanted$header_should_say))
  if (!all(header_ok)) {
    stop(
      sheet, ": unexpected header in column(s) ",
      str_flatten_comma(cols_wanted$letter[!header_ok])
    )
  }

  # Check 2: the two budget columns we picked sit in the general budget
  # group. The group header is written once, above the group's first
  # column (DL), and should name the same year as the sheet.
  group_found <- group_headers[cellranger::letter_to_num("DL")]
  if (!str_detect(group_found, paste(year, "General Budget Appropriations"))) {
    stop(sheet, ": column DL is headed '", group_found, "'")
  }

  # The data start in row 6. Read everything as text so that nothing is
  # guessed, and treat the database's "No data" as missing.
  values <- read_excel(
    ufb_path,
    sheet = sheet,
    range = cell_limits(c(6, 1), c(NA, last_col)),
    col_names = FALSE,
    col_types = "text",
    na = c("", "No data"),
    .name_repair = "minimal"
  )

  values <- values[, cols_wanted$col_number]
  names(values) <- cols_wanted$name

  values |>
    mutate(year = year, .before = 1)
}

# Read all the yearly sheets and stack them -------------------------------

year_sheets <- excel_sheets(ufb_path) |>
  str_subset("^\\d{4} Summary$")

year_sheets # expect 11 sheets, 2016 to 2026

budget_raw <- map(year_sheets, read_one_year) |>
  list_rbind()

# Keep the municipalities and fix the column types ------------------------

# Below the towns, each sheet has summary rows (Minimum, Maximum, Median,
# Average) and a few stray cells. Real municipalities have a four-digit
# code: two digits for the county and two for the town.
budget <- budget_raw |>
  filter(str_detect(muni_code, "^\\d{4}$")) |>
  mutate(
    no_ufb = !is.na(no_ufb), # the database marks these towns with an X
    population = as.numeric(population),
    public_works_budget = as.numeric(public_works_budget),
    solid_waste_budget = as.numeric(solid_waste_budget)
  ) |>
  arrange(year, muni_code)

# The three checks ---------------------------------------------------------

glimpse(budget)

# New Jersey had 565 municipalities until Pine Valley merged into Pine Hill
# in 2022, and 564 after. Expect 565 rows a year through 2021, then 564.
budget |> count(year)

# No town should appear twice in a year.
budget |>
  count(year, muni_code) |>
  filter(n > 1) # expect 0 rows

# How many towns have no public works number, by year? A town is missing
# when DCA has no User Friendly Budget on file for it that year.
budget |>
  group_by(year) |>
  summarize(
    towns = n(),
    no_ufb_on_file = sum(no_ufb),
    missing_public_works = sum(is.na(public_works_budget)),
    zero_public_works = sum(public_works_budget == 0, na.rm = TRUE),
    zero_solid_waste = sum(solid_waste_budget == 0, na.rm = TRUE)
  ) |>
  print(width = Inf)

# Is solid waste ever missing when public works is not? If so, adding the
# two together in script 04 would quietly lose those towns.
budget |>
  filter(!is.na(public_works_budget), is.na(solid_waste_budget)) # expect 0 rows

# Ewing Township, every year. Compare these to the database by eye.
budget |>
  filter(muni_code == "1102") |>
  print(n = Inf, width = Inf)

# Save ---------------------------------------------------------------------

write_csv(budget, "output/budget_by_town_year.csv")
