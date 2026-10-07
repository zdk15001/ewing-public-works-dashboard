# Decision log

The assignment asks for one entry per decision: what the decision was,
what the AI did, whether you agree or disagree, and why.

Claude AI made every decision below while building this example, and wrote
the first three parts of each entry. **The last line of each entry is left
blank on purpose.** Agreeing or disagreeing is the author's job, and an AI
tool cannot do it for you.

Decisions 1 to 13 are from the first version, which used only the budget
database and the road mileage. Decisions 14 to 19 were added on October 7,
2026, when the Census Bureau's road spending data became the main measure.
Where a later decision changes an earlier one, the earlier entry says so.

Budget numbers are from the 2026 budget year unless a year is given. Road
upkeep numbers are from fiscal year 2022.

---

## 1. Use budgeted amounts, not actual spending

**What the AI did.** Used the current-year appropriation in each year's
sheet (what the town planned to spend when it adopted the budget).

**Why, and what else was possible.** The database also has last year's
"modified appropriations," which is closer to what was spent. But that
column is one year behind, and the current-year column is the one the
council actually votes on. The dashboard says "budgeted" everywhere so
nobody reads it as spending.

**Changed in version 2.** This still holds for the two budget measures,
but they are no longer the main measure. The budget database has no
spending column at all, so actual spending had to come from another
source. See decision 14.

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

## 3. Offer two ways of counting the budget: public works, and public works plus solid waste

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

**What the AI did.** Marked the 44 towns whose population in the 2026
sheet (which is a 2025 estimate) is between 29,273 and 48,788 (Ewing:
39,030), and used the same 44 in every year. Five of the 44 have no 2026
budget on file, so the 2026 figure shows 39.

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
would be one more data source. The trend figure is meant for comparing
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
`scripts/04_join_and_check.R`.

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

## 14. Make actual road spending the main measure, and keep the budget as the broader one

**What the AI did.** Added a third data source, the Census Bureau's 2022
Census of Governments, and used its item E44 ("Regular Highways, Current
Operations"): what each town reported spending in fiscal year 2022 on
running and maintaining its streets and roads. The dashboard opens on that
measure. The two budget measures from decision 3 are still offered, and
the figure over time still uses the budget.

**Why, and what else was possible.** The first version answered "how much
does Ewing spend per mile of road?" with a number that was neither
spending nor only roads. For Ewing, road upkeep in 2022 ($993,000) was 36
percent of that year's public works budget ($2,757,900), and across the
222 towns with both numbers the middle town's share was 43 percent. The
budget database has no line for roads alone, so a better number had to
come from somewhere else. The other route was each town's own budget
document, which has a Streets and Roads line with what was actually paid.
That is the more direct source, but it means collecting and reading one
PDF per town from several dozen town websites. The Census Bureau has
already done a version of that work for every town, so it was used
instead. The budget measures were kept for two reasons: they are the only
ones filed every year, and seeing all three side by side shows how much
the answer depends on the definition. In 2022 the two kinds of measure
agree in direction but not closely (rank correlation 0.67 across the 222
towns), and Ewing is below the median on both.

**Agree or disagree, and why:**

## 15. Use only the numbers towns reported, not the Census Bureau's estimates

**What the AI did.** Every amount in the Census file carries a flag. For
road upkeep in New Jersey, 225 towns have a reported number (flag R) and
245 have an imputed one (flag I), which is an estimate the Census Bureau
filled in for a town that did not respond. Another 93 have no road item at
all. Only the 225 reported numbers are used. The rest are missing, and
that includes the 93, which are not counted as $0.

**Why, and what else was possible.** Imputed numbers exist so that state
totals come out right. They are not a record of what any one town spent,
and ranking Ewing against another town's estimate would be comparing a
fact with a guess. The cost is a smaller and less typical group: of the 44
towns of similar population, 31 reported. Larger towns reported more often
than small ones (34 of the 38 towns over 50,000 people, against 45 of the
187 under 5,000), so the statewide median is the median of towns that
reported. Keeping the estimates would not have changed the story: with
them, Ewing ranks 30th of 40 similar towns instead of 24th of 31, and the
group's median is $15,393 instead of $16,826.

The 93 towns with no road item are the harder call. Of those, 51 have a
reported number for every other item, so they answered the survey and
simply have nothing sorted under roads. Read literally, that is $0. It was
treated as missing instead, because a town such as New Brunswick does not
maintain its streets for nothing; its road costs are most likely under a
broader heading. Counting the 51 as $0 would lower the statewide median to
$14,788 (276 towns) and the similar-town median to $15,654 (33 towns), and
Ewing would still rank 24th.

**Agree or disagree, and why:**

## 16. Count upkeep only, and leave out road construction

**What the AI did.** Used current operations (item E44) and left out
construction (item F44), which is where repaving would be.

**Why, and what else was possible.** Only 79 New Jersey towns reported a
construction number for 2022, and only 4 of the 44 towns of similar
population. Ewing has none on file, though its own 2023 budget lists a
$1,000,000 road improvement program in its capital budget. Adding the two
items together would treat every town with no construction number as
having spent nothing on construction, which is plainly wrong for Ewing.
So the measure is called road upkeep and the dashboard says in several
places that repaving is not in it. This is the largest thing still
missing from the picture: for Ewing, the capital program is about as
large as a year of upkeep.

**Agree or disagree, and why:**

## 17. Match the Census names to municipal codes, with 10 matched by hand

**What the AI did.** The Census Bureau writes names in capitals with the
type spelled out ("EWING TOWNSHIP"). Lower-casing them and joining on
county plus name matches 553 of its 563 New Jersey municipalities. The
other 10 are listed one by one in `scripts/04_join_and_check.R`.

**Why, and what else was possible.** As with the road mileage (decision
9), there is no shared code. The Census file has a federal place code, but
the budget database does not, so a third table would have been needed to
connect them. Two of the hand matches need a second look: the Census
Bureau lists "PRINCETON MUNICIPALITY" where the budget database says
"Princeton borough," and "ORANGE CITY TOWNSHIP" for the City of Orange
Township. One town, Lafayette township in Sussex County, is not in the
Census file at all. The script checks that every Census town gets exactly
one code and no code is used twice.

**Agree or disagree, and why:**

## 18. Put 2022 spending over 2019 road miles, for the towns that are similar in 2026

**What the AI did.** Divided fiscal year 2022 road upkeep by March 2019
municipal road miles, and compared Ewing with the same 44 towns chosen in
decision 6 from 2026 population.

**Why, and what else was possible.** Each piece is the latest of its kind:
the Census Bureau asks every town only in years ending in 2 and 7, NJDOT
has published town mileage only for 2019, and the comparison group was
already fixed. Three different years in one number is not ideal. Road
miles change slowly, so the mileage gap matters least. The comparison
group could instead have been chosen from 2022 population, which would
change a few towns at the edge of the 25 percent band. There is no trend:
the Census Bureau's 2017 and 2018 figures for Ewing are estimates, not
reported numbers, and Ewing is not in the smaller yearly sample files for
2019, 2020, 2023 or 2024. (Those other years' files were looked at but
are not in `data/`.) About one town in twenty has a fiscal year that ends
in June, so "2022" is not the same twelve months for every town.

**Agree or disagree, and why:**

## 19. Use Ewing's own budget as a check, not as data

**What the AI did.** Read the Streets and Roads lines in Ewing's adopted
budgets on the township's website and compared them with the Census
figure. They are within 1 percent (see `docs/verification_checks.md`).
The budget figures are not in `data/` and no number on the dashboard
comes from them.

**Why, and what else was possible.** Ewing's budgets would give something
the Census file cannot: what the township actually paid for streets and
roads in every year, not only 2022. For 2021 to 2024 that was $998,001,
$986,307, $1,041,136 and $1,104,003. That would make a real trend line for
Ewing. It was left out for now because it is one town, so there would be
nothing to compare the line with, and because the rule of this project is
that every number on the dashboard traces to a raw file in `data/`. Adding
it properly means saving the budget PDFs in `data/` and reading them with
a script, the way the mileage PDFs are read.

**Agree or disagree, and why:**
