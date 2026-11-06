# Explore seed, Monte Carlo size, and decision-rule sensitivity.
# Run from the repository root with: Rscript R/run_sensitivity.R

source("R/helpers.R")

student_id <- 6599L
seeds <- c(student_id, 2026L)
B_values <- c(1000L, 3000L)
criteria_variants <- list(
  default = NORMAL_CRITERIA,
  looser_shape = modifyList(
    NORMAL_CRITERIA,
    list(abs_skewness_max = 0.30, abs_excess_kurtosis_max = 0.50)
  ),
  stricter_shape = modifyList(
    NORMAL_CRITERIA,
    list(abs_skewness_max = 0.15, abs_excess_kurtosis_max = 0.20,
         qq_correlation_min = 0.997, qq_rmse_max = 0.06)
  )
)

rows <- list()
row_index <- 1L
for (criteria_name in names(criteria_variants)) {
  for (seed in seeds) {
    for (B in B_values) {
      studies <- run_all_studies(
        seed = seed, B = B, keep_samples = FALSE,
        criteria = criteria_variants[[criteria_name]]
      )
      summary <- summary_table(studies)
      summary$criteria <- criteria_name
      summary$seed <- seed
      summary$B <- B
      rows[[row_index]] <- summary
      row_index <- row_index + 1L
    }
  }
}

sensitivity <- do.call(rbind, rows)
sensitivity <- sensitivity[, c(
  "criteria", "seed", "B",
  setdiff(names(sensitivity), c("criteria", "seed", "B"))
)]

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
write.csv(sensitivity, "results/tables/sensitivity_summary.csv", row.names = FALSE)
message("Wrote results/tables/sensitivity_summary.csv")
