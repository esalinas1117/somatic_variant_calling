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

### Post-Alignment Quality Control

Post-alignment quality control was performed on the deduplicated, indexed BAM files (`normal_markdup.bam` and `tumor_markdup.bam`) to evaluate alignment performance, library insert size distributions, and aggregate all QC metrics across the pipeline.

#### 1. Picard Metrics Collection (`CollectAlignmentSummaryMetrics` & `CollectInsertSizeMetrics`)

To complement `samtools flagstat` alignment metrics, Picard tools (v3.1.1) were executed to extract comprehensive mapping statistics and structural library characteristics:

* **Alignment Metrics (`CollectAlignmentSummaryMetrics`)**: Evaluated mapped read percentages, mismatch rates, and pairing distributions against the GRCh38 primary assembly.
* **Insert Size Metrics (`CollectInsertSizeMetrics`)**: Modeled the orientation and fragment size distribution of paired-end reads to ensure proper physical library performance prior to somatic variant calling.

**Key Findings:**
* **Median Insert Sizes**: Calculated at **151 bp** for the Normal sample (`HCC1395BL`) and **154 bp** for the Tumor sample (`HCC1395`), showing tight concordance across paired libraries.
* **Histogram Output**: Generated visual distribution plots (`normal_insert_size_histogram.pdf` and `tumor_insert_size_histogram.pdf`) displaying sharp, unimodal insert size distributions representative of high-quality short-read sequencing library preparation.

```bash
# Bash
# Execute Picard post-alignment QC metrics collection
bash alignment_qc.sh
```
#### 2. MultiQC Report Aggregation

Aggregated quality control metrics across all upstream processing steps into a single interactive HTML report (`somatic_variant_calling_multiqc_report.html`) using MultiQC (v1.19).

**Aggregated Module Summary:**
* **Raw FastQC**: Evaluates per-base sequence quality, GC content, and adapter contamination across raw FASTQ files (`results/fastqc/raw`).
* **Samtools Flagstat & Stats**: Assesses alignment yield, mapping efficiency, and duplicate read counts (`results/alignedqc`).
* **Picard Metrics**: Parses alignment metrics and insert size distributions (`results/alignedqc`).

**Aggregated Statistics:**

| Sample Name | Read Type | Duplication Rate (FastQC) | GC Content (FastQC) | Mapped Reads (Samtools) | Median Insert Size (Picard) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Normal (HCC1395BL)** | Paired-End | ~6.28% | 52–53% | 1.81 M | 151 bp |
| **Tumor (HCC1395)** | Paired-End | ~8.38% | 51–52% | 1.75 M | 154 bp |

**Pipeline Quality Assessment:**
* **High Library Complexity**: Low duplication levels (< 10%) indicate minimal PCR bias and high genomic library diversity.
* **Balanced Sequencing Depth**: Uniform read depth and consistent GC content (~51–53%) between paired normal and tumor samples ensure unbiased germline subtraction and accurate somatic variant frequency calculations.
* **Status**: Both normal and tumor alignments pass quality control thresholds and are validated for downstream somatic variant calling (GATK4 Mutect2).

```bash
# Bash
# Execute MultiQC report aggregation script
bash multiqc_aggregate.sh
```
