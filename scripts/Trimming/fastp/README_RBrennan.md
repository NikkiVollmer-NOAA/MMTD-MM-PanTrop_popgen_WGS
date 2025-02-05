# fastp and nextflow created by Reid Brennan Jan2025

This script will run in parallel, submitting 25 jobs at a time.

You should put the `fastp.nf` and the `nextflow.config` in your working directory. the nf file can be in scripts and you can point to it from there. It is best to have the config file where you will run things from.

The fastp command in the script is:

```bash

    module load bio/fastp/0.23.2

    fastp -i ${read1} \
          -I ${read2} \
          -o ${sample_id}.R1.clip.fastq.gz \
          -O ${sample_id}.R2.clip.fastq.gz \
          -w ${task.cpus} \
          --cut_right \
          -l 35 \
          -h /dev/null \
          -j /dev/null \
          --dont_eval_duplication
```


to run, start a new screen (very important). Then run the command below:

```bash
mamba activate nextflow-24.04.4

nextflow run fastp.nf --input_dir '241129_NOA015_PanTrop_WGS,241129_NOA016_PanTrop_WGS' --outdir trimmed -profile fastp

```

Then disconnect from your screen. 

where:
- `fastp.nf` is the nextflow script that runs fastp. If it in in `scripts`, use `scripts/fastp.nf`. 
- ` --input_dir '241129_NOA015_PanTrop_WGS,241129_NOA016_PanTrop_WGS'` are your input directories, comma separated.
- `--outdir trimmed` is the output location. You need to make this initial directory, but then it will automatically make subdirectories with the same name as your input directories.
- `-profile fastp` is what is feeding the slurm option and things specific to this job. 

I'd highly recommend running fastqc or at least counting reads after to make sure things ran correctly. You can track the overall progress from the screen. 
