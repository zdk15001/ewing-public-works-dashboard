# scripts/03_join_and_check.R
#
# Joins the budget table to the road mileage table and computes the
# measure the dashboard shows: public works budget per mile of municipal
# road.
#
# Run from the project folder: open ewing-public-works-dashboard.Rproj first.
# Reads:  output/budget_by_town_year.csv   (made by 01_import_budget.R)
#         output/road_miles_by_town.csv    (made by 02_import_mileage.R)
# Writes: output/public_works_per_mile.csv (the file the dashboard reads)

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

# Give each town in the road table its municipal code ---------------------

# The two sources have no key in common. The budget database has a code
# and a name ("Ewing township"). NJDOT has only a name, written its own
# way ("Ewing Twp"). So we match on county plus name, after rewriting
# NJDOT's abbreviations.
#
# County has to be part of the key: New Jersey has five Washington
# townships and two Hamilton townships.

town_list <- budget |>
  distinct(muni_code, municipality, county) |>
  mutate(name_key = str_to_lower(municipality))

nrow(town_list) # expect 565 (564 today, plus Pine Valley through 2021)

# Sixteen towns still do not match after the abbreviations are rewritten:
# names where "City" is part of the name, punctuation, and three towns
# whose type NJDOT lists differently. Each pair below was matched by hand,
# by reading the two lists side by side within one county.
name_fixes <- tribble(
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
  left_join(name_fixes, by = c("county", "name_njdot")) |>
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

# Join road miles onto the budget table ------------------------------------

# Road miles are from March 2019, the only year NJDOT publishes by town.
# Every budget year gets the same 2019 miles. See decision 4.
town_years <- budget |>
  left_join(
    road_miles_coded |>
      select(muni_code, municipal_miles, total_miles),
    by = "muni_code"
  )

nrow(budget) # expect 6,210
nrow(town_years) # expect 6,210: a left join on a unique key adds no rows

# Compute the measure ------------------------------------------------------

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

# One row per town, per year, per way of counting. The dashboard lets the
# reader choose what to count, so each choice gets its own rows.
per_mile <- town_years |>
  mutate(
    `Public works` = public_works_clean,
    `Public works plus solid waste disposal` =
      public_works_clean + solid_waste_budget
  ) |>
  pivot_longer(
    cols = c(`Public works`, `Public works plus solid waste disposal`),
    names_to = "what_counted",
    values_to = "budget_dollars"
  ) |>
  mutate(dollars_per_mile = budget_dollars / municipal_miles_clean)

nrow(per_mile) # expect 12,420: two rows for each of the 6,210 town-years

# Mark the comparison groups -----------------------------------------------

ewing_code <- "1102"
latest_year <- max(budget$year)

ewing_population <- budget |>
  filter(muni_code == ewing_code, year == latest_year) |>
  pull(population)

ewing_population # 39,030 in the 2026 sheet

# "Similar population" means within 25 percent of Ewing's population in
# the latest year. The group is set once and used for every year, so the
# trend figure follows the same towns over time. See decision 6.
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

# How many towns have a usable number, by year and way of counting?
per_mile |>
  group_by(what_counted, year) |>
  summarize(
    towns = n(),
    usable = sum(!is.na(dollars_per_mile)),
    usable_similar = sum(!is.na(dollars_per_mile) & similar_population),
    usable_mercer = sum(!is.na(dollars_per_mile) & county == "Mercer"),
    .groups = "drop"
  ) |>
  print(n = Inf)

# Ewing, latest year. These are the numbers to check by hand against the
# two raw files. See docs/verification_checks.md.
per_mile |>
  filter(muni_code == ewing_code, year == latest_year) |>
  select(
    year, municipality, what_counted, budget_dollars, municipal_miles,
    dollars_per_mile
  ) |>
  print(width = Inf)

# Save ---------------------------------------------------------------------

per_mile |>
  select(
    year, muni_code, municipality, county, town_label, population,
    similar_population, municipal_miles, what_counted, budget_dollars,
    dollars_per_mile
  ) |>
  write_csv("output/public_works_per_mile.csv")
