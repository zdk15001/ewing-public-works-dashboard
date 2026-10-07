# app.R
#
# The dashboard. To run it: open ewing-public-works-dashboard.Rproj, open
# this file, and click "Run App" (or run shiny::runApp() in the console).
#
# The app does no data cleaning. It reads one file that the scripts made:
#   output/dollars_per_mile.csv   (made by scripts/04_join_and_check.R)
# and it draws its figures with the functions in scripts/figure_functions.R.

# Load packages, functions and data ----------------------------------------

library(shiny)
library(tidyverse)
source("scripts/figure_functions.R")

per_mile <- read_csv(
  "output/dollars_per_mile.csv",
  col_types = cols(
    muni_code = col_character(),
    municipality = col_character(),
    county = col_character(),
    town_label = col_character(),
    measure = col_character(),
    similar_population = col_logical(),
    .default = col_double()
  )
)

# The page: what the user sees ---------------------------------------------

ui <- fluidPage(
  titlePanel("Ewing Township: dollars for roads, per mile of road"),
  p(
    strong("Who this is for: "),
    "members of the Ewing Township Council. ",
    strong("The question: "),
    "for each mile of road the township maintains, how much does Ewing ",
    "spend on road upkeep, and how does that compare with similar towns ",
    "and with the rest of New Jersey?"
  ),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      radioButtons(
        "group",
        "Compare Ewing to",
        choices = c(
          "Towns of similar population" = "similar",
          "Mercer County towns" = "mercer"
        )
      ),
      # The values are the names used in the data file. The labels say
      # what each one is in plain words.
      radioButtons(
        "measure",
        "What to count",
        choiceNames = list(
          "Road upkeep: what was actually spent (2022 only)",
          "All public works: what was budgeted (2016 to 2026)",
          "All public works plus trash disposal: what was budgeted"
        ),
        choiceValues = measure_words$measure
      ),
      selectInput(
        "year",
        "Year (first figure and the numbers tab)",
        choices = 2022
      ),
      helpText(
        "Why 'what to count' matters: road upkeep is the closest of the",
        "three to money spent on roads, but it is collected from every",
        "town only once every five years. Public works budgets are filed",
        "every year, but they also cover sewers, recycling, vehicle",
        "maintenance and more, and towns do not all put trash in the same",
        "place. Switch between them to see how much Ewing's ranking",
        "depends on the choice."
      )
    ),
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel(
          "Compare",
          h4(textOutput("summary")),
          # On a phone the figure keeps a readable width and scrolls
          # sideways inside its own box instead of being squeezed.
          div(
            style = "overflow-x: auto;",
            div(
              style = "min-width: 640px;",
              plotOutput("rank_plot", height = "auto")
            )
          ),
          p(
            strong("What this shows. "),
            textOutput("rank_text", inline = TRUE)
          ),
          p(em(textOutput("rank_source", inline = TRUE))),
          hr(),
          div(
            style = "overflow-x: auto;",
            div(
              style = "min-width: 640px;",
              plotOutput("trend_plot", height = "460px")
            )
          ),
          p(
            strong("What this shows. "),
            "The budget for every year from 2016 to 2026, per mile of ",
            "municipal road: public works alone, or with solid waste ",
            "disposal added if that is what you chose to count. The blue ",
            "line is Ewing. The gray lines are the median of the ",
            "comparison group and the median of all New Jersey towns with ",
            "a budget figure that year. This figure uses the budget ",
            "because it is the only one of the measures that exists for ",
            "every year. It counts more than roads, so read it for ",
            "direction, not for the cost of roads. Dollars are not ",
            "adjusted for inflation, so compare Ewing with the gray lines ",
            "in the same year, not one year with another."
          ),
          p(em(
            "Sources: NJ Department of Community Affairs, User Friendly ",
            "Budget Database, adopted budgets for 2016 to 2026 (file dated ",
            "September 1, 2026). NJ Department of Transportation, Mileage ",
            "by Municipality and Jurisdiction, March 2019. The 2019 road ",
            "miles are used for every year."
          ))
        ),
        tabPanel(
          "The numbers",
          h4(textOutput("table_title")),
          tableOutput("rank_table"),
          p(em(textOutput("table_source", inline = TRUE)))
        ),
        tabPanel(
          "About the data",
          h4("Three ways to count, from narrowest to broadest"),
          tags$ul(
            tags$li(
              strong("Road upkeep, actual spending. "),
              "What the town reported spending in its 2022 fiscal year on ",
              "running and maintaining its streets and roads. It is the ",
              "Census Bureau's item for current operations of non-toll ",
              "highways. For Ewing it is within 1 percent of the Streets ",
              "and Roads lines (salaries and wages plus other expenses) ",
              "in the township's own budget. It leaves out construction, ",
              "such as repaving. For Ewing it also leaves out the pensions ",
              "and health insurance of the road crew, which the township ",
              "budgets on separate lines."
            ),
            tags$li(
              strong("Public works, budgeted. "),
              "What the town planned to spend on its whole public works ",
              "category when it adopted its budget. By the state's ",
              "definition that category also covers sanitary sewers, ",
              "stormwater, solid waste, recycling, vehicle maintenance and ",
              "other public works functions."
            ),
            tags$li(
              strong("Public works plus solid waste disposal, budgeted. "),
              "The same, plus the separate budget line for landfill and ",
              "solid waste disposal. Some towns, including Ewing, budget ",
              "trash disposal there and others fold it into public works."
            )
          ),
          h4("Where the numbers come from"),
          tags$ul(
            tags$li(
              strong("Road spending: "),
              "U.S. Census Bureau, 2022 Census of Governments, finance ",
              "public use files, individual unit file (item E44). File ",
              "dated August 4, 2026, downloaded October 7, 2026. Only ",
              "numbers the town itself reported are used: 225 of New ",
              "Jersey's 563 municipalities in the file."
            ),
            tags$li(
              strong("Budgets: "),
              "New Jersey Department of Community Affairs, Division of ",
              "Local Government Services, User Friendly Budget Database. ",
              "One sheet per budget year, 2016 to 2026. File dated ",
              "September 1, 2026, downloaded October 6, 2026. We use the ",
              "General Budget Appropriations columns for Public Works and ",
              "for Landfill / Solid Waste Disposal."
            ),
            tags$li(
              strong("Road miles: "),
              "New Jersey Department of Transportation, Mileage by ",
              "Municipality and Jurisdiction, March 2019 (21 county PDFs), ",
              "downloaded October 6, 2026. We use the Municipal column: ",
              "roads the town itself owns. State, county and toll roads ",
              "inside the town are left out."
            )
          ),
          h4("Read these before quoting a number"),
          tags$ul(
            tags$li(
              "None of the three is the full cost of roads. Repaving is ",
              "usually paid for through the capital budget, with borrowed ",
              "money and state grants, and is in none of them."
            ),
            tags$li(
              "The road upkeep figures depend on how each town labels its ",
              "budget lines. A town that pays its road crew from a general ",
              "public works line will show little or nothing under roads. ",
              "The figure was checked against the town's own budget for ",
              "Ewing only."
            ),
            tags$li(
              "Only 225 of the 563 New Jersey towns in the Census file ",
              "have a road upkeep figure they reported themselves. Another ",
              "245 did not answer, and the Census Bureau's estimates for ",
              "them are not used. The other 93 have no road line at all. ",
              "More than half of those answered the rest of the survey, ",
              "which suggests their road costs are filed under a broader ",
              "heading. Larger towns reported more often than small ones, ",
              "so the statewide median describes the towns with a ",
              "reported figure, not all towns."
            ),
            tags$li(
              "The Census Bureau publishes these town-by-town records as ",
              "the inputs to its state totals. It has not reviewed them as ",
              "a record over time for any one government, it warns that ",
              "they can contain reporting and coding errors, and it has ",
              "not reviewed this analysis. The conclusions here are ours, ",
              "not the Census Bureau's."
            ),
            tags$li(
              "Road miles are from 2019, the only year NJDOT has published ",
              "by town, and they count the length of a road, not its ",
              "width. A four-lane road and a cul-de-sac of the same ",
              "length count the same."
            ),
            tags$li(
              "Budgets are plans. A town with no User Friendly Budget on ",
              "file for a year is left out of that year, and so is a town ",
              "whose public works line is blank or zero. In 2026, 36 of ",
              "564 towns have no budget on file, including Trenton."
            ),
            tags$li(
              "Towns of similar population are the 44 towns whose ",
              "population in the 2026 budget database (a 2025 estimate) is ",
              "within 25 percent of Ewing's 39,030. The same towns are ",
              "used for every year and every way of counting."
            ),
            tags$li(
              "The median is the middle town. Half are above it and half ",
              "are below. We use it instead of the average because a few ",
              "towns with very few road miles have very large numbers."
            )
          ),
          h4("Public records request"),
          p(
            "A request under the Open Public Records Act for the ",
            "township's street paving records has been drafted but not ",
            "yet sent. It would start to fill the largest gap here: how ",
            "much road the township repaves each year. No public records ",
            "request data is in this dashboard. The request is in ",
            "docs/opra_log.md."
          ),
          h4("Code and data"),
          p(
            "Everything needed to rebuild this dashboard is in the ",
            "project's GitHub repository: the raw files, the scripts, ",
            "a codebook, the decision log and the verification checks. ",
            a(
              "github.com/zdk15001/ewing-public-works-dashboard",
              href = "https://github.com/zdk15001/ewing-public-works-dashboard"
            )
          )
        )
      )
    )
  )
)

# The server: how the page reacts to the three controls ---------------------

# A reactive() is a recipe. Shiny re-runs it only when one of the inputs
# it uses changes, and everything that uses the result updates after it.
server <- function(input, output, session) {

  # The year menu offers only the years the chosen measure has: 2022 for
  # road upkeep, 2016 to 2026 for the two budget measures. When the
  # measure changes, the menu resets to that measure's latest year.
  observeEvent(input$measure, {
    years_available <- per_mile |>
      filter(measure == input$measure) |>
      distinct(year) |>
      arrange(desc(year)) |>
      pull(year)

    updateSelectInput(
      session,
      "year",
      choices = years_available,
      selected = max(years_available)
    )
  })

  # The words that go with the chosen measure ("spent" or "budgeted", and
  # so on). One row of the measure_words table in figure_functions.R.
  words <- reactive({
    measure_words |>
      filter(measure == input$measure)
  })

  # Every New Jersey town with a usable number for the chosen measure, all
  # years. Re-runs when "What to count" changes.
  usable <- reactive({
    per_mile |>
      filter(measure == input$measure, !is.na(dollars_per_mile))
  })

  # Narrow any set of rows to the chosen comparison group.
  keep_group <- function(rows) {
    if (input$group == "similar") {
      rows |> filter(similar_population)
    } else {
      rows |> filter(county == "Mercer")
    }
  }

  # Words for the chosen group, used in titles and sentences.
  group_name <- reactive({
    if (input$group == "similar") {
      "towns of similar population"
    } else {
      "Mercer County towns"
    }
  })

  # selectInput() hands back text ("2026"), so turn it into a number.
  chosen_year <- reactive({
    as.numeric(input$year)
  })

  # The comparison group in the chosen year, highest first, with ranks.
  rank_rows <- reactive({
    rows <- keep_group(usable()) |>
      filter(year == chosen_year()) |>
      arrange(desc(dollars_per_mile)) |>
      mutate(rank = row_number())

    # For a moment after the measure changes, the year menu still holds a
    # year the new measure does not have. req() waits until it catches up.
    req(nrow(rows) > 0)
    rows
  })

  # All New Jersey towns in the chosen year, for the statewide median.
  state_rows <- reactive({
    usable() |>
      filter(year == chosen_year())
  })

  # The sentence above the first figure.
  output$summary <- renderText({
    ewing <- rank_rows() |>
      filter(muni_code == ewing_code)

    paste0(
      "In ", chosen_year(), ", Ewing ", words()$verb, " ",
      scales::dollar(ewing$dollars_per_mile, accuracy = 1),
      " per mile of municipal road ", words()$object,
      ". That ranks ", scales::ordinal(ewing$rank), " highest of the ",
      nrow(rank_rows()), " ", group_name(), " ", words()$towns_with, ". ",
      "The group's median is ",
      scales::dollar(median(rank_rows()$dollars_per_mile), accuracy = 1),
      ", and the median of all ", nrow(state_rows()),
      " New Jersey towns ", words()$towns_with, " is ",
      scales::dollar(median(state_rows()$dollars_per_mile), accuracy = 1),
      "."
    )
  })

  # Figure 1. Its height grows with the number of towns, so the bars stay
  # the same thickness whether the group has 8 towns or 44.
  output$rank_plot <- renderPlot(
    {
      state_name <- if (input$measure == road_upkeep) {
        paste("all NJ towns", words()$towns_with)
      } else {
        "all NJ towns"
      }

      plot_rank(
        rank_rows(),
        group_median = median(rank_rows()$dollars_per_mile),
        state_median = median(state_rows()$dollars_per_mile),
        group_name = group_name(),
        title = paste0("Ewing and ", group_name(), ", ", chosen_year()),
        subtitle = words()$subtitle,
        x_label = words()$axis_label,
        state_name = state_name
      )
    },
    height = function() {
      250 + 22 * nrow(rank_rows())
    },
    res = 96
  )

  output$rank_text <- renderText({
    if (input$measure == road_upkeep) {
      paste0(
        "Each bar is what one town reported spending in its 2022 fiscal ",
        "year on running and maintaining its streets and roads, divided ",
        "by the miles of road the town itself maintains. Ewing is the ",
        "blue bar. The two vertical lines are the median town in the ",
        "comparison group and the median of all New Jersey towns that ",
        "reported a figure. Repaving and other construction are not ",
        "included, and towns that did not report are left out."
      )
    } else {
      paste0(
        "Each bar is one town's budget for the year, divided by the ",
        "miles of road the town itself maintains. Ewing is the blue ",
        "bar. The two vertical lines are the median town in the ",
        "comparison group and the median of all New Jersey towns with a ",
        "budget figure. This is a budget for all of public works, not ",
        "only roads, and it is a plan, not what was spent."
      )
    }
  })

  output$rank_source <- renderText({
    if (input$measure == road_upkeep) {
      paste0(
        "Sources: U.S. Census Bureau, 2022 Census of Governments, ",
        "individual unit file, reported values only (file dated August ",
        "4, 2026). NJ Department of Transportation, Mileage by ",
        "Municipality and Jurisdiction, March 2019."
      )
    } else {
      paste0(
        "Sources: NJ Department of Community Affairs, User Friendly ",
        "Budget Database, adopted ", chosen_year(), " budgets (file dated ",
        "September 1, 2026). NJ Department of Transportation, Mileage by ",
        "Municipality and Jurisdiction, March 2019."
      )
    }
  })

  # Figure 2. Road upkeep exists for one year only, so the figure over
  # time always uses a budget measure: the chosen one, or plain public
  # works when road upkeep is chosen. It does not use the year menu.
  trend_measure <- reactive({
    if (input$measure == road_upkeep) {
      "Public works, budgeted"
    } else {
      input$measure
    }
  })

  output$trend_plot <- renderPlot(
    {
      trend_words <- measure_words |>
        filter(measure == trend_measure())

      budget_rows <- per_mile |>
        filter(measure == trend_measure(), !is.na(dollars_per_mile))

      group_line <- if (input$group == "similar") {
        "Similar-size towns (median)"
      } else {
        "Mercer County towns (median)"
      }

      trend_rows <- bind_rows(
        budget_rows |>
          filter(muni_code == ewing_code) |>
          mutate(line = "Ewing township") |>
          select(year, line, dollars_per_mile),
        keep_group(budget_rows) |>
          group_by(year) |>
          summarize(dollars_per_mile = median(dollars_per_mile)) |>
          mutate(line = group_line),
        budget_rows |>
          group_by(year) |>
          summarize(dollars_per_mile = median(dollars_per_mile)) |>
          mutate(line = "All NJ towns (median)")
      )

      plot_trend(
        trend_rows,
        title = "The budget over time, 2016 to 2026",
        subtitle = paste0(
          trend_words$subtitle, ", not adjusted for inflation"
        ),
        y_label = trend_words$axis_label
      )
    },
    res = 96
  )

  # The numbers tab: every bar in figure 1, as a table.
  output$table_title <- renderText({
    paste0(words()$subtitle, ", ", group_name(), ", ", chosen_year())
  })

  output$rank_table <- renderTable(
    {
      rank_rows() |>
        transmute(
          Rank = rank,
          Town = town_label,
          Dollars = scales::dollar(dollars, accuracy = 1),
          `Municipal road miles` = scales::number(
            municipal_miles,
            accuracy = 0.01
          ),
          `Dollars per mile` = scales::dollar(dollars_per_mile, accuracy = 1)
        )
    },
    align = "llrrr",
    striped = TRUE
  )

  output$table_source <- renderText({
    dollars_source <- if (input$measure == road_upkeep) {
      paste0(
        "Dollars: U.S. Census Bureau, 2022 Census of Governments, ",
        "reported values only (file dated August 4, 2026). "
      )
    } else {
      paste0(
        "Dollars: NJ DCA User Friendly Budget Database, adopted ",
        chosen_year(), " budgets (file dated September 1, 2026). "
      )
    }

    paste0(
      dollars_source,
      "Road miles: NJDOT, March 2019. Median of this group: ",
      scales::dollar(median(rank_rows()$dollars_per_mile), accuracy = 1),
      ". Median of all ", nrow(state_rows()), " New Jersey towns ",
      words()$towns_with, ": ",
      scales::dollar(median(state_rows()$dollars_per_mile), accuracy = 1), "."
    )
  })
}

# Start the app -------------------------------------------------------------

shinyApp(ui, server)
