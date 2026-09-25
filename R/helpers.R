# Shared functions for the CLT Monte Carlo project.
# This file uses base R only, so the simulations are portable and easy to audit.

B_DEFAULT <- 10000L
N_VALUES <- c(2L, 5L, 10L, 15L, 20L, 30L, 40L, 50L,
              75L, 100L, 150L, 200L, 300L, 500L)

# A sample-mean distribution is classified as approximately normal only when
# all four shape criteria pass. The plots and scientific interpretation remain
# part of the final decision; this is a transparent, reproducible screen.
NORMAL_CRITERIA <- list(
  abs_skewness_max = 0.20,
  abs_excess_kurtosis_max = 0.30,
  qq_correlation_min = 0.995,
  qq_rmse_max = 0.08,
  consecutive_passes = 3L
)

moment_skewness <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 3L || sd(x) == 0) return(NA_real_)
  centered <- x - mean(x)
  mean(centered^3) / mean(centered^2)^(3 / 2)
}

moment_excess_kurtosis <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 4L || sd(x) == 0) return(NA_real_)
  centered <- x - mean(x)
  mean(centered^4) / mean(centered^2)^2 - 3
}

qq_diagnostics <- function(x) {
  x <- sort(x[is.finite(x)])
  p <- (seq_along(x) - 0.5) / length(x)
  theoretical <- qnorm(p)
  observed <- mean(x) + sd(x) * theoretical
  list(
    qq_correlation = cor(x, theoretical),
    qq_rmse = sqrt(mean((x - observed)^2)) / sd(x)
  )
}

# Construct the synthetic age-at-death distribution supplied in
# Inference/custom_age_at_death_distribution_monte_carlo.html.
custom_age_at_death_distribution <- function() {
  age <- 0:100
  early_component <- 0.045 * exp(-age / 5)
  adult_component <- 0.030 * exp(-0.5 * ((age - 65) / 10)^2)
  weight <- early_component + adult_component
  probability <- weight / sum(weight)

  data.frame(
    age = age,
    probability = probability,
    percent = 100 * probability
  )
}

# Sampling function corresponding to the rdeath() function in the reference
# HTML. Sampling is with replacement from the normalized discrete distribution.
rdeath <- function(n, distribution = custom_age_at_death_distribution()) {
  sample(
    x = distribution$age,
    size = n,
    replace = TRUE,
    prob = distribution$probability
  )
}

population_specs <- function() {
  list(
    normal = list(
      label = "Standard Normal",
      description = "Independent N(0, 1) observations; the sample mean is normal for every n.",
      expectation = "Because normality is preserved by averaging, even n = 2 should look normal.",
      generator = function(n) rnorm(n, mean = 0, sd = 1),
      mean = 0, sd = 1,
      sd_mean = function(n) 1 / sqrt(n)
    ),
    uniform = list(
      label = "Continuous Uniform",
      description = "Independent Uniform(0, 1) observations; bounded and symmetric but not normal.",
      expectation = "Symmetry should make convergence relatively fast, although very small n will retain bounded shape.",
      generator = function(n) runif(n, min = 0, max = 1),
      mean = 0.5, sd = sqrt(1 / 12),
      sd_mean = function(n) sqrt(1 / 12) / sqrt(n)
    ),
    die = list(
      label = "Six-Sided Die",
      description = "Independent discrete uniform values 1 through 6.",
      expectation = "The discrete support should become smoother with averaging; symmetry should help convergence.",
      generator = function(n) sample(1:6, size = n, replace = TRUE),
      mean = 3.5, sd = sqrt(35 / 12),
      sd_mean = function(n) sqrt(35 / 12) / sqrt(n)
    ),
    exponential = list(
      label = "Exponential(rate = 1)",
      description = "Independent exponentially distributed observations with strong right skew.",
      expectation = "Right skew should persist for small n and decline gradually as n increases.",
      generator = function(n) rexp(n, rate = 1),
      mean = 1, sd = 1,
      sd_mean = function(n) 1 / sqrt(n)
    ),
    poisson = list(
      label = "Poisson(lambda = 1)",
      description = "Independent event counts with a discrete, right-skewed population.",
      expectation = "The skew should decrease with n, but the small lambda makes early sample means visibly discrete.",
      generator = function(n) rpois(n, lambda = 1),
      mean = 1, sd = 1,
      sd_mean = function(n) 1 / sqrt(n)
    ),
    binomial_small = list(
      label = "Binomial(size = 5, p = .10)",
      description = "Independent, highly discrete and right-skewed observations.",
      expectation = "The rare-success structure should require a larger n than the symmetric populations.",
      generator = function(n) rbinom(n, size = 5, prob = 0.10),
      mean = 0.5, sd = sqrt(0.45),
      sd_mean = function(n) sqrt(0.45) / sqrt(n)
    ),
    binomial_large = list(
      label = "Binomial(size = 20, p = .50)",
      description = "Independent, discrete but symmetric observations.",
      expectation = "Symmetry should produce quick convergence despite the discrete population.",
      generator = function(n) rbinom(n, size = 20, prob = 0.50),
      mean = 10, sd = sqrt(5),
      sd_mean = function(n) sqrt(5) / sqrt(n)
    ),
    cauchy = list(
      label = "Cauchy(location = 0, scale = 1)",
      description = "Independent observations with no finite mean or variance; the usual CLT does not apply.",
      expectation = "No stable normal sampling distribution should emerge from ordinary sample means.",
      generator = function(n) rcauchy(n, location = 0, scale = 1),
      mean = NA_real_, sd = NA_real_,
      sd_mean = function(n) NA_real_
    ),
    dependent_machine = list(
      label = "Dependent machine-failure process",
      description = "An AR(1)-style dependent process: Gaussian correlation rho = .80 is transformed to exponential marginals.",
      expectation = "Positive dependence reduces effective sample size, so convergence should be slower than for independent exponential observations.",
      generator = function(n) {
        rho <- 0.80
        z <- numeric(n)
        z[1] <- rnorm(1)
        if (n > 1L) {
          for (i in 2:n) z[i] <- rho * z[i - 1] + sqrt(1 - rho^2) * rnorm(1)
        }
        -log(pmax(pnorm(z), .Machine$double.xmin))
      },
      mean = 1, sd = 1,
      sd_mean = function(n) NA_real_
    ),
    nonidentical_bernoulli = list(
      label = "Non-identical Bernoulli process",
      description = "Within each sample, Bernoulli probabilities vary linearly from .50 to .90.",
      expectation = "Bounded observations should still average toward a bell shape, but the observations are not identically distributed.",
      generator = function(n) {
        probabilities <- seq(0.50, 0.90, length.out = n)
        rbinom(length(probabilities), size = 1, prob = probabilities)
      },
      mean = 0.70, sd = NA_real_,
      sd_mean = function(n) {
        probabilities <- seq(0.50, 0.90, length.out = n)
        sqrt(sum(probabilities * (1 - probabilities))) / n
      }
    ),
    mixture = {
      death_distribution <- custom_age_at_death_distribution()
      death_mean <- with(death_distribution, sum(age * probability))
      death_sd <- with(
        death_distribution,
        sqrt(sum((age - death_mean)^2 * probability))
      )

      list(
        label = "Custom age-at-death mixture",
        description = paste(
          "A discrete distribution on ages 0 through 100 formed by normalizing",
          "an early-life exponential component and an adult bell-shaped component",
          "centered at age 65."
        ),
        expectation = paste(
          "The two-component shape combines an early-life decline with an adult",
          "peak, so sample means should converge more slowly than symmetric populations",
          "but eventually approach normality because the distribution has finite mean and variance."
        ),
        generator = function(n) rdeath(n, death_distribution),
        mean = death_mean,
        sd = death_sd,
        sd_mean = function(n) death_sd / sqrt(n)
      )
    }
  )
}

diagnose_sample_means <- function(sample_means, n, spec) {
  qq <- qq_diagnostics(sample_means)
  skew <- moment_skewness(sample_means)
  kurt <- moment_excess_kurtosis(sample_means)
  passes <- is.finite(skew) &&
    abs(skew) <= NORMAL_CRITERIA$abs_skewness_max &&
    is.finite(kurt) &&
    abs(kurt) <= NORMAL_CRITERIA$abs_excess_kurtosis_max &&
    is.finite(qq$qq_correlation) &&
    qq$qq_correlation >= NORMAL_CRITERIA$qq_correlation_min &&
    is.finite(qq$qq_rmse) &&
    qq$qq_rmse <= NORMAL_CRITERIA$qq_rmse_max

  expected_sd <- spec$sd_mean(n)
  data.frame(
    n = n,
    simulated_mean = mean(sample_means),
    simulated_sd = sd(sample_means),
    theoretical_mean = spec$mean,
    theoretical_sd = expected_sd,
    mean_error = if (is.finite(spec$mean)) mean(sample_means) - spec$mean else NA_real_,
    sd_ratio = if (is.finite(expected_sd) && expected_sd > 0) sd(sample_means) / expected_sd else NA_real_,
    skewness = skew,
    excess_kurtosis = kurt,
    qq_correlation = qq$qq_correlation,
    qq_rmse = qq$qq_rmse,
    normal_enough = passes,
    stringsAsFactors = FALSE
  )
}

study_population <- function(population, seed = 6599L, B = B_DEFAULT,
                             n_values = N_VALUES, keep_samples = TRUE) {
  specs <- population_specs()
  spec <- specs[[population]]
  if (is.null(spec)) stop("Unknown population: ", population)

  samples <- vector("list", length(n_values))
  diagnostics <- vector("list", length(n_values))

  for (i in seq_along(n_values)) {
    n <- n_values[i]
    # The same student seed is set before each experiment, as required by the
    # handout. This makes every n reproducible and easy to rerun independently.
    set.seed(seed)
    sample_means <- replicate(B, mean(spec$generator(n)))
    if (keep_samples) samples[[i]] <- sample_means
    diagnostics[[i]] <- diagnose_sample_means(sample_means, n, spec)
  }

  diagnostics <- do.call(rbind, diagnostics)
  diagnostics$stable_pass <- vapply(seq_len(nrow(diagnostics)), function(i) {
    j <- i:min(i + NORMAL_CRITERIA$consecutive_passes - 1L, nrow(diagnostics))
    length(j) == NORMAL_CRITERIA$consecutive_passes && all(diagnostics$normal_enough[j])
  }, logical(1))

  selected <- which(diagnostics$stable_pass)[1]
  selected_n <- if (is.na(selected)) NA_integer_ else diagnostics$n[selected]
  if (keep_samples) names(samples) <- as.character(n_values)

  list(
    population = population,
    spec = spec,
    seed = seed,
    B = B,
    n_values = n_values,
    diagnostics = diagnostics,
    samples = samples,
    selected_n = selected_n,
    criteria = NORMAL_CRITERIA
  )
}

reproducibility_check <- function(population, n, seed_a = 6599L,
                                  seed_b = 2026L, B = B_DEFAULT) {
  spec <- population_specs()[[population]]
  set.seed(seed_a)
  a <- replicate(B, mean(spec$generator(n)))
  set.seed(seed_b)
  b <- replicate(B, mean(spec$generator(n)))
  data.frame(
    seed = c(seed_a, seed_b),
    simulated_mean = c(mean(a), mean(b)),
    simulated_sd = c(sd(a), sd(b)),
    skewness = c(moment_skewness(a), moment_skewness(b)),
    excess_kurtosis = c(moment_excess_kurtosis(a), moment_excess_kurtosis(b)),
    stringsAsFactors = FALSE
  )
}

run_all_studies <- function(seed = 6599L, B = B_DEFAULT,
                            n_values = N_VALUES, keep_samples = FALSE) {
  populations <- names(population_specs())
  studies <- lapply(populations, function(population) {
    study_population(population, seed = seed, B = B,
                     n_values = n_values, keep_samples = keep_samples)
  })
  names(studies) <- populations
  studies
}

# Generate the reusable B x max_n observation matrix used by the fine-grid
# analysis and by the interactive explorer. Keeping this path construction in
# one function makes the two published views use the same simulation design.
full_grid_observations <- function(population, spec, B, max_n) {
  # These populations are iid, so one B x max_n matrix can be reused for all n.
  iid_populations <- c(
    "normal", "uniform", "die", "exponential", "poisson",
    "binomial_small", "binomial_large", "cauchy", "mixture"
  )

  if (population %in% iid_populations) {
    return(matrix(
      replicate(max_n, spec$generator(B)),
      nrow = B,
      ncol = max_n
    ))
  }

  if (population == "nonidentical_bernoulli") {
    probabilities <- seq(0.50, 0.90, length.out = max_n)
    uniforms <- matrix(runif(B * max_n), nrow = B, ncol = max_n)
    return(sweep(uniforms, 2, probabilities, "<") * 1)
  }

  if (population == "dependent_machine") {
    rho <- 0.80
    z <- matrix(0, nrow = B, ncol = max_n)
    z[, 1] <- rnorm(B)
    if (max_n > 1L) {
      for (j in 2:max_n) {
        z[, j] <- rho * z[, j - 1] + sqrt(1 - rho^2) * rnorm(B)
      }
    }
    return(-log(pmax(pnorm(z), .Machine$double.xmin)))
  }

  stop("No full-grid generator defined for: ", population)
}

# Fine-grid version used for the exhaustive sensitivity analysis. Instead of
# running a separate 10,000-repetition experiment for every n, this function
# generates one reusable path of length max(n_values) for each repetition and
# obtains every sample mean from cumulative sums. The normality diagnostics and
# the stable-pass rule are otherwise identical to study_population().
study_population_full_grid <- function(population, seed = 6599L,
                                       B = B_DEFAULT, n_values = 2:500,
                                       keep_samples = FALSE) {
  specs <- population_specs()
  spec <- specs[[population]]
  if (is.null(spec)) stop("Unknown population: ", population)

  n_values <- sort(unique(as.integer(n_values)))
  if (!length(n_values) || any(!is.finite(n_values)) || any(n_values < 1L)) {
    stop("n_values must contain positive integers")
  }

  max_n <- max(n_values)
  set.seed(seed)

  observations <- full_grid_observations(population, spec, B, max_n)

  cumulative <- t(apply(observations, 1, cumsum))
  diagnostics <- vector("list", length(n_values))
  samples <- if (keep_samples) vector("list", length(n_values)) else list()

  for (i in seq_along(n_values)) {
    n <- n_values[i]
    sample_means <- cumulative[, n] / n
    if (keep_samples) samples[[i]] <- sample_means
    diagnostics[[i]] <- diagnose_sample_means(sample_means, n, spec)
  }

  diagnostics <- do.call(rbind, diagnostics)
  diagnostics$stable_pass <- vapply(seq_len(nrow(diagnostics)), function(i) {
    j <- i:min(i + NORMAL_CRITERIA$consecutive_passes - 1L,
               nrow(diagnostics))
    length(j) == NORMAL_CRITERIA$consecutive_passes &&
      all(diagnostics$normal_enough[j])
  }, logical(1))

  selected <- which(diagnostics$stable_pass)[1]
  selected_n <- if (is.na(selected)) NA_integer_ else diagnostics$n[selected]
  if (keep_samples) names(samples) <- as.character(n_values)

  list(
    population = population,
    spec = spec,
    seed = seed,
    B = B,
    n_values = n_values,
    diagnostics = diagnostics,
    samples = samples,
    selected_n = selected_n,
    criteria = NORMAL_CRITERIA,
    design = "Reusable simulation path with cumulative means for every integer n."
  )
}

run_all_studies_full_grid <- function(seed = 6599L, B = B_DEFAULT,
                                      n_values = 2:500,
                                      keep_samples = FALSE) {
  populations <- names(population_specs())
  studies <- lapply(populations, function(population) {
    study_population_full_grid(
      population, seed = seed, B = B, n_values = n_values,
      keep_samples = keep_samples
    )
  })
  names(studies) <- populations
  studies
}

summary_table <- function(studies) {
  rows <- lapply(studies, function(study) {
    d <- study$diagnostics
    selected <- which(d$stable_pass)[1]
    if (is.na(selected)) {
      selected_row <- d[nrow(d), , drop = FALSE]
      selected_n <- NA_integer_
    } else {
      selected_row <- d[selected, , drop = FALSE]
      selected_n <- selected_row$n
    }
    data.frame(
      population = study$spec$label,
      smallest_n_judged_normal = selected_n,
      skewness_at_selected_n = selected_row$skewness,
      excess_kurtosis_at_selected_n = selected_row$excess_kurtosis,
      qq_correlation_at_selected_n = selected_row$qq_correlation,
      qq_rmse_at_selected_n = selected_row$qq_rmse,
      conclusion = if (is.na(selected_n)) "No stable n met all criteria in the investigated range." else paste("First stable pass at n =", selected_n),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

format_number <- function(x, digits = 3) {
  ifelse(is.na(x), "NA", formatC(x, digits = digits, format = "f"))
}
