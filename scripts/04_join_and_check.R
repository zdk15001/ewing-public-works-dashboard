# scripts/04_join_and_check.R
#
# Joins the three imported tables and computes the measures the dashboard
# shows, all as dollars per mile of municipal road:
#   1. Road upkeep, actual spending (Census Bureau, 2022)
#   2. Public works, budgeted (state budget database, 2016 to 2026)
#   3. Public works plus solid waste disposal, budgeted (same)
#
# Run from the project folder: open ewing-public-works-dashboard.Rproj first.
# Reads:  output/budget_by_town_year.csv   (made by 01_import_budget.R)
#         output/road_miles_by_town.csv    (made by 02_import_mileage.R)
#         output/road_spending_by_town.csv (made by 03_import_road_spending.R)
# Writes: output/dollars_per_mile.csv      (the file the dashboard reads)

# Load packages and data --------------------------------------------------

library(tidyverse)

# muni_code is a label, not a number. Read as a number it would lose its
# leading zero: Absecon is "0101", not 101.
budget <- read_csv(
  "output/budget_by_town_year.csv",
  col_types = cols(
    muni_code = col_character(),
    municipality = col_character(),
    county = col_character(),
    no_ufb = col_logical(),
    .default = col_double()
  )
)

road_miles <- read_csv(
  "output/road_miles_by_town.csv",
  col_types = cols(
    county = col_character(),
    name_njdot = col_character(),
    .default = col_double()
  )
)

road_spending <- read_csv(
  "output/road_spending_by_town.csv",
  col_types = cols(
    road_upkeep_dollars = col_double(),
    road_construction_dollars = col_double(),
    .default = col_character()
  )
)

# The list of towns, with the code we join everything to ------------------

# The three sources have no key in common. The budget database has a code
# and a name ("Ewing township"). NJDOT has only a name, written its own
# way ("Ewing Twp"). The Census Bureau has its own ID and its own spelling
# ("EWING TOWNSHIP"). So we match on county plus name, in lower case.
#
# County has to be part of the key: New Jersey has five Washington
# townships and two Hamilton townships.

town_list <- budget |>
  distinct(muni_code, municipality, county) |>
  mutate(name_key = str_to_lower(municipality))

nrow(town_list) # expect 565 (564 today, plus Pine Valley through 2021)

# Give each town in the road mileage table its municipal code -------------

# Sixteen towns still do not match after NJDOT's abbreviations are
# rewritten: names where "City" is part of the name, punctuation, and
# three towns whose type NJDOT lists differently. Each pair below was
# matched by hand, by reading the two lists side by side within one county.
njdot_name_fixes <- tribble(
  ~county,    ~name_njdot,              ~municipality,
  "Atlantic", "Corbin City",            "Corbin City city",
  "Atlantic", "Egg Harbor City",        "Egg Harbor City city",
  "Atlantic", "Margate City",           "Margate City city",
  "Atlantic", "Ventnor City",           "Ventnor City city",
  "Bergen",   "Ho Ho Kus Boro",         "Ho-Ho-Kus borough",
  "Camden",   "Gloucester City",        "Gloucester City city",
  "Cape May", "Ocean City",             "Ocean City city",
  "Cape May", "Sea Isle City",          "Sea Isle City city",
  "Essex",    "Fairfield Boro",         "Fairfield township",
  "Essex",    "Orange City",            "City of Orange township",
  "Essex",    "South Orange Twp",       "South Orange Village township",
  "Essex",    "West Caldwell Boro",     "West Caldwell township",
  "Hudson",   "Jersey City",            "Jersey City city",
  "Hudson",   "Union City",             "Union City city",
  "Mercer",   "Princeton",              "Princeton borough",
  "Somerset", "Peapack-Gladstone Boro", "Peapack and Gladstone borough"
)

road_miles_keyed <- road_miles |>
  left_join(njdot_name_fixes, by = c("county", "name_njdot")) |>
  mutate(
    name_key = if_else(
      !is.na(municipality),
      str_to_lower(municipality), # one of the sixteen hand-matched names
      name_njdot |>
        str_to_lower() |>
        str_replace(" boro$", " borough") |>
        str_replace(" twp$", " township")
    )
  ) |>
  select(-municipality)

# Before joining, write down what we expect: every one of the 564 NJDOT
# towns finds exactly one code, and no code is used twice.
road_miles_coded <- road_miles_keyed |>
  left_join(town_list, by = c("county", "name_key"))

nrow(road_miles_coded) # expect 564, the same as before the join

road_miles_coded |>
  filter(is.na(muni_code)) # expect 0 rows: no NJDOT town left unmatched

road_miles_coded |>
  count(muni_code) |>
  filter(n > 1) # expect 0 rows: no code matched twice

# Which towns in the budget database have no road mileage?
town_list |>
  anti_join(road_miles_coded, by = "muni_code")
# expect 1 row: Pine Valley borough. It is not in NJDOT's 2019 table, and
# it merged into Pine Hill in 2022.

# Give each town in the Census table its municipal code -------------------

# The Census Bureau writes names in capitals with the type spelled out, so
# lower case is enough for 553 of its 563 towns. The other ten were
# matched by hand, the same way as above.
census_name_fixes <- tribble(
  ~county,    ~name_census,                   ~municipality,
  "Atlantic", "ATLANTIC CITY CITY",           "Atlantic City",
  "Atlantic", "EGG HARBOR CITY",              "Egg Harbor City city",
  "Atlantic", "MARGATE CITY",                 "Margate City city",
  "Bergen",   "WOOD RIDGE BOROUGH",           "Wood-Ridge borough",
  "Camden",   "HI NELLA BOROUGH",             "Hi-Nella borough",
  "Cape May", "SEA ISLE CITY",                "Sea Isle City city",
  "Essex",    "ORANGE CITY TOWNSHIP",         "City of Orange township",
  "Essex",    "SOUTH ORANGE VILLAGE VILLAGE", "South Orange Village township",
  "Mercer",   "PRINCETON MUNICIPALITY",       "Princeton borough",
  "Monmouth", "AVON BY THE SEA BOROUGH",      "Avon-by-the-Sea borough"
)

road_spending_coded <- road_spending |>
  left_join(census_name_fixes, by = c("county", "name_census")) |>
  mutate(
    name_key = str_to_lower(if_else(
      !is.na(municipality), municipality, name_census
    ))
  ) |>
  select(-municipality) |>
  left_join(town_list, by = c("county", "name_key"))

nrow(road_spending_coded) # expect 563, the same as before the join

road_spending_coded |>
  filter(is.na(muni_code)) # expect 0 rows: no Census town left unmatched

road_spending_coded |>
  count(muni_code) |>
  filter(n > 1) # expect 0 rows: no code matched twice

# Which towns in the budget database are not in the Census file?
town_list |>
  anti_join(road_spending_coded, by = "muni_code")
# expect 2 rows: Pine Valley borough (merged into Pine Hill in 2022) and
# Lafayette township in Sussex County, which the Census file leaves out.

# Join road miles onto the budget table ------------------------------------

# Road miles are from March 2019, the only year NJDOT publishes by town.
# Every year gets the same 2019 miles. See decision 4.
town_years <- budget |>
  left_join(
    road_miles_coded |>
      select(muni_code, municipal_miles, total_miles),
    by = "muni_code"
  )

nrow(budget) # expect 6,210
nrow(town_years) # expect 6,210: a left join on a unique key adds no rows

town_years <- town_years |>
  mutate(
    # A few towns report exactly $0 for public works in some years. No
    # town maintains roads for nothing, so we treat $0 as "not reported"
    # and keep the original column to compare against. See decision 5.
    public_works_clean = if_else(
      public_works_budget == 0, NA, public_works_budget
    ),
    # Tavistock has 0.00 miles of municipal road. Dollars per zero miles
    # is not a number we can rank, so it becomes missing.
    municipal_miles_clean = if_else(municipal_miles == 0, NA, municipal_miles)
  )

town_years |> count(public_works_budget == 0, is.na(public_works_clean))
town_years |> count(municipal_miles == 0, is.na(municipal_miles_clean))

# The two budget measures: one row per town, per year, per measure ---------

budget_measures <- town_years |>
  mutate(
    `Public works, budgeted` = public_works_clean,
    `Public works plus solid waste disposal, budgeted` =
      public_works_clean + solid_waste_budget
  ) |>
  pivot_longer(
    cols = c(
      `Public works, budgeted`,
      `Public works plus solid waste disposal, budgeted`
    ),
    names_to = "measure",
    values_to = "dollars"
  )

nrow(budget_measures) # expect 12,420: two rows for each of 6,210 town-years

# The road upkeep measure: one row per town, for 2022 only -----------------

census_year <- 2022

# Start from the budget table's 2022 rows so that every town is listed,
# with the same names and population as everywhere else.
road_measure <- town_years |>
  filter(year == census_year) |>
  left_join(
    road_spending_coded |>
      select(muni_code, road_upkeep_dollars, road_upkeep_flag),
    by = "muni_code"
  ) |>
  mutate(
    measure = "Road upkeep, actual spending",
    # Keep only numbers the town itself reported (flag R). An imputed
    # number (flag I) is the Census Bureau's estimate for a town that did
    # not respond. It is fine for a state total and wrong for ranking one
    # town against another. See decision 15.
    dollars = if_else(road_upkeep_flag == "R", road_upkeep_dollars, NA)
  )

nrow(road_measure) # expect 564: one row per town in the 2022 budget sheet

road_measure |> count(road_upkeep_flag, is.na(dollars))
# expect 225 reported and kept; 245 imputed and 94 with nothing on file,
# both set to missing

# Stack the measures and compute dollars per mile --------------------------

per_mile <- bind_rows(road_measure, budget_measures) |>
  mutate(dollars_per_mile = dollars / municipal_miles_clean)

nrow(per_mile) # expect 12,984: 564 + 12,420

# Mark the comparison groups -----------------------------------------------

ewing_code <- "1102"
latest_year <- max(budget$year)

ewing_population <- budget |>
  filter(muni_code == ewing_code, year == latest_year) |>
  pull(population)

ewing_population # 39,030 in the 2026 sheet

# "Similar population" means within 25 percent of Ewing's population in
# the latest year. The group is set once and used for every year and
# every measure, so the figures always compare the same towns. See
# decision 6.
similar_towns <- budget |>
  filter(
    year == latest_year,
    population >= 0.75 * ewing_population,
    population <= 1.25 * ewing_population
  ) |>
  pull(muni_code)

length(similar_towns) # how many towns, Ewing included

per_mile <- per_mile |>
  mutate(
    similar_population = muni_code %in% similar_towns,
    # Several towns share a name, so labels carry the county.
    town_label = paste0(municipality, " (", county, ")")
  )

# Checks on the finished table ---------------------------------------------

glimpse(per_mile)

# How many towns have a usable number, by measure and year?
per_mile |>
  group_by(measure, year) |>
  summarize(
    towns = n(),
    usable = sum(!is.na(dollars_per_mile)),
    usable_similar = sum(!is.na(dollars_per_mile) & similar_population),
    usable_mercer = sum(!is.na(dollars_per_mile) & county == "Mercer"),
    .groups = "drop"
  ) |>
  print(n = Inf)

# Ewing: the road upkeep row, and the latest budget rows. These are the
# numbers to check by hand against the raw files. See
# docs/verification_checks.md.
per_mile |>
  filter(
    muni_code == ewing_code,
    (measure == "Road upkeep, actual spending") | (year == latest_year)
  ) |>
  select(
    year, municipality, measure, dollars, municipal_miles, dollars_per_mile
  ) |>
  print(width = Inf)

# Save ---------------------------------------------------------------------

per_mile |>
  select(
    year, muni_code, municipality, county, town_label, population,
    similar_population, municipal_miles, measure, dollars,
    dollars_per_mile
  ) |>
  write_csv("output/dollars_per_mile.csv")
