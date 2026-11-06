# Lightweight automated tests for the statistical core.
# Run from the repository root with: Rscript tests/test_helpers.R

source("R/helpers.R")

assert <- function(condition, message) {
  if (!isTRUE(condition)) stop("TEST FAILED: ", message, call. = FALSE)
}

assert_equal <- function(actual, expected, message) {
  if (!isTRUE(all.equal(actual, expected))) {
    stop("TEST FAILED: ", message, call. = FALSE)
  }
}

specs <- population_specs()
assert(length(specs) == 11L, "the project should define 11 populations")
assert(all(vapply(specs, function(spec) is.function(spec$generator), logical(1))),
       "every population must provide a generator")

assert_equal(
  stable_pass_flags(c(FALSE, TRUE, TRUE, TRUE, FALSE), 3L),
  c(FALSE, TRUE, FALSE, FALSE, FALSE),
  "stable-pass detection should require consecutive passing values"
)

set.seed(42)
means_a <- replicate(250, mean(specs$normal$generator(10)))
set.seed(42)
means_b <- replicate(250, mean(specs$normal$generator(10)))
assert_equal(means_a, means_b, "a fixed seed should reproduce generated values")

small_study <- study_population(
  "normal", seed = 42L, B = 300L, n_values = c(2L, 5L, 10L),
  keep_samples = FALSE
)
assert(nrow(small_study$diagnostics) == 3L,
       "one diagnostic row should be produced for each candidate n")
assert(all(is.finite(small_study$diagnostics$simulated_sd)),
       "normal simulations should produce finite standard deviations")
assert(any(small_study$diagnostics$normal_enough),
       "the normal population should pass at least one candidate under the default screen")

strict <- NORMAL_CRITERIA
strict$abs_skewness_max <- 0.01
strict_study <- study_population(
  "normal", seed = 42L, B = 300L, n_values = c(2L, 5L, 10L),
  keep_samples = FALSE, criteria = strict
)
assert(!identical(strict_study$criteria, NORMAL_CRITERIA),
       "custom criteria should be carried through the study result")

message("All helper tests passed.")
