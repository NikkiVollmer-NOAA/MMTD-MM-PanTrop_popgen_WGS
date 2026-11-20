# =============================================================================
# 01_install_mitopilot.R
# Install MitoPilot into the MitoPilot_deps conda environment.
# Run from a compute node with the env active:
#   mamba activate MitoPilot_deps
#   Rscript scripts/01_install_mitopilot.R 2>&1 | tee ~/mitopilot_install.log
# Compiling everything from source takes ~30-60+ min the first time.
# =============================================================================

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

# Dependencies that failed on the first attempt (all downstream of xml2/XML,
# which needed libxml2-devel). Installing them explicitly first makes any
# remaining compile errors easier to spot.
deps <- c("XML", "xml2", "rentrez", "read.gb", "Rsamtools", "shiny", "rmarkdown",
          "htmlwidgets", "reactable", "shinyjs", "shinyWidgets", "waiter",
          "golem", "gargoyle", "listviewer", "msaR", "rclipboard")
missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]
print(missing)
if (length(missing)) BiocManager::install(missing, update = FALSE, ask = FALSE)

BiocManager::install("Smithsonian/MitoPilot", update = FALSE, ask = FALSE)

# Check: should print "Using Nextflow 25.10.x [supported]" and the version
library(MitoPilot)
packageVersion("MitoPilot")
R.version.string

# Find any compile failures afterwards with:
#   grep -n -A5 "ERROR\|not available\|cannot find" ~/mitopilot_install.log
