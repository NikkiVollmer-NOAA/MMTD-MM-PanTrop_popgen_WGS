# =============================================================================
# 04_test_project.R
# Create MitoPilot's built-in test project (13 fish SRA samples + 2 scaffold
# test cases) and open the GUI. Run in RStudio Server on SEDNA.
# =============================================================================
library(MitoPilot)

# RStudio must be able to see /scratch2 (APPTAINER_BIND in the launcher)
stopifnot(dir.exists("/scratch2/nvollmer"))
# Should list paths in ~/.conda/envs/MitoPilot_deps/bin (via ~/.Renviron)
print(Sys.which(c("nextflow", "java", "singularity")))

wd <- "/scratch2/nvollmer/MitoPilot/test_project"

MitoPilot::new_test_project(
  path      = wd,
  executor  = "NOAA_SEDNA",
  full_size = FALSE,
  Rproj     = FALSE
)

list.files(wd, all.files = TRUE)

# IMPORTANT: apply the config fix before running (scripts/05_fix_config.sh)

# Open the GUI (must be called from inside the project directory)
setwd(wd)
MitoPilot::MitoPilot()

# In the GUI: select module -> click Update -> COPY the Nextflow command.
# Do NOT click "Run from App" (SEDNA cannot run Nextflow from the Shiny app).
# Paste the command into scripts/run_nextflow.sh and sbatch it.
