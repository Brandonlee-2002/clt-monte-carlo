# Generate the evidence visuals used on the project homepage.
#
# The script uses base R only and reads the same diagnostics produced by
# R/run_all.R. Run from the repository root with:
#   Rscript R/homepage_visuals.R

diagnostics_path <- "results/tables/all_diagnostics.csv"
if (!file.exists(diagnostics_path)) {
  stop("Missing ", diagnostics_path, ". Run R/run_all.R first.")
}

diagnostics <- read.csv(diagnostics_path, stringsAsFactors = FALSE)
diagnostics$n <- as.integer(diagnostics$n)
diagnostics$normal_enough <- as.logical(diagnostics$normal_enough)

asset_dirs <- c("assets/homepage", "docs/assets/homepage")
invisible(lapply(asset_dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

navy <- "#102a43"
slate <- "#52606d"
muted <- "#7b8794"
border <- "#d9e2ec"
surface <- "#ffffff"
background <- "#f7fafc"
teal <- "#0f766e"
teal_light <- "#d9f3f0"
orange <- "#d97706"
fail_fill <- "#e8edf2"
fail_text <- "#7b8794"
danger <- "#b42318"

xml_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x
}

svg_text <- function(x, y, text, size = 14, fill = navy, weight = 400,
                     anchor = "start", baseline = "alphabetic", opacity = 1) {
  sprintf(
    '<text x="%s" y="%s" fill="%s" font-family="Inter, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif" font-size="%s" font-weight="%s" text-anchor="%s" dominant-baseline="%s" opacity="%s">%s</text>',
    x, y, fill, size, weight, anchor, baseline, opacity, xml_escape(text)
  )
}

svg_rect <- function(x, y, width, height, fill = surface, stroke = "none",
                     stroke_width = 0, radius = 0, opacity = 1) {
  sprintf(
    '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s" stroke="%s" stroke-width="%s" opacity="%s"/>',
    x, y, width, height, radius, fill, stroke, stroke_width, opacity
  )
}

svg_line <- function(x1, y1, x2, y2, stroke = border, width = 1,
                     dash = NULL, marker_end = NULL) {
  dash_attr <- if (is.null(dash)) "" else sprintf(' stroke-dasharray="%s"', dash)
  marker_attr <- if (is.null(marker_end)) "" else sprintf(' marker-end="url(#%s)"', marker_end)
  sprintf(
    '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"%s%s/>',
    x1, y1, x2, y2, stroke, width, dash_attr, marker_attr
  )
}

svg_circle <- function(cx, cy, r, fill = teal, stroke = "none", width = 0) {
  sprintf('<circle cx="%s" cy="%s" r="%s" fill="%s" stroke="%s" stroke-width="%s"/>',
          cx, cy, r, fill, stroke, width)
}

write_svg <- function(filename, width, height, body) {
  content <- c(
    sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" role="img">', width, height, width, height),
    sprintf('<title>%s</title>', xml_escape(filename)),
    '<desc>Evidence visual from the CLT Monte Carlo simulation project.</desc>',
    body,
    '</svg>'
  )
  for (directory in asset_dirs) {
    writeLines(content, file.path(directory, filename), useBytes = TRUE)
  }
}

# 1. Experimental design pipeline -------------------------------------------

pipeline <- c(
  svg_rect(0, 0, 1200, 300, fill = background),
  svg_text(60, 44, "One experiment, repeated across every population", size = 24, weight = 700),
  svg_text(60, 70, "A common design makes the cross-distribution comparison defensible.", size = 14, fill = slate),
  '<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#7b8794"/></marker></defs>'
)

pipeline_steps <- data.frame(
  number = sprintf("%02d", 1:5),
  title = c("Choose a population", "Draw a sample", "Calculate the mean", "Repeat 10,000 times", "Apply the same screen"),
  detail = c("11 shapes and processes", "Candidate n = 2–500", "One mean per sample", "Monte Carlo sampling", "4 diagnostics + stability"),
  stringsAsFactors = FALSE
)
step_x <- c(60, 285, 510, 735, 960)
pipeline_title_lines <- list(
  c("Choose a", "population"),
  c("Draw a", "sample"),
  c("Calculate", "the mean"),
  c("Repeat 10,000", "times"),
  c("Apply the same", "screen")
)
for (i in seq_len(nrow(pipeline_steps))) {
  title_lines <- pipeline_title_lines[[i]]
  title_markup <- c(
    svg_text(step_x[i] + 18, 157, title_lines[1], size = 16, weight = 700),
    svg_text(step_x[i] + 18, 178, title_lines[2], size = 16, weight = 700)
  )
  pipeline <- c(
    pipeline,
    svg_rect(step_x[i], 105, 180, 118, fill = surface, stroke = border, stroke_width = 1, radius = 12),
    svg_text(step_x[i] + 18, 132, pipeline_steps$number[i], size = 12, fill = teal, weight = 700),
    title_markup,
    svg_text(step_x[i] + 18, 204, pipeline_steps$detail[i], size = 13, fill = slate),
    if (i < nrow(pipeline_steps)) svg_line(step_x[i] + 186, 164, step_x[i + 1] - 10, 164, stroke = muted, width = 1.5, marker_end = "arrow") else character(0)
  )
}
write_svg("experimental-design.svg", 1200, 300, pipeline)

# Shared ordering and selected thresholds for the result visuals ------------

n_values <- sort(unique(diagnostics$n))
populations <- unique(diagnostics$population)
short_labels <- c(
  "Standard Normal" = "Standard normal",
  "Continuous Uniform" = "Continuous uniform",
  "Six-Sided Die" = "Six-sided die",
  "Exponential(rate = 1)" = "Exponential",
  "Poisson(lambda = 1)" = "Poisson",
  "Binomial(size = 5, p = .10)" = "Binomial (rare success)",
  "Binomial(size = 20, p = .50)" = "Binomial (symmetric)",
  "Cauchy(location = 0, scale = 1)" = "Cauchy",
  "Dependent machine-failure process" = "Dependent process",
  "Non-identical Bernoulli process" = "Non-identical Bernoulli",
  "Two-component mixture" = "Two-component mixture"
)

first_stable_n <- function(rows) {
  rows <- rows[order(rows$n), , drop = FALSE]
  for (i in seq_len(nrow(rows))) {
    j <- i:min(i + 2L, nrow(rows))
    if (length(j) == 3L && all(rows$normal_enough[j])) return(rows$n[i])
  }
  NA_integer_
}

selected <- setNames(vapply(populations, function(population) {
  first_stable_n(diagnostics[diagnostics$population == population, , drop = FALSE])
}, integer(1)), populations)

# 2. Cross-distribution heatmap ---------------------------------------------

heatmap_width <- 1200
heatmap_height <- 590
heatmap_x <- 250
heatmap_y <- 125
cell_width <- 51
cell_height <- 30
heatmap <- c(
  svg_rect(0, 0, heatmap_width, heatmap_height, fill = background),
  svg_text(60, 42, "Normality screen across populations and sample sizes", size = 24, weight = 700),
  svg_text(60, 68, "Each cell applies the same four diagnostic thresholds; the orange outline marks the first stable pass.", size = 14, fill = slate),
  svg_text(heatmap_x - 20, 96, "sample size n", size = 13, fill = muted, weight = 700, anchor = "end")
)

for (j in seq_along(n_values)) {
  x <- heatmap_x + (j - 1) * cell_width
  heatmap <- c(heatmap, svg_text(x + cell_width / 2, heatmap_y - 14, n_values[j], size = 12, fill = slate, anchor = "middle"))
}

for (i in seq_along(populations)) {
  population <- populations[i]
  y <- heatmap_y + (i - 1) * cell_height
  rows <- diagnostics[diagnostics$population == population, , drop = FALSE]
  rows <- rows[match(n_values, rows$n), , drop = FALSE]
  heatmap <- c(heatmap, svg_text(heatmap_x - 18, y + cell_height / 2, short_labels[[population]], size = 13, fill = navy, anchor = "end", baseline = "middle"))
  for (j in seq_along(n_values)) {
    x <- heatmap_x + (j - 1) * cell_width
    fill <- if (isTRUE(rows$normal_enough[j])) teal_light else fail_fill
    text_fill <- if (isTRUE(rows$normal_enough[j])) teal else fail_text
    heatmap <- c(
      heatmap,
      svg_rect(x + 2, y + 2, cell_width - 4, cell_height - 4, fill = fill, radius = 5),
      svg_text(x + cell_width / 2, y + cell_height / 2 + 1, if (isTRUE(rows$normal_enough[j])) "✓" else "–", size = 14, fill = text_fill, weight = 700, anchor = "middle", baseline = "middle")
    )
    if (!is.na(selected[[population]]) && n_values[j] == selected[[population]]) {
      heatmap <- c(heatmap, svg_rect(x + 1, y + 1, cell_width - 2, cell_height - 2, fill = "none", stroke = orange, stroke_width = 2, radius = 6))
    }
  }
  threshold_label <- if (is.na(selected[[population]])) "no stable pass ≤ 500" else paste0("first stable n = ", selected[[population]])
  heatmap <- c(heatmap, svg_text(1068, y + cell_height / 2, threshold_label, size = 12, fill = if (is.na(selected[[population]])) danger else slate, baseline = "middle"))
}

legend_y <- heatmap_y + length(populations) * cell_height + 28
heatmap <- c(
  heatmap,
  svg_rect(heatmap_x, legend_y, 16, 16, fill = teal_light, radius = 4),
  svg_text(heatmap_x + 24, legend_y + 8, "passes all four criteria", size = 13, fill = slate, baseline = "middle"),
  svg_rect(heatmap_x + 190, legend_y, 16, 16, fill = fail_fill, radius = 4),
  svg_text(heatmap_x + 214, legend_y + 8, "fails at least one criterion", size = 13, fill = slate, baseline = "middle"),
  svg_rect(heatmap_x + 430, legend_y, 16, 16, fill = "none", stroke = orange, stroke_width = 2, radius = 4),
  svg_text(heatmap_x + 454, legend_y + 8, "first stable pass", size = 13, fill = slate, baseline = "middle")
)
write_svg("normality-heatmap.svg", heatmap_width, heatmap_height, heatmap)

# 3. Smallest defensible threshold comparison -------------------------------

dot_width <- 1200
dot_height <- 610
dot_x0 <- 260
dot_x1 <- 940
dot_y0 <- 120
dot_row_height <- 36
log_x <- function(n) dot_x0 + (log10(n) - log10(min(n_values))) / (log10(max(n_values)) - log10(min(n_values))) * (dot_x1 - dot_x0)
dot_ticks <- c(2, 5, 10, 30, 100, 500)

dotplot <- c(
  svg_rect(0, 0, dot_width, dot_height, fill = background),
  svg_text(60, 42, "Smallest defensible sample size by population", size = 24, weight = 700),
  svg_text(60, 68, "The threshold is population-specific; open markers indicate no stable pass in the investigated range.", size = 14, fill = slate),
  svg_text(dot_x0, 95, "sample size n · logarithmic scale", size = 13, fill = muted, weight = 700)
)

for (tick in dot_ticks) {
  x <- log_x(tick)
  dotplot <- c(
    dotplot,
    svg_line(x, dot_y0 - 15, x, dot_y0 + (length(populations) - 1) * dot_row_height + 12, stroke = border, width = 1, dash = "3 5"),
    svg_text(x, dot_y0 + length(populations) * dot_row_height + 28, tick, size = 12, fill = slate, anchor = "middle")
  )
}

for (i in seq_along(populations)) {
  population <- populations[i]
  y <- dot_y0 + (i - 1) * dot_row_height
  dotplot <- c(dotplot, svg_text(dot_x0 - 18, y, short_labels[[population]], size = 13, fill = navy, anchor = "end", baseline = "middle"))
  if (is.na(selected[[population]])) {
    x <- log_x(max(n_values))
    dotplot <- c(
      dotplot,
      svg_circle(x, y, 7, fill = background, stroke = danger, width = 2),
      svg_text(x + 16, y, "no stable pass", size = 12, fill = danger, baseline = "middle")
    )
  } else {
    x <- log_x(selected[[population]])
    dotplot <- c(
      dotplot,
      svg_circle(x, y, 7, fill = teal, stroke = surface, width = 2),
      svg_text(x + 14, y, paste0("n = ", selected[[population]]), size = 12, fill = teal, weight = 700, baseline = "middle")
    )
  }
}

dotplot <- c(
  dotplot,
  svg_line(dot_x0, dot_y0 + length(populations) * dot_row_height - 15, dot_x1, dot_y0 + length(populations) * dot_row_height - 15, stroke = muted, width = 1.2),
  svg_circle(70, dot_height - 35, 7, fill = teal, stroke = surface, width = 2),
  svg_text(86, dot_height - 35, "first stable pass", size = 13, fill = slate, baseline = "middle"),
  svg_circle(250, dot_height - 35, 7, fill = background, stroke = danger, width = 2),
  svg_text(266, dot_height - 35, "no stable pass through n = 500", size = 13, fill = slate, baseline = "middle")
)
write_svg("threshold-comparison.svg", dot_width, dot_height, dotplot)

message("Wrote homepage visuals to assets/homepage/ and docs/assets/homepage/")
