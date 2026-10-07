# scripts/figure_functions.R
#
# The words for the three measures, and the two functions that draw the
# dashboard's two figures.
#
# This file is not run on its own. app.R and scripts/05_make_figures.R
# both source() it, so the figure in the dashboard and the copy saved in
# output/ are drawn by the same code and cannot drift apart.

library(tidyverse)

# The three measures, and the words used for each ---------------------------

# The dashboard can count dollars three ways. The first is the closest to
# "what was spent on roads." The other two are broader and come from
# budgets, but they exist for every year. See docs/decision_log.md,
# decisions 3 and 14.
#
# measure:      the name used in output/dollars_per_mile.csv
# verb, object: for sentences ("Ewing spent $9,054 ... on road upkeep")
# subtitle:     the line under a figure's title
# axis_label:   the label on the dollars axis
# towns_with:   how to describe the towns that have a number
measure_words <- tribble(
  ~measure,
  ~verb,
  ~object,
  ~subtitle,
  ~axis_label,
  ~towns_with,

  "Road upkeep, actual spending",
  "spent",
  "on road upkeep",
  "Road upkeep spending per mile of municipal road",
  "Dollars spent per mile of municipal road",
  "with a reported figure",

  "Public works, budgeted",
  "budgeted",
  "for public works",
  "Public works budget per mile of municipal road",
  "Budgeted dollars per mile of municipal road",
  "with a budget figure",

  "Public works plus solid waste disposal, budgeted",
  "budgeted",
  "for public works plus solid waste disposal",
  "Public works plus solid waste disposal budget per mile of municipal road",
  "Budgeted dollars per mile of municipal road",
  "with a budget figure"
)

road_upkeep <- "Road upkeep, actual spending"

# Colors -------------------------------------------------------------------

# Ewing is the subject, so Ewing is the only thing in color. Every other
# town and both benchmarks are shades of gray.
ewing_blue <- "#2a78d6"
other_bar_gray <- "#c3c2b7"
group_gray <- "#52514e"
state_gray <- "#898781"
grid_gray <- "#e1e0d9"

ewing_code <- "1102"

# A theme both figures share -----------------------------------------------

theme_dashboard <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.title.position = "plot",
      plot.caption = element_text(color = state_gray, hjust = 0),
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = grid_gray, linewidth = 0.3),
      axis.title = element_text(color = group_gray),
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_blank()
    )
}

# Figure 1: Ewing ranked against the comparison group ----------------------

# rank_rows:    one row per town in the comparison group, for one year and
#               one measure, with town_label and dollars_per_mile
# group_median: the median of dollars_per_mile in rank_rows
# state_median: the median across every New Jersey town with a number,
#               same year and measure
# group_name:   words for the comparison group, used in the legend
# x_label:      the label on the dollars axis ("spent" or "budgeted")
# state_name:   words for the statewide benchmark, used in the legend
plot_rank <- function(rank_rows, group_median, state_median, group_name,
                      title, subtitle, x_label,
                      state_name = "all NJ towns", caption = NULL) {
  rank_rows <- rank_rows |>
    mutate(
      is_ewing = muni_code == ewing_code,
      town_label = fct_reorder(town_label, dollars_per_mile)
    )

  # Ewing's value and the two benchmarks are written out in the legend.
  # (Labels placed next to the bar and the lines would overlap whenever
  # the numbers are close together, which they often are.) The "numbers"
  # tab of the dashboard lists every town's value.
  ewing_value <- rank_rows |>
    filter(is_ewing) |>
    pull(dollars_per_mile)

  ewing_label <- paste0(
    "Ewing township: ", scales::dollar(ewing_value, accuracy = 1)
  )

  medians <- tibble(
    line = c(
      paste0(
        "Median, ", group_name, ": ",
        scales::dollar(group_median, accuracy = 1)
      ),
      paste0(
        "Median, ", state_name, ": ",
        scales::dollar(state_median, accuracy = 1)
      )
    ),
    value = c(group_median, state_median)
  ) |>
    mutate(line = fct_inorder(line))

  median_colors <- c(group_gray, state_gray)
  names(median_colors) <- levels(medians$line)

  ggplot(rank_rows, aes(x = dollars_per_mile, y = town_label)) +
    geom_col(aes(fill = is_ewing), width = 0.65) +
    geom_vline(
      data = medians,
      aes(xintercept = value, color = line),
      linewidth = 0.8
    ) +
    # Only the blue (Ewing) bar gets a legend entry: breaks = "TRUE".
    scale_fill_manual(
      values = c("TRUE" = ewing_blue, "FALSE" = other_bar_gray),
      breaks = "TRUE",
      labels = ewing_label
    ) +
    scale_color_manual(values = median_colors) +
    # Ewing first, then the two medians, one legend entry per row so a
    # long entry is not cut off.
    guides(
      fill = guide_legend(order = 1),
      color = guide_legend(order = 2, ncol = 1)
    ) +
    scale_x_continuous(
      labels = scales::label_dollar(),
      expand = expansion(mult = c(0, 0.08))
    ) +
    # If two axis labels would overlap on a narrow screen, drop one.
    guides(x = guide_axis(check.overlap = TRUE)) +
    labs(
      title = str_wrap(title, 55),
      subtitle = str_wrap(subtitle, 70),
      caption = caption,
      x = x_label,
      y = NULL
    ) +
    theme_dashboard() +
    theme(
      panel.grid.major.y = element_blank(),
      legend.box = "vertical",
      legend.box.just = "left",
      legend.spacing.y = unit(0, "pt")
    )
}

# Figure 2: Ewing and the two medians over time -----------------------------

# trend_rows: one row per year per line, with columns year, line (the name
#             of the line) and dollars_per_mile. The lines must come in this
#             order: Ewing first, then the comparison group's median, then
#             the median of all New Jersey towns.
# y_label:    the label on the dollars axis
plot_trend <- function(trend_rows, title, subtitle, y_label,
                       caption = NULL) {
  trend_rows <- trend_rows |>
    mutate(line = fct_inorder(line))

  line_colors <- c(ewing_blue, group_gray, state_gray)
  names(line_colors) <- levels(trend_rows$line)

  # The latest value of each line goes in the legend, as in figure 1.
  # (Labels at the ends of the lines overlap when the lines end close
  # together.)
  last_points <- trend_rows |>
    filter(year == max(year))

  legend_labels <- paste0(
    last_points$line, ": ",
    scales::dollar(last_points$dollars_per_mile, accuracy = 1),
    " in ", last_points$year
  )
  names(legend_labels) <- last_points$line

  ggplot(trend_rows, aes(x = year, y = dollars_per_mile, color = line)) +
    geom_line(linewidth = 1) +
    geom_point(data = last_points, size = 3) +
    scale_color_manual(values = line_colors, labels = legend_labels) +
    guides(
      color = guide_legend(ncol = 1),
      x = guide_axis(check.overlap = TRUE)
    ) +
    scale_x_continuous(
      breaks = seq(min(trend_rows$year), max(trend_rows$year), by = 2)
    ) +
    # The axis starts at zero so the gap between the lines is not
    # exaggerated.
    scale_y_continuous(
      labels = scales::label_dollar(),
      limits = c(0, NA),
      expand = expansion(mult = c(0, 0.08))
    ) +
    labs(
      title = str_wrap(title, 55),
      subtitle = str_wrap(subtitle, 70),
      caption = caption,
      x = "Budget year",
      y = str_wrap(y_label, 26)
    ) +
    theme_dashboard() +
    theme(panel.grid.major.x = element_blank())
}
