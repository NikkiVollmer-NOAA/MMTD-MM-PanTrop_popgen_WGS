###Ran this on the head node in /scratch2/nvollmer/analysis/Clipped/Clipped_Realigned to determine what HiC_scaffold_21 really is since it seems to be very long. Picked one male and one female sample to test the 
###ratio between an autosome (scaffold 1 presumably chrom 1) and scaffold 21 which might be the X chrom

SCAF_1="HiC_scaffold_1" 
SCAF_21="HiC_scaffold_21"

get_ratio() {
    samtools idxstats $1 | awk -v s1="$SCAF_1" -v s2="$SCAF_21" '
    $1==s1 {len1=$2; count1=$3} 
    $1==s2 {len2=$2; count2=$3} 
    END {
        if (len1 > 0 && len2 > 0) {
            depth1 = count1/len1
            depth2 = count2/len2
            if (depth1 > 0) {
                printf "Ratio (%s/%s): %.4f\n", s2, s1, depth2/depth1
            } else {
                print "Error: No reads found on " s1
            }
        } else {
            print "Error: Scaffold names not found or length is zero. Check your SCAF variables."
        }
    }'
}

# Run it again
echo "Male Results:"
get_ratio 8Satt143_clipped_realigned.bam
echo "Female Results:"
get_ratio 8Satt144_clipped_realigned.bam

###If Male Ratio approx 0.5$ and Female Ratio approx 1.0 then Scaffold 21 is the X Chromosome.If both are approx 1.0 Scaffold 21 is just a large Autosome that got sorted weirdly.

#Results:
echo 
"Male Results:"
Male Results:
(base) [nvollmer@sedna Clipped_Realigned]$ get_ratio $MALE_BAM
get_ratio $FEMALE_BAMRatio (Scaf21/Scaf1): 0.5982
(base) [nvollmer@sedna Clipped_Realigned]$ echo "Female Results:"
Female Results:
(base) [nvollmer@sedna Clipped_Realigned]$ get_ratio $FEMALE_BAM
Ratio (Scaf21/Scaf1): 1.0382

#The ratio for your Female (1.0382) is nearly a perfect 1:1, meaning she has the same "dosage" of Scaffold 21 as she does for the autosomes. 
#Your Male (0.5982) is very close to the expected 0.50, indicating he only has one copy of that scaffold.

###Ran the following to look at sizes of my next scaffolds (after 21) to try and find the missing autosome and/or the Y chrom

# Define the reference autosome and the range to test
REF="HiC_scaffold_1"
TEST_SCAFS=("HiC_scaffold_21" "HiC_scaffold_22" "HiC_scaffold_23" "HiC_scaffold_24" "HiC_scaffold_25")

# Define your test BAMs
M_BAM="8Satt143_clipped_realigned.bam"
F_BAM="8Satt144_clipped_realigned.bam"

echo -e "Scaffold\tMale_Ratio\tFemale_Ratio\tLikely_Identity"
echo "-------------------------------------------------------------------"

for SCAF in "${TEST_SCAFS[@]}"; do
    # Calculate Male Ratio
    m_vals=($(samtools idxstats $M_BAM | awk -v s1="$REF" -v s2="$SCAF" '$1==s1{l1=$2;c1=$3} $1==s2{l2=$2;c2=$3} END{if(l1>0 && l2>0 && c1>0) print (c2/l2)/(c1/l1); else print 0}'))
    
    # Calculate Female Ratio
    f_vals=($(samtools idxstats $F_BAM | awk -v s1="$REF" -v s2="$SCAF" '$1==s1{l1=$2;c1=$3} $1==s2{l2=$2;c2=$3} END{if(l1>0 && l2>0 && c1>0) print (c2/l2)/(c1/l1); else print 0}'))

    # Determine Identity Label
    if (( $(echo "$f_vals < 0.1" | bc -l) )); then
        ID="Y Chromosome"
    elif (( $(echo "$m_vals < 0.7" | bc -l) )) && (( $(echo "$f_vals > 0.8" | bc -l) )); then
        ID="X Chromosome"
    else
        ID="Autosome"
    fi

    echo -e "$SCAF\t$m_vals\t$f_vals\t$ID"
done

### results
HiC_scaffold_21 0.598202        1.03818 X Chromosome
HiC_scaffold_22 0.61313 0.0676672       Y Chromosome
HiC_scaffold_23 0.00026968      0.000254187     Y Chromosome
(standard_in) 1: syntax error
(standard_in) 1: syntax error
HiC_scaffold_24 0.000543138     9.43037e-05     Autosome
HiC_scaffold_25 0.000406009     0.000129239     Y Chromosome

###based on this scaffold 22 is prob the Y and all the others >=23 are too short to worry about

#next ran this to look for the next scaffold that has a length between 10 Mb and 50 Mb and a high read count (column 3).

# This will show you scaffolds ranked by length that aren't the ones we already found
samtools idxstats 8Satt144_clipped_realigned.bam | sort -k2,2nr | head -n 30

##and got this:
HiC_scaffold_1  162688928       23309410        19098
HiC_scaffold_2  155670876       22165048        12897
HiC_scaffold_3  149093641       21174249        12013
HiC_scaffold_4  127004759       18329401        11226
HiC_scaffold_5  121396970       17185993        10417
HiC_scaffold_21 108856197       16191891        10222
HiC_scaffold_6  104581870       15002638        10352
HiC_scaffold_7  101463711       14647875        9407
HiC_scaffold_8  101168457       14442083        11069
HiC_scaffold_9  95994220        13729678        7542
HiC_scaffold_10 93377156        13525805        7224
HiC_scaffold_11 91806927        13072595        13281
HiC_scaffold_12 90962718        12985668        10872
HiC_scaffold_13 79759866        11304923        5834
HiC_scaffold_14 79479372        11225413        7021
HiC_scaffold_15 79248479        13384893        9663
HiC_scaffold_16 78823031        11215096        8966
HiC_scaffold_17 70848036        11457604        5363
HiC_scaffold_18 70347050        9975352 5068
HiC_scaffold_19 53025636        7667996 5943
HiC_scaffold_20 52895807        7642377 5536
HiC_scaffold_22 2244437 21760   52
HiC_scaffold_23 521708  19      1
HiC_scaffold_24 518079  7       0
HiC_scaffold_25 378033  7       0
HiC_scaffold_26 346265  11      3
HiC_scaffold_27 338627  15      0
HiC_scaffold_28 311467  14      1
HiC_scaffold_29 296137  17      1
HiC_scaffold_30 250413  12      1

Scaffold Name	SizeRank	Type	Notes
HiC_scaffold_1–5	1–5	Autosomes	
HiC_scaffold_21	6	X Chromosome	Found by coverage ratio (Male 0.6 / Female 1.0)
HiC_scaffold_6–20	7–21	Autosomes	
HiC_scaffold_22	22	Y Chromosome	Found by coverage ratio (Male 0.6 / Female 0.0)
HiC_scaffold_23–30	23+	Debris	Tiny fragments (<1 Mb) with almost no mapping.
