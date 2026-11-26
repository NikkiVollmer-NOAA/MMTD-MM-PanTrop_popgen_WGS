# MitoPilot on NOAA SEDNA: *Stenella* mitogenomes

Scripts and notes for assembling and annotating mitogenomes from whole-genome
sequencing data with [MitoPilot](https://smithsonian.github.io/MitoPilot/) 1.6.0
on the NOAA NMFS SEDNA cluster.

Setup walkthrough (with all problems hit and fixes):
**`01_mitopilot_sedna_setup.qmd`**. Render it with `quarto render 01_mitopilot_sedna_setup.qmd`.

## Layout

```
envs/
  MitoPilot_deps.yml           conda env: R 4.6.2, Nextflow 25.10, Apptainer, libxml2-devel
  gbdb.yml                     conda env for building reference databases (Entrez Direct, Biopython)
scripts/
  00_create_env.sh             create MitoPilot_deps (mamba 2.x notes)
  01_install_mitopilot.R       install MitoPilot and its dependencies
  02_setup_rstudio.sh          one-time RStudio Server setup (Apptainer)
  start-rstudio-server-MitoPilot   launcher, copied to ~/bin
  03_pull_container.sh         pre-pull the MitoPilot container (avoids the 20-min pull timeout)
  04_test_project.R            create and open the built-in test project
  05_fix_config.sh             workaround for the MitoPilot 1.6.0 `multiply` config bug
  run_nextflow.sh              SLURM wrapper for a GUI-generated Nextflow command
  06_make_mapping.sh           build mapping CSVs (one lane per individual)
  07_build_delphinidae_db.sh   download Delphinidae records from GenBank
  08_finalize_ref_dbs.sh       final seedDB (>=15 kb) and labelDB (no no_product)
  09_compare_mitogenomes.sh    base-by-base comparison (mother/fetus check)
  10_make_seed_file.sh         same-species seed file from pilot assemblies
  11_getorg_summary.sh         per-sample GetOrganelle status and coverage, newest log per sample (run before deleting work/)
  12_pairwise_differences.sh   differences between one sample and all others (rotated sequences)
  13_species_call_blast.sh     species call per sample by local whole-genome BLAST (use instead of MitoPilot Top BLAST Hit)
  14_analyze_mitogenomes.py    align all exported mitogenomes, distances, nearest relatives, NJ tree
  15_getorg_rescue_test.sh     test GetOrganelle settings on one failed sample (200x read-cap fix)
01_mitopilot_sedna_setup.qmd   setup + test-run documentation
02_stenella_mitogenomes.qmd    Stenella data, databases, pilot run, batches
```

## Quick start (new SEDNA account)

```bash
srun -c 2 --mem=16GB -p standard -t 8:00:00 --pty /bin/bash
/opt/bioinformatics/mambaforge/bin/mamba shell init --shell bash && source ~/.bashrc
bash scripts/00_create_env.sh
mamba activate MitoPilot_deps
Rscript scripts/01_install_mitopilot.R
bash scripts/02_setup_rstudio.sh
sbatch scripts/03_pull_container.sh
echo 'export NXF_SINGULARITY_CACHEDIR=/scratch2/nvollmer/singularity_cache' >> ~/.bashrc
```

For every new MitoPilot project, run `bash scripts/05_fix_config.sh <project_dir>`
before the first run.

Paths are specific to user `nvollmer` on SEDNA; edit them for other users.
No sequence data, containers or databases are tracked (see `.gitignore`).
