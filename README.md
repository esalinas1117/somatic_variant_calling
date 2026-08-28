# Somatic Variant Calling Workflow
Documenting processing steps from FastQ QC to somatic variant calling using GATK4 on cell lines HCC1395 (ATCC, CRL-2324) and HCC1395BL (ATCC, CRL-2325).

## Data Download Strategy
- **Normal Sample (HCC1395BL):** SRR29788251
- **Tumor Sample (HCC1395):** SRR29788252
- **Subsampling:** Subsampled first 1,000,000 reads (-X 1000000) using fastq-dump to optimize EC2 disk usage during pipeline development.
- **Target Region:** Whole-genome reads; alignment will be performed on the whole genome.

## FastQC Processing of Raw Fastq Files
- **Per Base Sequence Quality:** Pass across all cycles.
- **Per Base Sequence Content:** Fail across all samples. However, this is due to fluctuations of >30% and <-20% in %T and %A content, respectively, were observed between base pairs 2 through 6. This is normal for Illumina Novaseq 6000. 
- **Adapter Content:** $<0.1\%$ contamination detected.
- **Trimming Decision:** High base quality ($Q > 30$); no preliminary trimming required prior to alignment.
- **Code:**
  ```bash
  #Bash
  #Run FastQC analysis
  bash fastqc_raw.sh
  ```

## Reference Genome Downloading and Indexing
- **Assembly:** GRCh38 Primary Assembly (GENCODE Release 44)
- **Indexing:** BWA whole-genome index built successfully (`.amb`, `.ann`, `.bwt`, `.pac`, `.sa`).
- **Code:**
  ```bash
  #Bash
  #Download and index reference genome
  bash download_index_reference.sh
  ```

## BWA Alignment of Raw, Paired Fastq Files to Reference Genome
- Aligned raw paired-end FASTQ reads to the human reference genome using BWA-MEM (v0.7.17), including proper read group headers required for downstream GATK processing.

- Reference Genome: GRCh38 primary assembly (GRCh38.primary_assembly.genome.fa)

- Algorithm: bwa mem with the -M flag enabled to mark shorter split hits as secondary (ensures Picard/GATK compatibility)

- Metadata & Read Groups: Applied complete Illumina @RG tags to preserve sample provenance across paired tumor/normal analyses:

- Normal Sample (SM:NORMAL): Run SRR29788251 (Library SRX25330419, Flowcell HCMCWDRX2.1)

- Tumor Sample (SM:TUMOR): Run SRR29788252 (Library SRX25330418, Flowcell HCLTMDSX3.1)

- Resource Optimization: Dynamically assigns CPU threads based on host capacity (nproc - 1).

- Output: Intermediate uncompressed SAM files (normal.sam, tumor.sam) directed to data/aligned/.

- Code:
   
  ```bash
  # Bash
  # Run alignment pipeline
  bash align_reads.sh
  ```
## Alignment Processing using Samtools

**Pipeline Overview**

This script automates post-alignment processing of raw SAM files into indexed BAM files using **samtools**, following standard practices (such as HBC Training guidelines) for downstream variant calling.

**Step-by-Step Execution Workflow**

  1. **Environment & Resource Allocation**
     - Sets strict shell execution modes (`set -euo pipefail`) to ensure robust error handling.
     - Creates logging directories and redirects outputs to a dedicated log file.
     - Dynamically allocates multithreading worker threads based on available CPU cores (`SAM_THREADS=$(nproc) -       1`).

  2. **Query-Name Sorting (`samtools sort -n`)**
     - Sorts the raw input SAM file (`${sample_name}.sam`) by query/read name.
     - Groups paired-end reads together, which is required for accurate mate-score tagging.

  3. **Mate Tagging (`samtools fixmate -m`)**
     - Fills in mate coordinates, flags, and adds mate-score tags (`-m`).
     - Prepares duplicate pair scoring metrics required for `samtools markdup`.
  
  4. **Genomic Coordinate Sorting (`samtools sort`)**
     - Re-sorts the alignment records by genomic coordinates (chromosome and start position).
     - Prepares the BAM file for position-based duplicate identification and indexing.
  
  5. **Duplicate Marking & Removal (`samtools markdup -r`)**
     - Identifies PCR and optical duplicate reads using the mate tags added during `fixmate`.
     - Removes marked duplicates from the alignment (`${sample_name}_markdup.bam`).
  
  6. **Indexing & Cleanup**
     - Generates a spatial index file (`.bai`) using `samtools index` to allow fast random access by downstream          tools.
     - Cleans up intermediate BAM files (`querysort`, `fixmate`, and `coordsort`) to conserve disk space.
  7. **Code**
      ```bash
      #Bash
      #Execute alignment processing script
      bash alignment_processing.sh
      ```
---

**Sample Processing**

The processing function is executed sequentially for both **`normal`** and **`tumor`** sample pairs.


