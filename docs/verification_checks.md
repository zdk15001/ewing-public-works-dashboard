# Verification checks

The assignment asks you to check numbers on the dashboard against the
original sources by hand and write down what you checked.

The checks in parts 1 to 5 were run by Claude AI on October 6 and 7, 2026,
while building this example. They were done by reading the raw files
directly, not by trusting the project's own R scripts. **Part 6 is left
for the author.** A check you did not do yourself is someone else's check.

## 1. The raw files are the files the agencies posted

All 24 raw files in `data/` have the same SHA-256 checksum as the files
served by nj.gov on October 6, 2026 and by census.gov on October 7, 2026.
The checksums are in `docs/source_files.tsv`.

## 2. Numbers on the dashboard, traced to a cell or a line in the source

| Number on the dashboard | Where it is in the original source | Source says | Match |
|---|---|---|---|
| Ewing public works budget, 2026: $3,345,500 | Budget database, sheet `2026 Summary`, row 290 (Ewing township), column DQ | 3345500 | Yes |
| Ewing solid waste disposal budget, 2026: $3,302,819 | Same sheet and row, column DW | 3302819 | Yes |
| Ewing public works budget, 2022: $2,757,900 | Sheet `2022 Summary`, Ewing township row, column DQ | 2757900 | Yes |
| Ewing public works budget, 2016: $3,543,667 | Sheet `2016 Summary`, row 291, column DQ | 3543666.55 | Yes, rounded |
| Ewing population used for "similar towns": 39,030 | Sheet `2026 Summary`, row 290, column I | 39030 | Yes |
| Ewing municipal road miles: 109.68 | `mileage_Mercer.pdf`, line "Ewing Twp", fourth number (Municipal) | 109.68 | Yes |
| Ewing road upkeep, fiscal year 2022: $993,000 | Census zip, `2022FinEstDAT_07152026modp.txt`, the line that starts `343021184022E44` | `343021184022E44         9932022R`: 993 thousand dollars, year 2022, flag R (reported) | Yes |
| That ID is Ewing | Census zip, `Fin_PID_2022.txt`, the line that starts `343021184022` | EWING TOWNSHIP, Mercer | Yes |

The column headers were checked too: in every yearly sheet, cell DQ5 reads
"Public Works," DW5 reads "Landfill / Solid Waste Disposal," and DL4 reads
"<year> General Budget Appropriations."

## 3. The arithmetic, done by hand

- $3,345,500 ÷ 109.68 miles = $30,502.37 per mile. The dashboard shows
  $30,502.
- ($3,345,500 + $3,302,819) ÷ 109.68 miles = $60,615.60 per mile. The
  dashboard shows $60,616.
- $993,000 ÷ 109.68 miles = $9,053.61 per mile. The dashboard shows
  $9,054.

## 4. The medians and ranks, recomputed a second way

The medians and ranks cannot be checked against a single cell, because
they come from hundreds of towns. They were recomputed from the three raw
sources with a separate program written in Python (reading the spreadsheet
with openpyxl, the PDFs with pdftotext and the Census text files straight
from the zip), using none of this project's R code. Every figure matched.

| Year, what was counted | Figure | R scripts and dashboard | Separate Python check |
|---|---|---|---|
| 2022, road upkeep | Towns in New Jersey with a reported figure | 225 | 225 |
| | Ewing, dollars per mile | $9,054 | $9,054 |
| | Median, all 225 New Jersey towns | $18,358 | $18,358 |
| | Median, 31 towns of similar population | $16,826 | $16,826 |
| | Ewing's rank among the 31 | 24th | 24th |
| | Median, 8 Mercer County towns | $13,094 | $13,094 |
| | Ewing's rank among the 8 | 7th | 7th |
| 2026, public works | Towns in New Jersey with a usable number | 527 | 527 |
| | Median, all New Jersey towns | $51,700 | $51,700 |
| | Median, 39 towns of similar population | $50,633 | $50,633 |
| | Ewing's rank among the 39 | 30th | 30th |
| | Ewing's rank among 11 Mercer County towns | 8th | 8th |
| 2026, public works plus solid waste | Ewing, dollars per mile | $60,616 | $60,616 |
| | Median, all New Jersey towns | $63,740 | $63,740 |
| | Median, towns of similar population | $64,185 | $64,185 |
| | Ewing's rank among the 39 | 23rd | 23rd |
| 2022, public works plus solid waste | Ewing, dollars per mile | $48,896 | $48,896 |
| | Median, 11 Mercer County towns | $54,540 | $54,540 |
| | Median, all 547 New Jersey towns | $57,083 | $57,083 |
| 2016, public works | Median, all 529 New Jersey towns | $37,160 | $37,160 |
| | Median, towns of similar population | $36,828 | $36,828 |

The two programs share the lists of hand-matched town names (16 for the
road mileage, 10 for the Census file), so this check would not catch a
wrong pair in those lists. See decisions 9 and 17 in
`docs/decision_log.md`.

Other checks that run every time the scripts run:

- Every yearly sheet has 565 towns through 2021 and 564 after, and no town
  twice.
- In every county, the road miles read from the PDF add up exactly to
  NJDOT's own County Total row, and the 21 county totals match the
  separate statewide PDF.
- Every NJDOT town is matched to exactly one municipal code, and the join
  adds no rows (6,210 before and after).
- The road upkeep amounts read for New Jersey's towns add up exactly to
  the Census Bureau's own state totals, which are in a separate file in
  the same zip: $287,850 thousand for cities and $272,944 thousand for
  townships.
- Every Census town is matched to exactly one municipal code.

The dashboard was also opened in a browser and each control was changed in
turn. The summary sentence, both figures and the table changed as
expected and agreed with the numbers above.

## 5. The Census figure for Ewing, against Ewing's own budget

The Census Bureau sorts each town's spending into its own categories, so
its road number is only as good as that sorting. For Ewing it was checked
against the township's adopted budgets, which are posted on the township
website (ecode360.com/EW1628, Financial Documents). Each budget shows, for
the year before, what was "Paid or Charged" on every line. These PDFs
were read on October 7, 2026. They are not in `data/`.

| Year | Streets & Roads, Salary & Wages (26-290-1), paid or charged | Streets & Roads, Other Expenses (26-290-2), paid or charged | The two together | Census Bureau, road upkeep |
|---|---|---|---|---|
| 2021 | $915,643.54 | $82,357.65 | $998,001.19 | not collected |
| 2022 | $896,376.97 | $89,930.20 | $986,307.17 | $993,000 |
| 2023 | $944,857.26 | $96,278.39 | $1,041,135.65 | not collected |
| 2024 | $995,866.20 | $108,136.33 | $1,104,002.53 | not collected |

The 2021 to 2023 rows are from the adopted budgets for 2022 to 2024. The
2024 row is from the introduced 2025 budget; no adopted 2025 budget was
posted.

For 2022 the Census figure is $6,693 higher than the two budget lines
together, a difference of 0.7 percent. The cause of the difference was
not found. It could be a later, final figure from the township's annual
financial statement, or a small related item. What the check does show is
that the Census number for Ewing is the Streets and Roads salaries plus
other expenses, and nothing else of any size: not benefits, not vehicle
maintenance, not the capital road program.

No other town's Census figure was checked this way.

## What was not checked

- Whether the population estimates in the budget database match the Census
  Bureau's (see decision 11).
- Whether 2019 road miles are still right for 2026.
- Whether any town besides Ewing files its public works costs the way the
  comparison assumes, or labels its road spending so that the Census
  Bureau counts it as roads. Some reported road figures are too small to
  be a town's whole road cost (under $500 per mile).
- What the Census Bureau's road item includes beyond what was seen for
  Ewing. Its classification manual was not read.
- The scripts were run on R 4.3.3 on Linux only. They have not been run on
  Windows or a Mac, or with newer package versions.
- The app has not been published, so the publishing step in the README is
  untested.

## 6. Your turn

Check these four yourself and write down what you find.

| What to check | How | What you found |
|---|---|---|
| Ewing's 2022 road upkeep | Unzip `data/census_gov_finance/2022_Individual_Unit_File.zip`. Open `2022FinEstDAT_07152026modp.txt` in a text editor and search for `343021184022E44`. Read the amount (in thousands) and the flag at the end of the line. | |
| The same number in Ewing's own budget | On the township website, open the 2023 adopted budget. Find the two Streets & Roads lines and add the "Paid or Charged" amounts for 2022. | |
| Ewing's municipal road miles | Open `data/njdot_mileage/mileage_Mercer.pdf`. Find "Ewing Twp." Read the Municipal column. | |
| One other town in the first figure | Pick any bar. Find its two numbers the same way, divide, and compare with the "numbers" tab. | |
