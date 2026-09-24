# Generate diagnostics for every integer sample size.
source("R/helpers.R")

student_id <- 6599L
B <- B_DEFAULT
FULL_N_VALUES <- 2:500

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

studies <- run_all_studies_full_grid(
  seed = student_id,
  B = B,
  n_values = FULL_N_VALUES,
  keep_samples = FALSE
)

diagnostics <- do.call(rbind, lapply(studies, function(study) {
  d <- study$diagnostics
  d$population <- study$spec$label
  d
}))
diagnostics <- diagnostics[, c("population", setdiff(names(diagnostics), "population"))]

write.csv(
  diagnostics,
  "results/tables/full_grid_diagnostics.csv",
  row.names = FALSE
)

summary <- summary_table(studies)
write.csv(
  summary,
  "results/tables/full_grid_summary.csv",
  row.names = FALSE
)

cat("Wrote", nrow(diagnostics), "diagnostic rows across",
    length(studies), "populations.\n")

