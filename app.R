# app.R
#
# The dashboard. To run it: open ewing-public-works-dashboard.Rproj, open
# this file, and click "Run App" (or run shiny::runApp() in the console).
#
# The app does no data cleaning. It reads one file that the scripts made:
#   output/public_works_per_mile.csv   (made by scripts/03_join_and_check.R)
# and it draws its figures with the functions in scripts/figure_functions.R.

# Load packages, functions and data ----------------------------------------

library(shiny)
library(tidyverse)
source("scripts/figure_functions.R")

per_mile <- read_csv(
  "output/public_works_per_mile.csv",
  col_types = cols(
    muni_code = col_character(),
    municipality = col_character(),
    county = col_character(),
    town_label = col_character(),
    what_counted = col_character(),
    similar_population = col_logical(),
    .default = col_double()
  )
)

years <- sort(unique(per_mile$year), decreasing = TRUE)

# The page: what the user sees ---------------------------------------------

ui <- fluidPage(
  titlePanel("Ewing Township: public works budget per mile of road"),
  p(
    strong("Who this is for: "),
    "members of the Ewing Township Council. ",
    strong("The question: "),
    "for each mile of road the township maintains, how much does Ewing ",
    "budget for public works, and how does that compare with similar towns ",
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
      radioButtons(
        "counted",
        "What to count",
        choices = c("Public works", "Public works plus solid waste disposal")
      ),
      selectInput(
        "year",
        "Budget year (first figure and the numbers tab)",
        choices = years
      ),
      helpText(
        "Why 'what to count' matters: towns budget trash differently. Some",
        "put it under Public Works. Others, including Ewing, list it on a",
        "separate line called Landfill / Solid Waste Disposal. Switch this",
        "to see how much Ewing's ranking depends on that."
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
            "Each bar is one town's budget for the year, divided by the ",
            "miles of road the town itself maintains. Ewing is the blue ",
            "bar. The two vertical lines are the median town in the ",
            "comparison group and the median of all New Jersey towns with ",
            "a budget on file. A longer bar means more dollars budgeted ",
            "per mile."
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
            "The same measure for every budget year from 2016 to 2026. ",
            "The blue line is Ewing. The gray lines are the median of the ",
            "comparison group and the median of all New Jersey towns. ",
            "Dollars are not adjusted for inflation, so compare Ewing with ",
            "the gray lines in the same year, not one year with another."
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
          h4("Where the numbers come from"),
          tags$ul(
            tags$li(
              strong("Budgets: "),
              "New Jersey Department of Community Affairs, Division of ",
              "Local Government Services, User Friendly Budget Database. ",
              "One sheet per budget year, 2016 to 2026. File dated ",
              "September 1, 2026, downloaded October 6, 2026. We use the ",
              "General Budget Appropriations columns for Public Works and ",
              "for Landfill / Solid Waste Disposal. These are budgeted ",
              "amounts, not what was actually spent."
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
              "Public works is not only roads. DCA's category also covers ",
              "sewers, stormwater, recycling, vehicle maintenance and, in ",
              "some towns, trash pickup. Two towns can differ because they ",
              "file the same service under different headings."
            ),
            tags$li(
              "Road miles are from 2019, the only year NJDOT has published ",
              "by town. A town that has added roads since then looks ",
              "slightly more expensive per mile than it is."
            ),
            tags$li(
              "Towns with no User Friendly Budget on file for a year are ",
              "left out of that year. In 2026 that is 36 of 564 towns, ",
              "including Trenton."
            ),
            tags$li(
              "Towns of similar population are the 44 towns whose 2026 ",
              "population is within 25 percent of Ewing's (39,030 in the ",
              "database). The same towns are used for every year."
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
            "yet sent. No public records request data is in this ",
            "dashboard. The request is in docs/opra_log.md."
          ),
          h4("Code and data"),
          p(
            "Everything needed to rebuild this dashboard is in the ",
            "project's GitHub repository: the two raw files, the scripts, ",
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
server <- function(input, output) {

  # Every New Jersey town with a usable number, for the chosen way of
  # counting, all years. Re-runs when "What to count" changes.
  usable <- reactive({
    per_mile |>
      filter(what_counted == input$counted, !is.na(dollars_per_mile))
  })

  # The same rows, narrowed to the chosen comparison group. Re-runs when
  # usable() changes or when "Compare Ewing to" changes.
  group_rows <- reactive({
    if (input$group == "similar") {
      usable() |> filter(similar_population)
    } else {
      usable() |> filter(county == "Mercer")
    }
  })

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
    group_rows() |>
      filter(year == chosen_year()) |>
      arrange(desc(dollars_per_mile)) |>
      mutate(rank = row_number())
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
      "In ", chosen_year(), ", Ewing budgeted ",
      scales::dollar(ewing$dollars_per_mile, accuracy = 1),
      " per mile of municipal road for ", str_to_lower(input$counted),
      ". That ranks ", scales::ordinal(ewing$rank), " highest of the ",
      nrow(rank_rows()), " ", group_name(), " with a budget on file. ",
      "The group's median is ",
      scales::dollar(median(rank_rows()$dollars_per_mile), accuracy = 1),
      ", and the median of all ", nrow(state_rows()),
      " New Jersey towns with data is ",
      scales::dollar(median(state_rows()$dollars_per_mile), accuracy = 1),
      "."
    )
  })

  # Figure 1. Its height grows with the number of towns, so the bars stay
  # the same thickness whether the group has 11 towns or 44.
  output$rank_plot <- renderPlot(
    {
      plot_rank(
        rank_rows(),
        group_median = median(rank_rows()$dollars_per_mile),
        state_median = median(state_rows()$dollars_per_mile),
        group_name = group_name(),
        title = paste0("Ewing and ", group_name(), ", ", chosen_year()),
        subtitle = paste(input$counted, "budget per mile of municipal road")
      )
    },
    height = function() {
      250 + 22 * nrow(rank_rows())
    },
    res = 96
  )

  output$rank_source <- renderText({
    paste0(
      "Sources: NJ Department of Community Affairs, User Friendly Budget ",
      "Database, adopted ", chosen_year(), " budgets (file dated September ",
      "1, 2026). NJ Department of Transportation, Mileage by Municipality ",
      "and Jurisdiction, March 2019."
    )
  })

  # Figure 2. It uses every year, so it does not depend on the year menu.
  output$trend_plot <- renderPlot(
    {
      group_line <- if (input$group == "similar") {
        "Similar-size towns (median)"
      } else {
        "Mercer County towns (median)"
      }

      trend_rows <- bind_rows(
        usable() |>
          filter(muni_code == ewing_code) |>
          mutate(line = "Ewing township") |>
          select(year, line, dollars_per_mile),
        group_rows() |>
          group_by(year) |>
          summarize(dollars_per_mile = median(dollars_per_mile)) |>
          mutate(line = group_line),
        usable() |>
          group_by(year) |>
          summarize(dollars_per_mile = median(dollars_per_mile)) |>
          mutate(line = "All NJ towns (median)")
      )

      plot_trend(
        trend_rows,
        title = "Ewing and the two medians, 2016 to 2026",
        subtitle = paste0(
          input$counted,
          " budget per mile of municipal road, not adjusted for inflation"
        )
      )
    },
    res = 96
  )

  # The numbers tab: every bar in figure 1, as a table.
  output$table_title <- renderText({
    paste0(
      input$counted, " budget per mile of municipal road, ", group_name(),
      ", ", chosen_year()
    )
  })

  output$rank_table <- renderTable(
    {
      rank_rows() |>
        transmute(
          Rank = rank,
          Town = town_label,
          `Budget` = scales::dollar(budget_dollars, accuracy = 1),
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
    paste0(
      "Budget: NJ DCA User Friendly Budget Database, adopted ",
      chosen_year(), " budgets (file dated September 1, 2026). Road miles: ",
      "NJDOT, March 2019. Median of this group: ",
      scales::dollar(median(rank_rows()$dollars_per_mile), accuracy = 1),
      ". Median of all ", nrow(state_rows()), " New Jersey towns with data: ",
      scales::dollar(median(state_rows()$dollars_per_mile), accuracy = 1), "."
    )
  })
}

# Start the app -------------------------------------------------------------

shinyApp(ui, server)
