# Calculate bam stats with nexflow

Author Information
- Nikki Vollmer edited from original created by Reid Brennan 14Feb2025 (https://github.com/nmfs-ost/Genomics_Resources/blob/main/tutorials/QC/bam_stats_nextflow/README.md)
- Email: nicole.vollmer@noaa.gov
- Last updated: 07Mar2025

---

This pipeline processes BAM files, after marking duplicates, to generate alignement statistics including:
- Total reads
- Mapped reads and percentage
- Duplicate reads and percentage
- High-quality (Q20) mapped reads and percentage

## To Run

To run, put the bam_stats.nf and nextflow.config files in your working directory (e.g., scripts) and in that directory, assuming you're using SEDNA, start a new screen (very important). Then run the command below:

    mamba activate nextflow-24.04.4

    nextflow run bam_stats.nf \
        -profile bam_stats \
        --input_dir path/to/your/bam/files \
        --output_dir path/to/output \
        --output_file counts.csv \
	    -with-tower

where: 
- `bam_stats.nf` is the nextflow script that runs the alignment stats
- `--input_dir` is the path to your bam files
- `--output_dir` is the output location for the txt file
-  `output_file` is the name of the output file, which will be csv
-  `-with-tower` allows you to track the run with nextflow tower (in seqera). This line requires you to have a corresponding token in line 4 of the nextflow.contig.

The pipeline generates a CSV file with the following columns:
- sample: Sample name derived from BAM filename
- total_reads: Total number of reads
- total_mapped: Number of mapped reads
- map_percent: Percentage of mapped reads
- duplicates: Number of duplicate reads
- dup_percent: Percentage of duplicate reads
- mapped_q20: Number of mapped reads with mapping quality ≥20
- map_percent_q20: Percentage of Q20 mapped reads

You can monitor the run at https://tower.nf/ under `runs`
  
