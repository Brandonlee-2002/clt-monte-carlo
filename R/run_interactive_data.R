# Generate compact visual data for the interactive every-n explorer.
source("R/helpers.R")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The interactive explorer requires the jsonlite R package.")
}

student_id <- 6599L
B <- B_DEFAULT
FULL_N_VALUES <- 2:500
HISTOGRAM_BINS <- 30L
QQ_POINTS <- 31L

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("docs/assets", recursive = TRUE, showWarnings = FALSE)

diagnostics <- read.csv(
  "results/tables/full_grid_diagnostics.csv",
  stringsAsFactors = FALSE
)
diagnostics$n <- as.integer(diagnostics$n)
diagnostics$normal_enough <- as.logical(diagnostics$normal_enough)
diagnostics$stable_pass <- as.logical(diagnostics$stable_pass)

specs <- population_specs()
summary <- read.csv(
  "results/tables/full_grid_summary.csv",
  stringsAsFactors = FALSE
)

make_histogram <- function(sample_means, bins = HISTOGRAM_BINS) {
  finite_values <- sample_means[is.finite(sample_means)]
  limits <- quantile(finite_values, probs = c(0.005, 0.995), names = FALSE)
  if (!all(is.finite(limits)) || diff(limits) <= 0) {
    limits <- range(finite_values)
  }
  if (!all(is.finite(limits)) || diff(limits) <= 0) {
    limits <- c(limits[1] - 0.5, limits[1] + 0.5)
  }
  padding <- max(diff(limits) * 0.05, 1e-6)
  breaks <- seq(limits[1] - padding, limits[2] + padding,
                length.out = bins + 1L)
  clipped_values <- pmin(pmax(finite_values, breaks[1]), breaks[length(breaks)])
  bin_index <- findInterval(
    clipped_values,
    breaks,
    rightmost.closed = TRUE,
    all.inside = TRUE
  )
  counts <- tabulate(bin_index, nbins = bins)
  list(
    centers = (breaks[-1] + breaks[-length(breaks)]) / 2,
    counts = as.integer(counts),
    lower = breaks[1],
    upper = breaks[length(breaks)]
  )
}

make_qq <- function(sample_means, points = QQ_POINTS) {
  probabilities <- seq(0.01, 0.99, length.out = points)
  theoretical <- qnorm(probabilities)
  observed <- as.numeric(
    quantile(sample_means, probs = probabilities, names = FALSE)
  )
  center <- mean(sample_means)
  spread <- sd(sample_means)
  standardized <- if (is.finite(spread) && spread > 0) {
    (observed - center) / spread
  } else {
    rep(0, length(observed))
  }
  list(
    theoretical = theoretical,
    observed = standardized
  )
}

population_payload <- vector("list", length(specs))
names(population_payload) <- names(specs)

for (population in names(specs)) {
  spec <- specs[[population]]
  set.seed(student_id)
  observations <- full_grid_observations(
    population = population,
    spec = spec,
    B = B,
    max_n = max(FULL_N_VALUES)
  )
  cumulative <- t(apply(observations, 1, cumsum))
  population_diagnostics <- diagnostics[
    diagnostics$population == spec$label,
    ,
    drop = FALSE
  ]
  selected_row <- summary[summary$population == spec$label, , drop = FALSE]
  selected_n <- if (nrow(selected_row) && !is.na(
    selected_row$smallest_n_judged_normal[1]
  )) {
    as.integer(selected_row$smallest_n_judged_normal[1])
  } else {
    NA_integer_
  }

  entries <- vector("list", length(FULL_N_VALUES))
  names(entries) <- as.character(FULL_N_VALUES)

  for (i in seq_along(FULL_N_VALUES)) {
    n <- FULL_N_VALUES[i]
    sample_means <- cumulative[, n] / n
    row <- population_diagnostics[population_diagnostics$n == n, , drop = FALSE]
    entries[[i]] <- list(
      n = n,
      normal_enough = isTRUE(row$normal_enough[1]),
      stable_pass = isTRUE(row$stable_pass[1]),
      diagnostics = list(
        skewness = row$skewness[1],
        excess_kurtosis = row$excess_kurtosis[1],
        qq_correlation = row$qq_correlation[1],
        qq_rmse = row$qq_rmse[1],
        simulated_mean = row$simulated_mean[1],
        simulated_sd = row$simulated_sd[1],
        theoretical_mean = row$theoretical_mean[1],
        theoretical_sd = row$theoretical_sd[1]
      ),
      histogram = make_histogram(sample_means),
      qq = make_qq(sample_means)
    )
  }

  population_payload[[population]] <- list(
    id = population,
    label = spec$label,
    description = spec$description,
    selected_n = selected_n,
    by_n = entries
  )
}

payload <- list(
  metadata = list(
    seed = student_id,
    repetitions = B,
    n_min = min(FULL_N_VALUES),
    n_max = max(FULL_N_VALUES),
    histogram_bins = HISTOGRAM_BINS,
    qq_points = QQ_POINTS,
    criteria = NORMAL_CRITERIA
  ),
  populations = population_payload
)

output_paths <- c(
  "results/tables/full_grid_visuals.json",
  "docs/assets/full-grid-visuals.json"
)
for (output_path in output_paths) {
  jsonlite::write_json(
    payload,
    output_path,
    auto_unbox = TRUE,
    digits = NA,
    pretty = FALSE,
    na = "null"
  )
}

cat("Wrote interactive visual data to:\n")
cat(paste(" -", output_paths, collapse = "\n"), "\n")
