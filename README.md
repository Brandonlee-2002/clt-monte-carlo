# How Fast Does Normal Happen?

This repository is a reproducible R/Quarto investigation of how quickly the
sampling distribution of a sample mean approaches normality under different
population shapes and assumptions.

## Project map

- `Inference/` contains the class handouts and rendered reference documents.
- `analyses/` contains one analysis for each population or process.
- `final-summary.qmd` compares the populations and answers the larger CLT questions.
- `R/helpers.R` contains the shared simulation, diagnostic, and summary functions.
- `results/` stores generated summary tables and figures when the project is run.
- `ai-log.md` records AI prompts, validation, revisions, and remaining limitations.

## Run the project

1. Install R and Quarto, then open this folder as a Quarto project.
2. In each `.qmd`, replace the placeholder `student_id <- 6599L` with the last
   four digits of your student ID.
3. Render the website with:

   ```bash
   quarto render --no-clean --cache-refresh
   ```

   The extra flags avoid a Quarto output-directory cleanup/move issue in this
   project and refresh stale rendering-session files.

To regenerate only the CSV result tables from the command line, run
`Rscript R/run_all.R` from the repository root.

The simulations use `B = 10000` repetitions and candidate sample sizes from 2
through 500. The code sets the student seed immediately before each sample-size
experiment so the results can be reproduced.

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
