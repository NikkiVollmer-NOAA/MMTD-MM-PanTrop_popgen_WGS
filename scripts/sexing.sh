###Ran this on the head node in /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned to determine sex of every individuals based on 
###the ratio between the X and Y chromosomes for each individual. 

echo -e "Sample\tX_Ratio\tY_Ratio\tPredicted_Sex" > final_sex_audit.txt

for bam in *.bam; do
    # Get mapped read counts and lengths
    # Col 2 is Length, Col 3 is Mapped Reads
    vals1=($(samtools idxstats $bam | grep -w "HiC_scaffold_1" | awk '{print $2, $3}'))
    valsX=($(samtools idxstats $bam | grep -w "HiC_scaffold_21" | awk '{print $2, $3}'))
    valsY=($(samtools idxstats $bam | grep -w "HiC_scaffold_22" | awk '{print $2, $3}'))
    
    # Calculate Normalized Depths (Reads/Length)
    # We use Scaffold 1 as the Autosomal baseline (2n)
    depth1=$(echo "scale=6; ${vals1[1]}/${vals1[0]}" | bc)
    depthX=$(echo "scale=6; ${valsX[1]}/${valsX[0]}" | bc)
    depthY=$(echo "scale=6; ${valsY[1]}/${valsY[0]}" | bc)
    
    # Calculate Ratios
    ratX=$(echo "scale=4; $depthX/$depth1" | bc)
    ratY=$(echo "scale=4; ($depthY/$depth1)*100" | bc) # Multiplied by 100 for visibility
    
    # Logic for Prediction
    # Males: X-ratio < 0.8 AND Y-ratio > 0.05
    if (( $(echo "$ratX < 0.8" | bc -l) )) && (( $(echo "$ratY > 0.05" | bc -l) )); then
        res="MALE"
    else
        res="FEMALE"
    fi
    
    echo -e "${bam}\t${ratX}\t${ratY}\t${res}" >> final_sex_audit.txt
done

column -t final_sex_audit.txt
