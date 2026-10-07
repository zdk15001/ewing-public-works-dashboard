# Ewing Township: public works budget per mile of road

An example project for the STA 220 town dashboard assignment. It is a
small R Shiny dashboard plus everything needed to rebuild it from the
original data (the reproduction package).

- **Town:** Ewing Township, Mercer County, New Jersey
- **Audience:** members of the Ewing Township Council
- **Question:** for each mile of road the township maintains, how much does
  Ewing budget for public works, and how does that compare with similar
  towns and with the rest of New Jersey?
- **Dashboard link:** not published yet. Add the link here after publishing.
- **Repository:** https://github.com/zdk15001/ewing-public-works-dashboard

## What it found

In its 2026 budget, Ewing set aside $30,502 for public works per mile of
municipal road. The median New Jersey town set aside $51,700, and Ewing
ranks 30th of 39 towns of similar population.

That gap depends on what is counted. Ewing lists trash disposal on a
separate budget line, and many towns do not. Counting public works and
solid waste disposal together, Ewing is at $60,616 per mile against a
statewide median of $63,740, and ranks 23rd of 39. The dashboard lets the
reader switch between the two.

## Where the data came from

| | Budget data | Road miles |
|---|---|---|
| Source | User Friendly Budget Database | Mileage by Municipality and Jurisdiction |
| Agency | NJ Department of Community Affairs, Division of Local Government Services | NJ Department of Transportation |
| What it covers | Adopted municipal budgets, 2016 to 2026, one sheet per year | Miles of public road in each municipality by owner, March 2019 |
| File here | `data/dca_ufb_database.xlsm` (posted as `UFB Database - FINAL.xlsm`) | `data/njdot_mileage/`, 21 county PDFs and 1 statewide PDF |
| File dated | September 1, 2026 | August 27, 2019 |
| Downloaded | October 6, 2026 | October 6, 2026 |
| Found on | nj.gov/dca/dlgs, Municipal and County Budgets page | nj.gov/transportation/refdata/sldiag/pdf/ (direct file links) |

The exact address, size and checksum of every raw file are in
`docs/source_files.tsv`. Both sources are public government records with
no personal information.

No data from a public records (OPRA) request is in the dashboard. A
request has been drafted but not sent. See `docs/opra_log.md`.

## How to run it

1. Install R and RStudio. Then install the packages once:
   `install.packages(c("tidyverse", "readxl", "pdftools", "shiny"))`
2. Open `ewing-public-works-dashboard.Rproj`. This sets the working
   directory, so every path in the scripts works as written.
3. Run the four scripts in `scripts/` in order. Each one starts from files,
   not from objects left over by the one before, so you can restart R
   between them.
   1. `01_import_budget.R` reads the budget database.
   2. `02_import_mileage.R` reads the road mileage PDFs.
   3. `03_join_and_check.R` joins the two and computes dollars per mile.
   4. `04_make_figures.R` saves the two figures and the package versions.
4. Open `app.R` and click **Run App**.

The scripts take under a minute in total. Each prints checks as it runs,
with the expected result written next to each check.

The cleaned data and figures are already in `output/`, so the dashboard
also runs without step 3. Running the scripts should reproduce the three
CSV files exactly, and the two figures to the eye.

## What is in each folder

| Folder or file | What it holds |
|---|---|
| `data/` | The raw files exactly as downloaded. Never edited. |
| `scripts/` | The code, numbered in the order it runs. `figure_functions.R` is not run on its own; `04_make_figures.R` and `app.R` both use it. |
| `output/` | Everything the scripts make: three CSV files and two figures. All of it can be remade by rerunning the scripts. |
| `app.R` | The dashboard. It reads `output/public_works_per_mile.csv`. |
| `codebook.md` | What each column means, and where each raw file came from. |
| `docs/decision_log.md` | Each decision made in the analysis, what was done and why. |
| `docs/verification_checks.md` | The numbers that were checked against the original sources, and how. |
| `docs/opra_log.md` | The public records request: wording, dates, responses. |
| `docs/source_files.tsv` | Address, size and checksum of every raw file. |
| `docs/session_info.txt` | The version of R and of each package at the last run. |
| `LICENSE` | The terms for reusing the code (MIT License). |

## Publishing the dashboard

The app needs only three files to run:
`app.R`, `scripts/figure_functions.R` and `output/public_works_per_mile.csv`.
To publish to shinyapps.io from RStudio without uploading the 22 MB raw
spreadsheet:

```r
rsconnect::deployApp(
  appFiles = c(
    "app.R",
    "scripts/figure_functions.R",
    "output/public_works_per_mile.csv"
  )
)
```

## Limits to know about

- These are budgeted amounts, not what was spent.
- "Public works" covers more than roads, and towns do not all file the
  same services under it.
- Road miles are from 2019 and are used for every year.
- Dollars are not adjusted for inflation.
- Towns with no budget on file with DCA for a year are missing for that
  year (36 of 564 in 2026).

More on each of these is in `docs/decision_log.md`.

## Who made this, and when

Made for STA 220 at The College of New Jersey by Zachary Kline with the
help of Claude AI. Claude wrote the code and made the analysis decisions
recorded in `docs/decision_log.md`. Last updated October 6, 2026.

## License

The code is released under the MIT License (see `LICENSE`). The files in
`data/` are public records of the State of New Jersey.
