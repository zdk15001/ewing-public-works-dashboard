# scripts/03_import_road_spending.R
#
# Reads the Census Bureau's 2022 Census of Governments finance file and
# saves one table with one row per New Jersey municipality: what the town
# actually spent on running and maintaining its streets and roads in its
# 2022 fiscal year.
#
# This is the only source in the project that is (a) spending, not a
# budget, and (b) roads only, not all of public works. See
# docs/decision_log.md, decisions 14 to 16.
#
# Run from the project folder: open ewing-public-works-dashboard.Rproj first.
# Reads:  data/census_gov_finance/2022_Individual_Unit_File.zip  (raw)
# Writes: output/road_spending_by_town.csv

# Load packages -----------------------------------------------------------

library(tidyverse)

# Unzip the three text files we need --------------------------------------

# The raw file stays zipped, exactly as the Census Bureau posted it. We
# unzip into R's temporary folder, which is thrown away when R closes.
zip_path <- "data/census_gov_finance/2022_Individual_Unit_File.zip"
folder_in_zip <- "2022_Individual_Unit_files/"

directory_file <- paste0(folder_in_zip, "Fin_PID_2022.txt")
amounts_file <- paste0(folder_in_zip, "2022FinEstDAT_07152026modp.txt")
totals_file <- paste0(folder_in_zip, "22statetypepu.txt")

unzip(
  zip_path,
  files = c(directory_file, amounts_file, totals_file),
  exdir = tempdir()
)

# Read the directory of governments ----------------------------------------

# These are "fixed-width" files: no commas or tabs. Each piece of
# information sits at fixed character positions on the line. The positions
# below come from the technical documentation PDF inside the zip.
#
# The 12-character ID is built like this:
#   characters 1-2   state (34 is New Jersey)
#   character  3     type of government (2 = city, 3 = township)
#   characters 4-6   county
#   characters 7-12  the government's own number
directory <- read_fwf(
  file.path(tempdir(), directory_file),
  col_positions = fwf_cols(
    census_id = c(1, 12),
    name_census = c(13, 76),
    county = c(77, 111),
    fips_place = c(112, 116)
  ),
  col_types = cols(.default = col_character()),
  locale = locale(encoding = "latin1")
)

nrow(directory) # expect 89,901 governments in the whole country

# Keep New Jersey's municipalities. The Census Bureau calls boroughs,
# cities, towns and villages "cities" (type 2) and townships "townships"
# (type 3). New Jersey law treats all of them as municipalities.
nj_towns <- directory |>
  filter(
    str_sub(census_id, 1, 2) == "34",
    str_sub(census_id, 3, 3) %in% c("2", "3")
  )

nrow(nj_towns) # expect 563
nj_towns |> count(type = str_sub(census_id, 3, 3)) # expect 323 and 240

# Read the amounts ---------------------------------------------------------

# One line is one amount for one government: an ID, a three-character
# item code, the amount in THOUSANDS of dollars, the year, and a flag
# that says where the number came from.
amounts <- read_fwf(
  file.path(tempdir(), amounts_file),
  col_positions = fwf_cols(
    census_id = c(1, 12),
    item_code = c(13, 15),
    thousands = c(16, 27),
    year = c(28, 31),
    flag = c(32, 32)
  ),
  col_types = cols(
    thousands = col_double(),
    .default = col_character()
  )
)

nrow(amounts) # expect 1,337,594 lines for the whole country

amounts |> count(year) # expect one year: 2022

# The two item codes for roads, from the technical documentation:
#   E44  Regular Highways - Current Operations (the yearly running cost)
#   F44  Regular Highways - Construction
# "Regular" means not a toll road. We use E44. F44 is read only so we can
# show why it was left out. See decision 16.
road_items <- amounts |>
  semi_join(nj_towns, by = "census_id") |>
  filter(item_code %in% c("E44", "F44"))

# The flag matters. R means the town reported the number. I means the
# Census Bureau filled in an estimate ("imputed") because the town did not
# respond. See decision 15.
road_items |> count(item_code, flag)
# expect E44: 245 imputed, 225 reported. F44: 66 imputed, 79 reported.

# One row per town ---------------------------------------------------------

road_spending <- road_items |>
  mutate(
    dollars = thousands * 1000,
    item = if_else(item_code == "E44", "road_upkeep", "road_construction")
  ) |>
  select(census_id, item, dollars, flag) |>
  pivot_wider(
    names_from = item,
    values_from = c(dollars, flag),
    names_glue = "{item}_{.value}"
  )

# Start from the full list of towns so that a town with no road item at
# all still gets a row (with missing values).
road_spending <- nj_towns |>
  left_join(road_spending, by = "census_id") |>
  select(
    census_id, name_census, county, fips_place,
    road_upkeep_dollars, road_upkeep_flag,
    road_construction_dollars, road_construction_flag
  )

# Checks -------------------------------------------------------------------

glimpse(road_spending)

nrow(road_spending) # expect 563, one per town

road_spending |> count(road_upkeep_flag)
# expect 245 I, 225 R, and 93 missing (no road item on file at all)

# Check: our towns add up to the Census Bureau's own New Jersey totals.
# The third file in the zip has those totals. "Level" 6 is all cities in
# a state and level 7 is all townships. If we had dropped or doubled a
# line, the two columns below would not match.
census_totals <- read_fwf(
  file.path(tempdir(), totals_file),
  col_positions = fwf_cols(
    state = c(1, 2),
    level = c(3, 3),
    item_code = c(5, 7),
    thousands_census = c(9, 20)
  ),
  col_types = cols(
    thousands_census = col_double(),
    .default = col_character()
  )
) |>
  filter(state == "34", level %in% c("6", "7"), item_code == "E44")

road_spending |>
  mutate(level = if_else(str_sub(census_id, 3, 3) == "2", "6", "7")) |>
  group_by(level) |>
  summarize(
    thousands_added_up = sum(road_upkeep_dollars, na.rm = TRUE) / 1000
  ) |>
  left_join(census_totals, by = "level")
# expect 287,850 for cities and 272,944 for townships, in both columns

# Ewing Township. Expect $993,000, flag R. Compare with the Streets &
# Roads lines in Ewing's own budget: see docs/verification_checks.md.
road_spending |>
  filter(name_census == "EWING TOWNSHIP", county == "Mercer")

# Save ---------------------------------------------------------------------

write_csv(road_spending, "output/road_spending_by_town.csv")
