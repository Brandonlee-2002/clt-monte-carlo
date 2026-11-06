# Validate simulated standard deviations against analytic expectations.
# Run from the repository root with: Rscript R/run_validation.R

source("R/helpers.R")

student_id <- 6599L
B <- 5000L
n_values <- c(2L, 30L, 100L)
populations <- c(
  "normal", "uniform", "die", "exponential", "poisson",
  "binomial_small", "binomial_large", "nonidentical_bernoulli", "mixture"
)

studies <- lapply(populations, function(population) {
  study_population(
    population, seed = student_id, B = B, n_values = n_values,
    keep_samples = FALSE
  )
})
names(studies) <- populations

validation <- do.call(rbind, lapply(studies, function(study) {
  d <- study$diagnostics
  d <- d[is.finite(d$theoretical_sd) & d$theoretical_sd > 0, ]
  d$sd_ratio_error <- abs(d$sd_ratio - 1)
  d$analytic_check_pass <- d$sd_ratio_error <= 0.08
  d$population <- study$spec$label
  d[, c("population", "n", "simulated_sd", "theoretical_sd", "sd_ratio",
        "sd_ratio_error", "analytic_check_pass")]
}))

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)
write.csv(validation, "results/tables/analytic_validation.csv", row.names = FALSE)

if (!all(validation$analytic_check_pass)) {
  stop("At least one analytic standard-deviation validation failed.")
}

message("Analytic validation passed for ", nrow(validation), " checks.")
