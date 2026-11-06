# Stress-Testing the Central Limit Theorem

[![Quality checks](https://github.com/Brandonlee-2002/clt-monte-carlo/actions/workflows/quality.yml/badge.svg)](https://github.com/Brandonlee-2002/clt-monte-carlo/actions/workflows/quality.yml)

[View the completed project](https://brandonlee-2002.github.io/clt-monte-carlo/) ·
[View source code](https://github.com/Brandonlee-2002/clt-monte-carlo)

This repository is a reproducible R/Quarto investigation of how quickly the
sampling distribution of a sample mean approaches normality.

## Interview summary

I built a reproducible R/Quarto Monte Carlo study testing when sample means
become approximately normal across 11 populations and dependence structures.
Instead of assuming that `n = 30` always works, the project applies four
pre-specified diagnostics and requires three consecutive passing sample sizes.
The resulting thresholds range from `n = 2` to `n = 100` for the finite-variance
independent populations; the Cauchy and dependent cases do not pass through
`n = 500`. The central engineering challenge was keeping the simulation,
diagnostics, tables, interactive explorer, and published report driven by the
same shared functions.

## Technical architecture

```text
Population generators in R/helpers.R
        ↓
Repeated sample-mean simulation
        ↓
Four numerical normality diagnostics
        ↓
Three-consecutive-pass decision rule
        ↓
CSV tables, plots, interactive explorer, and Quarto report
```

The project separates reusable statistical logic from presentation code. The
individual `.qmd` files describe each population, while `R/helpers.R` owns the
generators, simulation design, diagnostics, theoretical standard deviations,
and threshold selection.

## Project map

- `Inference/` contains the class handouts and rendered reference documents.
- `analyses/` contains one analysis for each population or process.
- `final-summary.qmd` compares the populations and answers the larger CLT questions.
- `full-grid.qmd` provides an interactive slider from `n = 2` through `n = 500`
  with selectable sampling-distribution, Q-Q, diagnostic, and comparison graphs.
- `R/helpers.R` contains the shared simulation, diagnostic, and summary functions.
- `R/run_full_grid.R` generates the exhaustive integer-grid diagnostic tables.
- `R/run_interactive_data.R` generates the compact JSON used by the explorer.
- `R/homepage_visuals.R` regenerates the three evidence visuals shown on the home page.
- `R/run_validation.R` checks simulated standard deviations against analytic expectations.
- `R/run_sensitivity.R` compares seeds, Monte Carlo sizes, and alternative decision criteria.
- `tests/test_helpers.R` runs lightweight automated tests for reproducibility and decision logic.
- `results/` stores generated summary tables and figures when the project is run.
- `ai-log.md` records AI prompts, validation, revisions, and remaining limitations.

## Run the project

1. Install R 4.4.1 and Quarto, then open this folder as a Quarto project.
2. Restore the locked R environment:

   ```r
   renv::restore()
   ```

3. In each `.qmd`, replace the placeholder `student_id <- 6599L` with the last
   four digits of your student ID.
4. Render the website with:

   ```bash
   quarto render --no-clean --cache-refresh
   ```

   The extra flags avoid a Quarto output-directory cleanup/move issue in this
   project and refresh stale rendering-session files.

To regenerate only the CSV result tables from the command line, run
`Rscript R/run_all.R` from the repository root.

To regenerate the exhaustive every-integer sensitivity analysis, run
`Rscript R/run_full_grid.R`. This writes
`results/tables/full_grid_diagnostics.csv` and
`results/tables/full_grid_summary.csv`.

To run the automated checks and analytic validation:

```bash
Rscript tests/test_helpers.R
Rscript R/run_validation.R
```

To explore sensitivity to seed, Monte Carlo size, and the normality criteria:

```bash
Rscript R/run_sensitivity.R
```

The sensitivity results are written to
`results/tables/sensitivity_summary.csv`. The default website uses `B = 10000`;
the sensitivity script uses smaller exploratory values so it can be rerun
quickly during development.

To regenerate the interactive graph data, run
`Rscript R/run_interactive_data.R` after the full-grid diagnostics have been
updated. This step uses the `jsonlite` package; install it once with
`install.packages("jsonlite")` if needed.

To regenerate the homepage SVG visuals after refreshing the result tables, run
`Rscript R/homepage_visuals.R` from the repository root.

The simulations use `B = 10000` repetitions and candidate sample sizes from 2
through 500. The code sets the student seed immediately before each sample-size
experiment so the results can be reproduced.

## Publish the completed project

The generated site is published from `docs/` by the workflow in
`.github/workflows/deploy-pages.yml`. To enable it on GitHub:

1. Open **Settings → Pages** for the repository.
2. Set **Source** to **GitHub Actions**.
3. Commit and push the workflow and generated `docs/` folder to `main`.
4. Check the workflow under the repository’s **Actions** tab.

The live project link is:

[View the completed project](https://brandonlee-2002.github.io/clt-monte-carlo/)

## Decision rule

The same pre-specified screen is used for all populations:

- absolute skewness no greater than `0.20`;
- absolute excess kurtosis no greater than `0.30`;
- normal Q-Q correlation at least `0.995`;
- standardized Q-Q RMSE no greater than `0.08`.

The selected value is the first candidate `n` that passes all four criteria for
three consecutive investigated sample sizes. Histograms and theoretical
standard-deviation comparisons are still reviewed before writing the conclusion.

This is a defensible operational definition of “approximately normal,” not a
claim that any simulated distribution is perfectly normal.

## Validation and limitations

The analytic validation compares the simulated standard deviation of the sample
mean with the theoretical value for nine finite-variance populations. Each
check must have an absolute ratio error of at most `0.08`. The automated tests
also verify fixed-seed reproducibility, population-generator coverage, and the
consecutive-pass rule.

Important limitations remain. The reported threshold is the first passing value
on the investigated grid, not necessarily the exact boundary between passing
and failing values. Monte Carlo estimates vary with the seed and number of
repetitions. The Cauchy population has no finite mean or variance, and the
dependent process has less independent information than its nominal sample size
suggests. The age-at-death mixture is synthetic and should not be interpreted
as historical mortality data.

## Interview talking points

- **Statistical judgment:** I defined “approximately normal” explicitly instead
  of hiding the decision behind the `n = 30` rule of thumb.
- **Reproducibility:** Seeds, a locked R environment, generated tables, and
  automated checks make the results rerunnable.
- **Software design:** Shared helpers prevent the 11 analyses from drifting
  apart, while each population still has its own documented expectations.
- **Validation:** Simulated standard deviations are checked against analytic
  formulas, and the conclusions are tested across seeds and criteria.
- **Tradeoff:** The project favors an interpretable, auditable screen over a
  single black-box normality test; the limitations are documented explicitly.
