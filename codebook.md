# Codebook

## The file the dashboard reads

`output/public_works_per_mile.csv`, made by `scripts/03_join_and_check.R`.

- **Unit of analysis:** one row is one New Jersey municipality, in one
  budget year, under one way of counting.
- **Rows expected:** 12,420. That is 565 municipalities for 2016 to 2021
  and 564 for 2022 to 2026 (6,210 town-years), times two ways of counting.
- **Missing values:** written as `NA`.

| Column | What it measures | Values | Missing when |
|---|---|---|---|
| `year` | Budget year | 2016 to 2026 | never |
| `muni_code` | DCA's municipal code: two digits for the county, two for the town. A label, not a number. Read it as text or the leading zero is lost. | `0101` to `2123`. Ewing is `1102`. | never |
| `municipality` | Town name as written in the budget database | For example `Ewing township` | never |
| `county` | County name | 21 counties | never |
| `town_label` | Town name with the county in parentheses, for labels. Several towns share a name. | For example `Ewing township (Mercer)` | never |
| `population` | Census Bureau population estimate, as given in that year's sheet of the budget database | 2 to about 324,000 | never |
| `similar_population` | Whether the town's 2026 population is within 25 percent of Ewing's. Set once and the same in every year. | `TRUE` for 44 towns, including Ewing | never |
| `municipal_miles` | Miles of road owned by the municipality, March 2019 | 0.00 to 348.30 | Pine Valley borough, which is not in NJDOT's table |
| `what_counted` | Which budget lines are in `budget_dollars` | `Public works` or `Public works plus solid waste disposal` | never |
| `budget_dollars` | Dollars budgeted in the general budget for the lines named in `what_counted` | Dollars, not adjusted for inflation | DCA has no budget on file for the town that year, or the town reported exactly $0 for public works |
| `dollars_per_mile` | `budget_dollars` divided by `municipal_miles` | Dollars per mile | `budget_dollars` is missing, or the town has 0 municipal miles (Tavistock) |

## The two in-between files

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
  row 6. Below the towns are four summary rows (Minimum, Maximum, Median,
  Average), which the script drops.
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
