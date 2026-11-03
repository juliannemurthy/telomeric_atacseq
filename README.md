# Telomeric ATAC-seq Analysis
Replicated pipeline from Lynskey ML et al. Cell Reports (2024) STAR methods descriptions. Written in collaboration with the NIH and Day Lab. Performs standard ATAC-seq analysis and telomeric specific analysis starting from raw fastq read files.

## Requirements
  - python=3.10
  - fastqc v0.11.7
  - fastp
  - bowtie2 v2.4.5
  - samtools v1.10
  - bedtools v2.29.0
  - deeptools v3.3.0
  - picard=3.2.*     
  - openjdk=17       
  - telseq v0.0.2
  - qmotif v1.2

## Steps
1. References prep → bowtie2 index of chm13v2.0 fasta, RefSeq hs1 annotation download, ensure chrom name compatibility with those
2. Trim adapters → confirmed presence with lab-run DRAGEN QC 
3. Run fastqc to ensure adapters successfully trimmed
4. Align samples to bowtie2 index with key ATAC-seq params from Lynskey et al paper
5. Coordinate sort aligned reads & remove PCR duplicates with Picard
6. Remove mitochondrial reads with grep -vwE command and create bam files
7. Sort BAM files into 1-100 bp fragment size class with SAMtools
    1. <100 bp fragments are nucleosome free (open) chromatin, whereas higher bp fragments represent different levels of nucleosome occupancy → want to enrich for most accessible signals
8. Merge command from samtools to create single merged bam file from 1-100 bp size class sorted bam replicates for each experimental condition.
9. RPGC-normalized signal tracks → RPGC normalized bigWig files generated from the merged bam files using deeptools bamcoverage command with specified params Lynskey et al
    1. RPGC → reads per genomic content, normalize coverage to 1x genome depth using the effective genome size param, ensure comparability across samples regardless of sequencing depth
    2. sequencing depth = (total mapped reads × average fragment length) / effective genome size. scaling factor = inverse of sequencing depth
    3. bigwig → compressed indexed format ideal for visualization and heatmap generation
10. Heatmaps are generated from RPGC normalized bigWig files over RefSeq annotated chm13v2.0 genome assembly transcription start sites (TSSs) genome wide using the computeMatrix (--missingDataAsZero -b 2000 -a 2000 -bs 20) and plotHeatmap commands from deepTools → matrix and heatmap generated
    1. heatmaps visualize chromatin accessibility signal from bigwigs over genomic regions of interest like the TSSs, arranged by a matrix
    2. rows are genes, columns are positions relative to TSS, color shows normalized accessibility. 
11. Lock a row (gene) order for compatibility across experimental conds and reps → using control sample matrix from step before, generate a sorted matrix bed file using the plotHeatmap -m command over TSSs with option -descend --outFileSortedRegions bed. This is used as the reference file -R for sorting all other experimental samples using computeMatrixOperations sort -keep. All matrices are then visualized over T2T annotated RefSeq TSSs using plotHeatmap.
    1. ensures consistent gene ordering across multiple heatmaps comparison side by side

### Telomere specific analysis using picard-filtered mito-removed bam files 

1. Build BAM index of these files using Picard BuildBamIndex command for qMotif
2. qMotif telomeric motif counts → using Lynskey et al params, run qMotif so it reads only known telomeric regions. Output is raw telomere motif counts per sample
3. Use the BAMs to do coverage-based normalization → 
    1. do BEDtools bam to bed conversion
    2. BEDTools coveragebed to average genome coverage per sample excluding chrM and sex chr
    3. compute scaling factor → set sample with lowest fraction genome coverage to 1.0 and scale other samples relative to that 
    4. multiply raw qMotif telomere counts by each sample’s scaling factor to get normalized telomere motif counts table 
    5. raw counts vary with sequencing depth so coverage based normalization is done for fair comparison across samples
4. TelSeq → calculate telomere length and cumulative telomeric reads using BAM files with key params, obtain stats
    1. offers genome wide telomere length measurement from sequencing data 
