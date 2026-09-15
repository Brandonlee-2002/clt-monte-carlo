# AI interaction log

This file documents how AI assisted the project. It is not a list of answers
copied from AI. Each entry should show the question, what was checked, and how
the analysis or prompt changed afterward.

## What to record for every important interaction

Use one entry per meaningful prompt or prompt revision. Include:

| Field | What to write |
|---|---|
| Date | When the interaction happened. |
| Goal | What you were trying to understand or improve. |
| Prompt | The exact prompt you gave AI. |
| AI response summary | The useful suggestion, code, or explanation. Do not paste an entire response. |
| Your validation | How you tested it in R, against the handout, or against a known result. |
| Problem found | Any error, unsupported assumption, misleading plot, or unanswered question. |
| Revision | What you changed in the prompt, code, design, or interpretation. |
| Result | What changed after the revision; include a file/range/figure name when useful. |
| Your decision | What you ultimately accepted and why. |

The strongest entries show iteration:

1. Ask a focused question.
2. Inspect the response rather than accepting it automatically.
3. Test the code and identify a weakness or uncertainty.
4. Ask a better follow-up question or revise the code.
5. Explain why the final method is appropriate for this project.

## Starter record — project setup

- Date: 2026-09-15
- Goal: Turn the class handout in `Inference/` into a reproducible project repository.
- Prompt: “Can you fill out all the files then? Please use these guidelines: [the five final-repository requirements]. Also, help me design the ai-log.md (what information i should use).”
- AI response summary: Created a Quarto website, 11 population analyses, a final comparison, shared base-R simulation helpers, generated diagnostic CSV files, and this interaction-log structure.
- Your validation: Inspected the handout’s required populations and deliverables; ran `Rscript R/run_all.R` with the current placeholder seed `6599`; checked the cross-distribution results; parsed every R code block in all `.qmd` files.
- Problem found: The handout marks the dependent machine-failure and life/death specifications as “coming soon,” so their exact generators were not available.
- Revision: Used an explicit AR(1)-style dependent exponential process and a documented two-component mixture as provisional models. The individual files state that these generators must be replaced if official specifications are supplied.
- Result: The simulations produced reproducible diagnostics and the repository now has a consistent normality rule across populations.
- Your decision: Treat this as the working project framework. Replace `6599L` with the last four digits of my student ID if needed, replace provisional generators when instructed, and inspect the plots before submitting conclusions.

This starter record documents the setup interaction only. Add additional entries
for the decisions you make while inspecting plots, revising thresholds, debugging
code, and interpreting surprising results.

## Suggested entries

### Entry 1 — Designing the normality criterion

- Date:
- Goal: Define “approximately normal” using more than one diagnostic.
- Prompt:
- AI response summary:
- Your validation: Check the proposed metrics on a known normal sample and on a clearly skewed sample.
- Problem found:
- Revision:
- Result:
- Your decision:

### Entry 2 — Checking Q-Q plot differences

- Date:
- Goal: Turn the visual Q-Q comparison into a reproducible numerical diagnostic.
- Prompt:
- AI response summary:
- Your validation: Verify how the correlation and standardized RMSE behave when the sample is normal, skewed, or heavy-tailed.
- Problem found:
- Revision:
- Result:
- Your decision:

### Entry 3 — Debugging one population generator

- Date:
- Goal: Implement or debug the generator for one assigned population.
- Prompt:
- AI response summary:
- Your validation: Confirm the population mean, spread, support, and dependence structure with a large simulated population.
- Problem found:
- Revision:
- Result:
- Your decision:

### Entry 4 — Interpreting a surprising result

- Date:
- Goal: Explain a result that differed from the initial prediction.
- Prompt:
- AI response summary:
- Your validation: Re-run with the assigned seed and one alternative seed; compare the scientific conclusion, not just exact numbers.
- Problem found:
- Revision:
- Result:
- Your decision:

## Important integrity notes

- I wrote the research questions and selected the populations/sample sizes.
- I ran and inspected the simulations myself.
- I treated AI suggestions as hypotheses to test, not as evidence.
- I can explain every submitted line of code and every reported conclusion.
- Any AI-generated code that was not used should not be presented as project evidence.
