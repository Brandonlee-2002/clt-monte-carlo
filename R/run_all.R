# Run this script from the repository root with: Rscript R/run_all.R

source("R/helpers.R")

student_id <- 6599  # Replace with the last four digits of your student ID.
B <- B_DEFAULT

dir.create("results", showWarnings = FALSE)
dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

studies <- run_all_studies(seed = student_id, B = B, keep_samples = FALSE)
summary <- summary_table(studies)
write.csv(summary, "results/tables/cross_distribution_summary.csv", row.names = FALSE)

diagnostics <- do.call(rbind, lapply(studies, function(study) {
  d <- study$diagnostics
  d$population <- study$spec$label
  d
}))
diagnostics <- diagnostics[, c("population", setdiff(names(diagnostics), "population"))]
write.csv(diagnostics, "results/tables/all_diagnostics.csv", row.names = FALSE)

message("Wrote results/tables/cross_distribution_summary.csv")
message("Wrote results/tables/all_diagnostics.csv")
