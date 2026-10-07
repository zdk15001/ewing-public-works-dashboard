# Decision log

The assignment asks for one entry per decision: what the decision was,
what the AI did, whether you agree or disagree, and why.

Claude AI made every decision below while building this example, and wrote
the first three parts of each entry. **The last line of each entry is left
blank on purpose.** Agreeing or disagreeing is the author's job, and an AI
tool cannot do it for you.

All numbers are from the 2026 budget year unless a year is given.

---

## 1. Use budgeted amounts, not actual spending

**What the AI did.** Used the current-year appropriation in each year's
sheet (what the town planned to spend when it adopted the budget).

**Why, and what else was possible.** The database also has last year's
"modified appropriations," which is closer to what was spent. But that
column is one year behind, and the current-year column is the one the
council actually votes on. The dashboard says "budgeted" everywhere so
nobody reads it as spending.

**Agree or disagree, and why:**

## 2. Use the general budget, not total appropriations

**What the AI did.** Used "Public Works" under General Budget
Appropriations (column DQ), not under Total Appropriations by Service Type
(column CS).

**Why, and what else was possible.** Total appropriations include utility
funds, such as a town-owned water or sewer system. Most towns do not own
one, so including them would compare unlike things. The choice matters:
for Ewing the total is $5,633,084 and the general budget figure is
$3,345,500.

**Agree or disagree, and why:**

## 3. Offer two ways of counting: public works, and public works plus solid waste

**What the AI did.** Kept both, and made "what to count" a control on the
dashboard instead of choosing one.

**Why, and what else was possible.** DCA's Public Works category can
include trash, and it also has a separate line for Landfill / Solid Waste
Disposal. Towns split their trash costs between the two differently: 168
of the 528 towns with a public works number put $0 on the separate line.
Ewing puts $3,302,819 there, about as much as its whole public works line.
With public works alone, Ewing is below 73 percent of New Jersey towns.
With the two together, it is below 55 percent. A dashboard that showed
only the first number would overstate how unusual Ewing is, so the reader
gets to see both. Adding the lines together is still not a perfect fix:
it does not help with towns where residents hire private haulers.

**Agree or disagree, and why:**

## 4. Divide by municipal road miles, from 2019, in every year

**What the AI did.** Used NJDOT's Municipal column (109.68 miles for
Ewing), not Total (152.14 miles), and applied the March 2019 figure to
every budget year from 2016 to 2026.

**Why, and what else was possible.** A town's public works department
maintains the town's own roads. State, county and toll roads inside the
town are someone else's budget. March 2019 is the only by-town mileage
found on NJDOT's site. Road networks change slowly, but a town that has
added roads since 2019 looks a little more expensive per mile than it is.

**Agree or disagree, and why:**

## 5. Treat $0 for public works, and 0 road miles, as missing

**What the AI did.** In 14 town-years a town reported exactly $0 for
public works. Those became missing in a new column, with the original
column kept. Tavistock borough, with 0.00 municipal road miles, also has
no dollars-per-mile figure.

**Why, and what else was possible.** No town maintains roads for nothing,
so a zero most likely means the section was not filled in or the spending
was filed under another heading. Leaving the zeros in would pull the
medians down slightly. Dividing by zero miles gives infinity, which cannot
be ranked. None of the 14 is Ewing or a town in either comparison
group.

**Agree or disagree, and why:**

## 6. "Similar towns" means population within 25 percent of Ewing's

**What the AI did.** Marked the 44 towns whose 2026 population is between
29,273 and 48,788 (Ewing: 39,030), and used the same 44 in every year.
Five of the 44 have no 2026 budget on file, so the 2026 figure shows 39.

**Why, and what else was possible.** Population is the measure of
"similar" a council member would expect. Fixing the group once means the
trend line follows the same towns instead of a group that changes each
year. Other reasonable choices: towns with a similar number of road miles,
a similar population density, or a similar score on the state's Municipal
Revitalization Index. The 25 percent cutoff is arbitrary; 20 or 30 would
also be defensible and would change the list.

**Agree or disagree, and why:**

## 7. Compare with the median, not the average

**What the AI did.** Both benchmarks (the comparison group and all of New
Jersey) are medians.

**Why, and what else was possible.** A handful of dense towns with very few
miles of their own road have enormous figures. Edgewater budgets $745,006
per mile on 6.38 miles. Those towns pull the statewide average up to
$66,099, against a median of $51,700. The median describes the typical
town. Note that this is the median of towns, with each town counting once.
It is not the statewide total budget divided by statewide miles, which
would be a third number.

**Agree or disagree, and why:**

## 8. Do not adjust for inflation

**What the AI did.** Left every dollar figure in the dollars of its own
budget year, and said so in the trend figure's subtitle and caption.

**Why, and what else was possible.** Adjusting needs a price index, which
would be a third data source. The trend figure is meant for comparing
Ewing with the two medians in the same year, and that comparison is fair
without adjusting. It is not fair for comparing 2016 with 2026: a flat
line in this figure is a budget that shrank in real terms. If the
dashboard were ever used to talk about change over time, this decision
should be reversed.

**Agree or disagree, and why:**

## 9. Match the two sources on county and name, with 16 names matched by hand

**What the AI did.** The budget database identifies towns by code and name
("Ewing township"); NJDOT uses only a name ("Ewing Twp"). The script
rewrites NJDOT's abbreviations and joins on county plus name. That matches
548 of 564 towns. The other 16 are listed one by one in
`scripts/03_join_and_check.R`.

**Why, and what else was possible.** There is no shared code to join on.
County has to be in the key because names repeat across counties. Three of
the 16 need a second look, because NJDOT gives a different type of
municipality: it lists "Fairfield Boro" and "West Caldwell Boro" in Essex
County, where the budget database has townships, and "Princeton" where
the database still says "Princeton borough." Each was matched because it
is the only town of that name in its county. The script checks that every
NJDOT town gets exactly one code and no code is used twice.

**Agree or disagree, and why:**

## 10. Leave out towns with no budget on file, year by year

**What the AI did.** A town with no User Friendly Budget on file for a year
is missing for that year only. In 2026 that is 36 towns, including
Trenton. Counts of towns are shown in the dashboard's summary sentence.

**Why, and what else was possible.** The alternative was to keep only towns
with a number in all eleven years, which would give cleaner trend lines
but drop about three towns in ten (394 of 565 have all eleven years). Because the group changes a little
each year, a small part of any year-to-year movement in the medians is
towns entering and leaving, not budgets changing.

**Agree or disagree, and why:**

## 11. Use the population figures in the budget database as they are

**What the AI did.** Used the population estimate printed in each year's
sheet, and only to decide which towns are of similar size.

**Why, and what else was possible.** Ewing's population in the database
moves in a way that looks odd: 37,402 in the 2022 sheet, 34,589 in the
2023 sheet, 39,030 in the 2026 sheet. That could be different vintages of
Census estimates, or how students in campus housing are counted. It was
**not** checked against the Census Bureau. It does not touch the
dollars-per-mile figures, but it does decide where the 25 percent band
falls, and so which towns are in the comparison group.

**Agree or disagree, and why:**

## 12. Keep the dashboard to dollars per mile

**What the AI did.** Left out dollars per resident, employees per mile and
public works as a share of the budget, all of which the same data could
support.

**Why, and what else was possible.** The assignment asks for a narrow
dashboard, and the question is about roads. The reader should know the
choice of denominator matters, though: per resident, Ewing ranks lower
still.

**Agree or disagree, and why:**

## 13. How the figures are drawn

**What the AI did.** Ewing is the only thing in color; other towns and
both medians are gray. The first figure's height grows with the number of
towns. The trend figure's axis starts at zero. Values are written in the
legend instead of on every bar, and a separate tab lists every number in
a table.

**Why, and what else was possible.** The figure is about one town, so one
color. Starting the axis at zero keeps the gap between Ewing and the
medians in proportion. The table means no number can be read only by
squinting at a bar.

**Agree or disagree, and why:**
