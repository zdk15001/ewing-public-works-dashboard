# Ewing Township: dollars for roads, per mile of road

An example project for the STA 220 town dashboard assignment. It is a
small R Shiny dashboard plus everything needed to rebuild it from the
original data (the reproduction package).

- **Town:** Ewing Township, Mercer County, New Jersey
- **Audience:** members of the Ewing Township Council
- **Question:** for each mile of road the township maintains, how much does
  Ewing spend on road upkeep, and how does that compare with similar towns
  and with the rest of New Jersey?
- **Dashboard link:** not published yet. Add the link here after publishing.
- **Repository:** https://github.com/zdk15001/ewing-public-works-dashboard

## What it found

In its 2022 fiscal year, the latest with a figure for every town that
reported one, Ewing spent $9,054 on road upkeep per mile of municipal
road. Among the 31 towns of similar population that reported a figure, the
median was $16,826 and Ewing ranked 24th. Among all 225 New Jersey towns
that reported, the median was $18,358.

The broader public works budget points the same way. In its 2026 budget
Ewing set aside $30,502 for all of public works per mile of municipal
road, against a statewide median of $51,700, and ranked 30th of 39 towns
of similar population. That gap mostly closes when trash disposal is
counted, because Ewing lists it on a separate budget line and many towns
do not: $60,616 per mile against a statewide median of $63,740. The
dashboard lets the reader switch between the three ways of counting.

None of the three is the full cost of roads. Repaving is paid for through
the capital budget and is in none of them. See "Limits to know about."

## Version 2: what changed and why

The first version of this project divided the public works budget by road
miles and called it dollars per mile of road. That number is a plan, not
spending, and public works covers much more than roads. Version 2 adds a
third data source, the Census Bureau's 2022 Census of Governments, which
has what 225 New Jersey towns reported actually spending on running and
maintaining their streets and roads. That is now the first thing the
dashboard shows. The budget numbers are still
there, labeled as the broader measure they are, because they are the only
ones filed every year. The reasoning is in decisions 14 to 19 of
`docs/decision_log.md`.

## Where the data came from

| | Road spending | Budgets | Road miles |
|---|---|---|---|
| Source | 2022 Census of Governments, finance public use files, individual unit file | User Friendly Budget Database | Mileage by Municipality and Jurisdiction |
| Agency | U.S. Census Bureau | NJ Department of Community Affairs, Division of Local Government Services | NJ Department of Transportation |
| What it covers | Revenue and spending by category for state and local governments across the country, fiscal year 2022 | Adopted municipal budgets, 2016 to 2026, one sheet per year | Miles of public road in each municipality by owner, March 2019 |
| File here | `data/census_gov_finance/2022_Individual_Unit_File.zip` | `data/dca_ufb_database.xlsm` (posted as `UFB Database - FINAL.xlsm`) | `data/njdot_mileage/`, 21 county PDFs and 1 statewide PDF |
| File dated | August 4, 2026 | September 1, 2026 | August 27, 2019 |
| Downloaded | October 7, 2026 | October 6, 2026 | October 6, 2026 |
| Found on | census.gov, 2022 State and Local Government Finance datasets page | nj.gov/dca/dlgs, Municipal and County Budgets page | nj.gov/transportation/refdata/sldiag/pdf/ (direct file links) |

The exact address, size and checksum of every raw file are in
`docs/source_files.tsv`. All three sources are public government records
with no personal information.

The Census Bureau asks that anyone using its town-by-town records pass on
its cautions. It publishes those records as the inputs to its state
totals. It has not reviewed them as a series for any one government, it
warns that they can contain reporting and coding errors, and it has not
reviewed or endorsed this analysis. The Census Bureau is the source of the
original data only. The conclusions here are ours.

No data from a public records (OPRA) request is in the dashboard. A
request has been drafted but not sent. See `docs/opra_log.md`.

## How to run it

1. Install R and RStudio. Then install the packages once:
   `install.packages(c("tidyverse", "readxl", "pdftools", "shiny"))`
2. Open `ewing-public-works-dashboard.Rproj`. This sets the working
   directory, so every path in the scripts works as written.
3. Run the five scripts in `scripts/` in order. Each one starts from files,
   not from objects left over by the one before, so you can restart R
   between them.
   1. `01_import_budget.R` reads the budget database.
   2. `02_import_mileage.R` reads the road mileage PDFs.
   3. `03_import_road_spending.R` reads the Census finance file.
   4. `04_join_and_check.R` joins the three and computes dollars per mile.
   5. `05_make_figures.R` saves the two figures and the package versions.
4. Open `app.R` and click **Run App**.

The scripts take under a minute in total. Each prints checks as it runs,
with the expected result written next to each check.

The cleaned data and figures are already in `output/`, so the dashboard
also runs without step 3. Running the scripts should reproduce the four
CSV files exactly, and the two figures to the eye.

## What is in each folder

| Folder or file | What it holds |
|---|---|
| `data/` | The raw files exactly as downloaded. Never edited. The Census file stays zipped; the script unzips it into a temporary folder. |
| `scripts/` | The code, numbered in the order it runs. `figure_functions.R` is not run on its own; `05_make_figures.R` and `app.R` both use it. |
| `output/` | Everything the scripts make: four CSV files and two figures. All of it can be remade by rerunning the scripts. |
| `app.R` | The dashboard. It reads `output/dollars_per_mile.csv`. |
| `codebook.md` | What each column means, and where each raw file came from. |
| `docs/decision_log.md` | Each decision made in the analysis, what was done and why. |
| `docs/verification_checks.md` | The numbers that were checked against the original sources, and how. |
| `docs/opra_log.md` | The public records request: wording, dates, responses. |
| `docs/source_files.tsv` | Address, size and checksum of every raw file. |
| `docs/session_info.txt` | The version of R and of each package at the last run. |
| `LICENSE` | The terms for reusing the code (MIT License). |

## Publishing the dashboard

The app needs only three files to run:
`app.R`, `scripts/figure_functions.R` and `output/dollars_per_mile.csv`.
To publish to shinyapps.io from RStudio without uploading the raw files:

```r
rsconnect::deployApp(
  appFiles = c(
    "app.R",
    "scripts/figure_functions.R",
    "output/dollars_per_mile.csv"
  )
)
```

## Limits to know about

- **Repaving is not counted.** Road upkeep is the yearly running cost.
  Construction is a separate item in the Census file, and only 79 New
  Jersey towns reported one, so it is left out. For scale: Ewing's 2023
  budget lists a $1,000,000 road improvement program in its capital
  budget, about as much as it spends on upkeep in a year.
- **Road upkeep depends on how a town labels its budget.** A town that
  pays its road crew from a general public works line shows little or
  nothing under roads. Reported figures run from under $500 to over
  $350,000 per mile. Ewing's figure was checked against its own budget;
  no other town's was.
- **Most towns have no reported figure.** 225 of the 563 towns in the
  Census file reported a road upkeep figure for 2022. Another 245 did not
  answer and have only a Census Bureau estimate, which is not used. The
  other 93 have no road line at all; 51 of those answered everything else,
  which suggests their road costs are filed under a broader heading.
  Larger towns reported more often, so the statewide median describes
  towns with a reported figure, not all towns.
- **One year.** The Census Bureau collects from every town only in years
  ending in 2 and 7, and its 2017 figure for Ewing is an estimate, not a
  number Ewing reported. So there is no trend in road upkeep, only in the
  budget.
- **Budgets are plans, and public works is more than roads.** The two
  budget measures have the problems the first version had. A town with no
  budget on file for a year, or a blank or zero public works line, is
  left out of that year.
- **Road miles are from 2019** and are used for every year. They count
  length, not lanes.
- **Dollars are not adjusted for inflation.**

More on each of these is in `docs/decision_log.md`.

## Who made this, and when

Made for STA 220 at The College of New Jersey by Zachary Kline with the
help of Claude AI. Claude wrote the code and made the analysis decisions
recorded in `docs/decision_log.md`. Last updated October 7, 2026.

## License

The code is released under the MIT License (see `LICENSE`). The files in
`data/` are public records of the State of New Jersey and of the U.S.
Census Bureau.
