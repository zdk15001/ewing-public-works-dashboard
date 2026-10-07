# Codebook

## The file the dashboard reads

`output/dollars_per_mile.csv`, made by `scripts/04_join_and_check.R`.

- **Unit of analysis:** one row is one New Jersey municipality, in one
  year, under one measure (one way of counting dollars).
- **Rows expected:** 12,984. The two budget measures have a row for every
  town in every budget year: 565 municipalities for 2016 to 2021 and 564
  for 2022 to 2026 (6,210 town-years), times two. The road upkeep measure
  has a row for each of the 564 towns in 2022 only.
- **Missing values:** written as `NA`.

| Column | What it measures | Values | Missing when |
|---|---|---|---|
| `year` | Budget year for the budget measures; fiscal year for road upkeep | 2016 to 2026; road upkeep is 2022 only | never |
| `muni_code` | DCA's municipal code: two digits for the county, two for the town. A label, not a number. Read it as text or the leading zero is lost. | `0101` to `2123`. Ewing is `1102`. | never |
| `municipality` | Town name as written in the budget database | For example `Ewing township` | never |
| `county` | County name | 21 counties | never |
| `town_label` | Town name with the county in parentheses, for labels. Several towns share a name. | For example `Ewing township (Mercer)` | never |
| `population` | Census Bureau population estimate, as given in that year's sheet of the budget database | 2 to about 324,000 | never |
| `similar_population` | Whether the town's population in the 2026 sheet (a 2025 estimate) is within 25 percent of Ewing's. Set once and the same in every year and measure. | `TRUE` for 44 towns, including Ewing | never |
| `municipal_miles` | Miles of road owned by the municipality, March 2019 | 0.00 to 348.30 | Pine Valley borough, which is not in NJDOT's table |
| `measure` | What is counted in `dollars` | `Road upkeep, actual spending`, `Public works, budgeted`, or `Public works plus solid waste disposal, budgeted` | never |
| `dollars` | For road upkeep: dollars the town reported spending on current operations of its streets and roads. For the budget measures: dollars budgeted in the general budget. | Dollars, not adjusted for inflation. Road upkeep is rounded to the nearest $1,000 by the Census Bureau. | Road upkeep: the town has no reported figure (339 of 564 towns: 245 with only a Census Bureau estimate, 93 with no road line, and Lafayette township, which is not in the file). Budget measures: DCA has no budget on file for the town that year, the Public Works cell says `No data`, or the town reported exactly $0 for public works. |
| `dollars_per_mile` | `dollars` divided by `municipal_miles` | Dollars per mile | `dollars` is missing, the town has 0 municipal miles (Tavistock), or it has no miles on file (Pine Valley) |

## The three in-between files

`output/budget_by_town_year.csv`, made by `scripts/01_import_budget.R`.
One row per municipality per year; 6,210 rows.

| Column | What it measures |
|---|---|
| `year`, `muni_code`, `municipality`, `county`, `population` | As above |
| `no_ufb` | `TRUE` when DCA marked the town "No UFB Available" for the year |
| `public_works_budget` | General Budget Appropriations, Public Works (column DQ), as reported. Zeros are kept here and treated as missing later. |
| `solid_waste_budget` | General Budget Appropriations, Landfill / Solid Waste Disposal (column DW), as reported |

`output/road_miles_by_town.csv`, made by `scripts/02_import_mileage.R`.
One row per municipality; 564 rows.

| Column | What it measures |
|---|---|
| `county` | County name, from the heading of each PDF |
| `name_njdot` | Town name as NJDOT writes it, for example `Ewing Twp` |
| `njdot_miles`, `authority_miles`, `county_miles`, `municipal_miles` | Miles of public road in the town owned by NJDOT, by a toll road authority, by the county, and by the municipality |
| `total_miles` | The four added together, as printed by NJDOT |

`output/road_spending_by_town.csv`, made by
`scripts/03_import_road_spending.R`. One row per municipality; 563 rows.

| Column | What it measures |
|---|---|
| `census_id` | The Census Bureau's 12-character ID for the government: state (34), type (2 = city, 3 = township), county, and a unit number |
| `name_census` | Town name as the Census Bureau writes it, for example `EWING TOWNSHIP` |
| `county` | County name |
| `fips_place` | The federal code for the place. Not used here; kept for anyone who wants to join to other Census data. |
| `road_upkeep_dollars` | Item E44, Regular Highways, Current Operations, fiscal year 2022, converted from thousands to dollars. Missing for 93 towns with no such item on file. |
| `road_upkeep_flag` | Where the number came from: `R` reported by the town (225), `I` imputed, meaning estimated by the Census Bureau (245) |
| `road_construction_dollars`, `road_construction_flag` | Item F44, Regular Highways, Construction, the same way. Read but not used: only 79 towns reported one. |

## Raw source 1: User Friendly Budget Database

- **Who collected it, and how:** each municipality fills in a User Friendly
  Budget form when it adopts its budget and files it with the NJ Department
  of Community Affairs, Division of Local Government Services. DCA compiles
  the forms into one workbook. DCA states that it is not responsible for
  the accuracy of what towns entered.
- **File:** `data/dca_ufb_database.xlsm`, posted by DCA as
  `UFB Database - FINAL.xlsm`. Dated September 1, 2026. Downloaded
  October 6, 2026.
- **Terms of use:** public government record, free to download and share.
- **Layout:** one sheet per budget year (`2016 Summary` to `2026 Summary`).
  Group headers are in row 4, column headers in row 5, and towns start in
  row 6. In the 2022 to 2026 sheets, below the towns are four summary rows
  (Minimum, Maximum, Median, Average), which the script drops.
- **Columns used:** A (municipal code), C (municipality), D (county),
  F (No UFB Available), I (population estimate), DQ (Public Works) and
  DW (Landfill / Solid Waste Disposal), the last two under the group
  "General Budget Appropriations."
- **Missing-value codes:** the text `No data`, and blank cells.
- **DCA's definition of Public Works:** "Includes Street and Road
  Maintenance, Sanitary Sewer Services, Stormwater Management, Solid Waste,
  Recycling, Vehicle Maintenance and other miscellaneous public works
  functions."
- **DCA's definition of General Budget:** "Budget appropriations for
  government operational purposes only. Excludes utility and enterprise
  funds."

## Raw source 2: Mileage by Municipality and Jurisdiction

- **Who collected it, and how:** the NJ Department of Transportation keeps
  an inventory of public roads and who owns each one.
- **Files:** `data/njdot_mileage/mileage_<County>.pdf`, 21 files, each
  headed "March 2019," plus `mileage_State.pdf` with one row per county.
  Files dated August 27, 2019. Downloaded October 6, 2026.
- **Terms of use:** public government record, free to download and share.
- **Layout:** one table row per municipality with five numbers: NJDOT,
  Authority, County, Municipal, Total Mileage. Each county file ends with a
  County Total row.
- **Rows expected:** 564 municipalities. Pine Valley borough, which existed
  in 2019, is not listed.
- **Missing-value codes:** none. A town with no road of a given kind
  shows 0.00.
- **Only year found:** NJDOT posts county-level mileage for every year, but
  the only tables by municipality we found on its site are this March 2019
  set.

## Raw source 3: 2022 Census of Governments, finance, individual unit file

- **Who collected it, and how:** every five years the U.S. Census Bureau
  asks every state and local government in the country for its revenue
  and spending, and sorts the answers into standard categories so that
  governments can be compared. A town that does not respond gets an
  estimated ("imputed") number, marked with a flag.
- **File:** `data/census_gov_finance/2022_Individual_Unit_File.zip`, as
  posted. Dated August 4, 2026. Downloaded October 7, 2026. The zip holds
  three text files and two PDFs: the technical documentation, which gives
  the layouts below, and a disclaimer.
- **Terms of use:** public government record, free to download and share.
  The Census Bureau asks that its cautions be passed on with any results:
  it has not reviewed the town-by-town records as a series for any one
  government, the records can contain reporting and coding errors, and it
  has not reviewed any analysis made from them. The Census Bureau is to be
  cited as the source of the original data only.
- **Layout:** fixed-width text. In `Fin_PID_2022.txt` (one line per
  government): ID in characters 1 to 12, name in 13 to 76, county in 77 to
  111, place code in 112 to 116. In `2022FinEstDAT_07152026modp.txt` (one
  line per government per item): ID in 1 to 12, item code in 13 to 15,
  amount in 16 to 27, year in 28 to 31, flag in 32.
- **Units:** amounts are in thousands of dollars.
- **Rows expected:** 89,901 governments and 1,337,594 amounts nationally;
  563 New Jersey municipalities (323 "cities" and 240 townships).
  Lafayette township in Sussex County is not in the file.
- **Items used:** E44, "Regular Highways-Current Oper" in the
  documentation. "Regular" means not a toll road. F44, "Regular
  Highways-Construction," is read but not used.
- **Flags:** `R` reported, `I` imputed. The documentation also lists `A`
  (analyst correction), `S` (alternative source), `M` (unknown) and `N`
  (not applicable); none of those appear on New Jersey's road items.
- **Fiscal year:** 536 of the 563 towns have a fiscal year ending December
  31, 2022. The other 27 end June 30, 2022. Ewing's ends in December.
- **Missing-value codes:** none. A town with no spending under an item has
  no line for that item.
