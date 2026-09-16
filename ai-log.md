# AI Interaction Log

This file records how AI was used to develop, debug, interpret, and present the
CLT Monte Carlo project. It is a decision record, not a transcript. Each entry
captures the user request, the proposed change, the validation performed, and
the decision made afterward.

## Logging standard

For every meaningful interaction, record:

| Field | What to include |
|---|---|
| Date | The date the interaction occurred. |
| User prompt | The request or question that initiated the change. |
| Goal | The problem the change was intended to solve. |
| AI response summary | The useful recommendation, code, or explanation. |
| Validation | Commands, tests, handout checks, or visual review performed. |
| Problem found | Any error, limitation, unsupported assumption, or ambiguity. |
| Revision | What changed in the code, documentation, design, or interpretation. |
| Result | The observable outcome, including files or generated outputs. |
| Decision | What was accepted, rejected, or left provisional, and why. |

The validation field should describe work that was actually checked. AI output
is a suggestion; the simulation results, rendered pages, and final decisions
must be independently inspectable in the repository.

## Historical record

### 2026-09-15 — Planning the project structure

- User prompt: “Using the inference folder, how should I create my project?”
- Goal: Convert the class handouts in 'Inference/' into a coherent,
  reproducible statistics project.
- AI response summary: Recommended a Quarto website with source files separated
  from generated HTML, shared R functions, individual population analyses, a
  cross-distribution summary, results tables, and an AI interaction log.
- Validation: Inspected the three handout files and mapped their required
  populations, research question, and deliverables to a repository structure.
- Problem found: The handouts were reference HTML files rather than an existing
  executable project.
- Revision: Established 'index.qmd', 'final-summary.qmd', 'analyses/',
  'R/', 'results/', 'docs/', and supporting documentation.
- Result: The repository has a recognizable source-to-output workflow.
- Decision: Keep editable '.qmd' and '.R' files in the source tree and publish
  generated website files in 'docs/'.

### 2026-09-15 — Filling the project files

- User prompt: “Can you fill out all the files then? Please use these
  guidelines: [clear design, consistent criteria, evidence-based conclusions,
  cross-distribution comparison, and professional documentation]. Also, help me
  design the ai-log.md.”
- Goal: Implement the complete CLT Monte Carlo study and document the reasoning.
- AI response summary: Created 11 population analyses, shared base-R helpers,
  a final summary, generated CSV tables, README instructions, and this log
  structure.
- Validation: Ran 'Rscript R/run_all.R' with seed 6599 and 'B = 10000';
  checked the generated summary tables; parsed the R code blocks in the
  '.qmd' files; and rendered the site.
- Problem found: The dependent machine-failure and mixture specifications were
  marked “coming soon” in the handout.
- Revision: Used explicit provisional models: an AR(1)-style dependent process
  with exponential marginals and a 90/10 two-component normal mixture. Both
  assumptions are documented in the affected analyses and final summary.
- Result: Every population uses the same diagnostic framework and produces
  reproducible evidence.
- Decision: Keep the provisional models until official instructor generators
  are supplied; replace only the generators while preserving the analysis
  framework.

### 2026-09-15 — Defining “approximately normal”

- User prompt: “What is the smallest sample size at which the sampling
  distribution of the sample mean is reasonably defensible as approximately
  normal?”
- Goal: Make the research question operational rather than relying on a
  subjective visual impression or the rule of thumb 'n = 30'.
- AI response summary: Proposed one shared decision rule: absolute skewness at
  most 0.20, absolute excess kurtosis at most 0.30, normal Q-Q correlation at
  least 0.995, and standardized Q-Q RMSE at most 0.08.
- Validation: Applied the rule to all candidate sample sizes
  '2, 5, 10, 15, 20, 30, 40, 50, 75, 100, 150, 200, 300, 500' using
  10,000 simulated sample means per population.
- Problem found: A single passing grid point could be caused by Monte Carlo
  variation.
- Revision: Required all four diagnostics to pass at three consecutive
  candidate sizes before selecting a threshold.
- Result: The decision rule is consistent across populations and its
  assumptions are visible in 'R/helpers.R'.
- Decision: Use the rule as a transparent operational definition, not as a
  claim that simulated distributions are perfectly normal.

### 2026-09-15 — Explaining why the answer is ambiguous

- User prompt: “Why is the answer very ambiguous?”
- Goal: Explain why the research question cannot have one universal numerical
  answer.
- AI response summary: Identified five sources of ambiguity: population shape,
  the definition of “approximately normal,” the candidate-n grid, Monte Carlo
  variation, and CLT assumptions such as finite variance, independence, and
  identical distributions.
- Validation: Compared the actual project outputs across symmetric, skewed,
  discrete, heavy-tailed, dependent, non-identical, and mixture populations.
- Problem found: Saying only “it depends” would be scientifically correct but
  insufficiently evidence-based.
- Revision: Added specific results to the explanation, including Poisson
  passing at n = 30, Exponential requiring n = 100, and Cauchy failing through
  n = 500.
- Result: The ambiguity is now explained as a consequence of explicit
  modeling choices rather than uncertainty in the analysis.
- Decision: Report a population-specific threshold and always state the
  diagnostic rule and investigated grid.

### 2026-09-15 — Expanding the research answer with evidence

- User prompt: “Could we expand the answer then? I think the answer can be a
  lot more professional. Include evidence with the answers based on the
  results from the project and analyses.”
- Goal: Turn the conclusion into a professional, evidence-based report section.
- AI response summary: Expanded 'final-summary.qmd' with an executive
  conclusion, design description, cross-distribution comparison, numerical
  evidence, limitations, seed sensitivity, and a direct answer to the research
  question.
- Validation: Confirmed the reported thresholds and diagnostics against
  'results/tables/cross_distribution_summary.csv' and
  'results/tables/all_diagnostics.csv'; reran the summary code during Quarto
  rendering.
- Problem found: Exact thresholds depend on the student seed and the finite
  candidate grid.
- Revision: Documented seed 6599, B = 10000, the candidate grid, the
  three-consecutive-pass rule, and the distinction between an exact boundary
  and the first passing investigated value.
- Result: The final answer now states both the findings and the limits of what
  the simulation establishes.
- Decision: Emphasize the range and scientific pattern rather than presenting
  one value of n as a universal law.

### 2026-09-15 — Synchronizing the homepage with the final answer

- User prompt: “index.html still has the same answer. It’s supposed to be
  changed as well, right?”
- Goal: Ensure a recruiter or reviewer who opens the homepage sees the updated
  conclusion immediately.
- AI response summary: Added an “Answer in brief” section to 'index.qmd' and
  regenerated 'docs/index.html'.
- Validation: Searched the generated homepage for the updated answer, evidence
  values, and links to the final summary; verified that 'docs/index.html' was
  generated from 'index.qmd'.
- Problem found: The generated HTML is an output artifact and should not be
  edited as the primary source.
- Revision: Kept the substantive answer in 'index.qmd' and treated
  'docs/index.html' as generated output.
- Result: The homepage and final summary communicate the same conclusion.
- Decision: Edit '.qmd' sources first, then rerender the website.

### 2026-09-15 — Diagnosing Quarto output and command errors

- User prompt: “No such file or directory ... rename 'index.html' to
  'docs/index.html'” and later “command not found quarto.”
- Goal: Make the project render reliably on macOS and explain the missing
  root-level HTML file.
- AI response summary: Identified 'docs/' as the configured output directory,
  recommended the installed Quarto binary when PATH configuration was missing,
  and tested 'quarto render --no-clean --cache-refresh'.
- Validation: Confirmed Quarto 1.10.18 was installed at
  '/Applications/quarto/bin/quarto'; rendered the full 14-page site
  successfully with cache refresh; and confirmed the output at 'docs/'.
- Problem found: Quarto’s default cleanup/move path could fail with stale
  project/session state, and a root 'index.html' is not the authoritative
  homepage in this project.
- Revision: Documented 'quarto render --no-clean --cache-refresh' in
  'README.md' and clarified that 'index.qmd' is the source while
  'docs/index.html' is the generated homepage.
- Result: The generated site contains the homepage, final summary, AI log, and
  all 11 analyses.
- Decision: Keep 'output-dir: docs' and do not maintain duplicate root-level
  HTML files.

### 2026-09-15 — Improving the presentation for professional review

- User prompt: “Can we make the layout more professional? This will
  potentially be seen by recruiters, hiring managers, and senior engineers.”
- Goal: Present the work as a polished technical portfolio artifact while
  preserving the statistical reasoning and reproducibility.
- AI response summary: Added a restrained navy/teal visual system, hero panel,
  project metrics, executive result table, project-signal cards, stronger
  headings, styled tables and figures, responsive breakpoints, improved
  navigation, and a professional footer.
- Validation: Rendered the site; checked that all 14 HTML pages were present;
  verified navigation targets; confirmed custom CSS selectors were included;
  and ran 'git diff --check'.
- Problem found: Raw HTML divs around Markdown headings produced an implicit
  unclosed-block warning during one render.
- Revision: Replaced the affected raw containers with Quarto fenced divs and
  corrected the AI Log navigation target from 'ai-log.qmd' to 'ai-log.md'.
- Result: The homepage and final summary have an executive presentation layer,
  and all pages share the same visual system.
- Decision: Use restrained visual hierarchy and evidence-forward content
  instead of decorative graphics that would distract from the analysis.

### 2026-09-15 — Choosing a professional project title

- User prompt: “What project title would be the best?”
- Goal: Make the project title clear and credible to technical reviewers.
- AI response summary: Recommended “Stress-Testing the Central Limit Theorem”
  with the subtitle “A Reproducible Monte Carlo Study of When Sample Means
  Become Approximately Normal.”
- Validation: Confirmed the title was applied consistently to the website
  navbar and homepage metadata.
- Problem found: The original “How Fast Does Normal Happen?” title was
  memorable but less descriptive in a professional portfolio context.
- Revision: Updated the website title, homepage title, and navbar alternative
  text.
- Result: The title now states the technical subject and the subtitle states
  the method and research focus.
- Decision: Use the descriptive title for the final portfolio version.

### 2026-09-15 — Keeping the subtitle on one desktop line

- User prompt: “On the index page, can we somehow fit ‘normal’ so the subtitle
  is 1 line?”
- Goal: Prevent the final word of the subtitle from wrapping on desktop.
- AI response summary: Found that the custom stylesheet limited the subtitle to
  '760px'. Widened it to the available title-block width, added responsive
  font sizing, and applied 'white-space: nowrap' only on desktop screens.
- Validation: Checked the CSS rules, confirmed the generated homepage links to
  the active stylesheet, and verified that mobile media rules still allow
  wrapping.
- Problem found: Quarto’s local Sass cache returned “unable to open database
  file” during a later rerender.
- Revision: Converted the active stylesheet to browser-ready 'styles.css' so
  the layout does not depend on the project’s SCSS cache for the custom rules;
  updated 'docs/index.html' to link the stylesheet directly.
- Result: The subtitle is configured to remain on one line on desktop while
  remaining responsive on narrow screens.
- Decision: Keep 'styles.css' as the authoritative active stylesheet and retain
  the generated output in 'docs/'.

### 2026-09-15 — Backfilling the AI log and defining future logging

- User prompt: “Can you also fill in the AI-Log for each change that I have
  asked for already? And for future ones too?”
- Goal: Make AI assistance auditable across the full project lifecycle.
- AI response summary: Backfilled this log with the prior requests,
  implementation decisions, validation steps, errors, revisions, and final
  decisions. Added a reusable template and a future logging workflow.
- Validation: Cross-checked the entries against the repository files,
  generated results, render commands, and the recorded conversation requests.
- Problem found: A short prompt-only log would not show whether the proposed
  changes were tested or whether assumptions remained provisional.
- Revision: Added explicit fields for validation, problems, revisions, results,
  and decisions.
- Result: Future entries can be added consistently without copying entire AI
  responses.
- Decision: Append a new entry for every meaningful request that changes code,
  analysis, interpretation, layout, documentation, or reproducibility.

### 2026-09-16 — Making GitHub Pages deployment explicit

- User prompt: “It is still not working on Github Pages” and then “still not
  fixing the issue.”
- Goal: Determine why the live project link was not serving the generated
  website even though the local repository contained 'docs/index.html'.
- AI response summary: Inspected the repository state and found the generated
  'docs/' site and its assets tracked on 'origin/main', but no GitHub Pages
  deployment workflow. Added '.github/workflows/deploy-pages.yml' to publish
  the 'docs/' folder on pushes to 'main'.
- Validation: Confirmed that 'origin/main' contains 'docs/index.html', all
  Quarto asset files, and 35 tracked 'docs/' files. The live URL could not be
  reached from the current environment because external DNS/network access was
  unavailable, so GitHub’s Pages deployment status still requires checking in
  the repository interface.
- Problem found: Branch/folder publishing and GitHub Actions publishing are
  different GitHub Pages modes; the repository had no workflow to support the
  Actions mode.
- Revision: Added the Pages workflow and documented the required setting—Pages
  source must be **GitHub Actions**—in 'README.md'.
- Result: Every push to 'main' can now upload the committed 'docs/' folder as a
  Pages artifact and deploy it automatically.
- Decision: Commit and push the workflow, set Pages to GitHub Actions, then use
  the deployment URL reported by the successful Actions run. If the workflow
  fails, treat the Actions log as the next diagnostic source.

### 2026-09-16 — Updating GitHub Actions for Node 24

- User prompt: “There was an annotation when running the Github Action:
  Node.js 20 is deprecated.”
- Goal: Determine whether the annotation represented a failed deployment and
  remove avoidable runtime deprecation warnings.
- AI response summary: Verified the warning against the official action
  repositories. The workflow was using older action versions, while current
  releases support Node 24.
- Validation: Checked the action release and source documentation for
  'configure-pages', 'deploy-pages', and 'upload-pages-artifact'. The
  annotation identifies the action runtime versions, not the Quarto site.
- Problem found: 'configure-pages@v5', 'deploy-pages@v4', and
  'upload-pages-artifact@v4' can trigger Node 20 deprecation annotations even
  when the deployment succeeds.
- Revision: Updated '.github/workflows/deploy-pages.yml' to
  'configure-pages@v6', 'deploy-pages@v5', and 'upload-pages-artifact@v5'.
- Result: The next workflow run will use the current Node 24-compatible action
  releases and should eliminate this particular annotation.
- Decision: Treat the annotation as non-blocking if the run is green, but keep
  the workflow action versions current to avoid future runner incompatibility.

### 2026-09-16 — Removing redundant home navigation

- User prompt: “Can you combine the Home button and the Title button? It
  doesnt make sense for there to be 2 buttons that redirect to the same link.”
- Goal: Eliminate duplicate navigation while preserving an obvious route back
  to the homepage.
- AI response summary: Confirmed that the Quarto navbar title already links to
  'index.html', so the separate Home item was redundant.
- Validation: Inspected the navbar configuration and confirmed the title link
  and Home item both targeted the homepage.
- Problem found: The duplicate controls added visual clutter and made the
  navigation hierarchy less intentional.
- Revision: Removed the Home entry from the left navbar in '_quarto.yml' while
  retaining the clickable site title.
- Result: The navbar now presents one homepage affordance, followed by the
  summary and analysis navigation.
- Decision: Keep the title as the home link because it is a conventional,
  recognizable website pattern and leaves the navbar less crowded.

## Template for future interactions

Copy this template and append it below the historical record for each
meaningful future request.

### [YYYY-MM-DD] — [Short change title]

- User prompt: “[Exact request or a faithful short quotation.]”
- Goal: [What problem were we trying to solve?]
- AI response summary: [What was suggested or changed?]
- Validation: [What did I run, inspect, compare with the handout, or review
  visually?]
- Problem found: [What failed, remained uncertain, or needed clarification?]
- Revision: [What changed after validation?]
- Result: [What files, outputs, or conclusions changed?]
- Decision: [What did I accept, reject, or leave provisional, and why?]

## Future logging workflow

1. Before making a change, record the date, prompt, and goal.
2. After implementation, record the files changed and the AI response summary.
3. Run an appropriate validation check: simulation, render, link check,
   'git diff --check', or visual review.
4. Record any failure or limitation rather than silently removing it.
5. Finish with the decision and the reason for accepting the result.

## Integrity notes

- AI helped draft code, documentation, interpretations, and presentation
  structure; AI suggestions were treated as hypotheses to inspect.
- The simulation evidence is generated from the repository’s R code and
  recorded seed, not copied from an AI response.
- Provisional population models are explicitly labeled and should be replaced
  if the instructor supplies official specifications.
- Generated HTML belongs in 'docs/'; the '.qmd' and '.R' files are the
  authoritative sources.
- I should be able to explain the submitted code, diagnostics, limitations,
  and conclusions.
