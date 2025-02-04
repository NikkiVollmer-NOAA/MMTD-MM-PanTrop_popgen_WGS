Jan 2025

Originally tried to use fastp to trim WGS but found that it was not adequately trimming out adapter sequences after inspection with fast/multiqc. 
Found online that this can be a problem for fastp when using Nextera adapters (https://github.com/OpenGene/fastp/issues/558).

After discovering this switched to trimmomatic for trimming sequences.
