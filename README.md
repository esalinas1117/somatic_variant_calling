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

## Reference Genome Sequence Dictionary and FASTA Indexing

Generated two additional reference indices required by GATK (distinct from the BWA index used for alignment): a sequence dictionary and a FASTA index. Both were run as ad-hoc commands rather than a dedicated script.

- **Sequence Dictionary (`gatk CreateSequenceDictionary`):** Produces the `.dict` file GATK uses to validate contig names/lengths and enable random access across tools (Mutect2, FilterMutectCalls, GetPileupSummaries, etc.).
- **FASTA Index (`samtools faidx`):** Produces the `.fai` index enabling fast random access into the reference FASTA by coordinate.

**Code:**
```bash
# Bash
# Create sequence dictionary
gatk CreateSequenceDictionary \
  -R data/reference/GRCh38.primary_assembly.genome.fa \
  -O data/reference/GRCh38.primary_assembly.genome.dict

# Create FASTA index
samtools faidx data/reference/GRCh38.primary_assembly.genome.fa
```

**Output:** `GRCh38.primary_assembly.genome.dict` and `GRCh38.primary_assembly.genome.fa.fai` generated successfully alongside the existing BWA index files (`.amb`, `.ann`, `.bwt`, `.pac`, `.sa`).

## Panel of Normals (PoN) Download

Downloaded the GATK Best Practices somatic panel of normals, used by Mutect2 to filter out recurrent technical artifacts and rare germline variants that appear across unrelated normal samples.

- **Resource:** `1000g_pon.hg38.vcf.gz` (+ `.tbi` index), from the public GATK Best Practices resource bucket (`gs://gatk-best-practices/somatic-hg38/`) — the same bucket later used for the `small_exac_common_3.hg38.vcf.gz` contamination resource.

**Code:**
```bash
# Bash
# Download panel of normals
wget -P data/resources/ https://storage.googleapis.com/gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz
wget -P data/resources/ https://storage.googleapis.com/gatk-best-practices/somatic-hg38/1000g_pon.hg38.vcf.gz.tbi
```

**Output:** `1000g_pon.hg38.vcf.gz` (17 MB) and its index stored in `data/resources/`.

## Somatic Variant Calling with GATK Mutect2

Called candidate somatic variants by running GATK4 Mutect2 in matched tumor-normal mode, comparing the tumor (`tumor_markdup.bam`) against the matched normal (`normal_markdup.bam`), with the panel of normals supplied to suppress recurrent artifacts.

- **Inputs:** `normal_markdup.bam` (`NORMAL`), `tumor_markdup.bam` (`TUMOR`), GRCh38 primary assembly reference, `1000g_pon.hg38.vcf.gz` panel of normals.
- **Annotations:** Requested standard QC annotations (`ClippingRankSumTest`, `DepthPerSampleHC`, `MappingQualityRankSumTest`, `MappingQualityZero`, `QualByDepth`, `ReadPosRankSumTest`, `RMSMappingQuality`, `FisherStrand`, `MappingQuality`, `DepthPerAlleleBySample`, `Coverage`).
- **Output:** Raw, unfiltered somatic VCF (`mutect2_NORMAL_TUMOR_GRCh38.raw.vcf`) plus its companion `.stats` file (used later by `FilterMutectCalls`).

**Key Findings:**
- **Raw Candidate Variants:** 176 candidate somatic variant records emitted prior to any filtering. Given the pipeline is developed on a 1-million-read subsample per sample (rather than full-depth sequencing), this is an expected, modest number — not the final call set.

**Code:**
```bash
# Bash
# Run GATK Mutect2 somatic variant calling
bash gatk_mutect2.sh
```

## Contamination Estimation (GetPileupSummaries & CalculateContamination)

Prior to filtering the raw Mutect2 calls, estimated cross-sample DNA contamination using GATK's `GetPileupSummaries` → `CalculateContamination` workflow, since library prep or sequencing can occasionally introduce reads from a genetically distinct source that would otherwise confound somatic filtering.

- **Germline Resource:** `small_exac_common_3.hg38.vcf.gz`, a curated panel of ~59,295 common, biallelic population SNPs, from the same GATK Best Practices bucket as the panel of normals.
- **Procedure:** Ran `GetPileupSummaries` independently on both the tumor and normal BAMs against this SNP panel, then ran `CalculateContamination` on the tumor pileups using the normal as the matched sample (also producing a tumor minor-allele-fraction segmentation used to distinguish copy-number-driven allelic imbalance from true contamination).

**Key Findings:**
- **Site Coverage:** Of the sites retained in each pileup table, >99.9% carried real read coverage in both samples (19,561 / 19,579 tumor sites; 19,408 / 19,420 normal sites) — a coverage density consistent with the underlying FASTQ data being whole-exome sequencing (WXS) rather than whole-genome, since exome capture concentrates reads onto the coding regions where this SNP panel's sites are drawn from.
- **Contamination Estimate:** 0.77% (± 0.25% SE) in the tumor sample — well below the ~5% threshold that would indicate meaningful cross-sample contamination. Given the near-universal site coverage above, this is a well-powered, reliable estimate.
- **Tumor Segmentation:** Minor allele fractions across chromosomal segments ranged from ~0.15 to ~0.48, consistent with allelic imbalance driven by HCC1395's well-documented aneuploid, copy-number-unstable genome (at coarse resolution, given the modest number of informative SNPs available).

**Code:**
```bash
# Bash
# Run contamination estimation workflow
bash contamination_cleanup.sh
```

## Somatic Variant Calling Re-run with a Germline Resource

Re-ran GATK Mutect2 with a population germline resource (`af-only-gnomad.hg38.vcf.gz`) added to the call, so that population allele frequency (POPAF) annotations would be based on real gnomAD data instead of a flat default. This was a targeted addition rather than a full pipeline re-run: with tumor and normal derived from the same patient, the matched-normal comparison already captures most of this patient's own germline variants directly, but since both samples are shallow 1-million-read subsamples, a population resource adds useful corroborating evidence at sites the normal alone under-covers.

- **Germline Resource:** `af-only-gnomad.hg38.vcf.gz` (~3.18 GB), from the same GATK Best Practices resource bucket as the panel of normals and contamination SNP panel.
- **Script Updates:** Added `--germline-resource` to `gatk_mutect2.sh`; corrected the Java heap allocation to `-Xmx6g` (appropriate for the 8 GB EC2 instance); routed all script output (not just the GATK command) into the run log.
- **Verification:** Confirmed via the raw VCF's own `##GATKCommandLine` header that the germline resource and panel-of-normals flags were both actually applied, not just present in the script.

**Key Findings:**
- **Raw Candidate Variants:** 176 candidate somatic variant records — unchanged from the original run, confirming the germline resource affects variant *annotation* rather than *emission*.
- **POPAF Spot-Check:** Of the 176 candidates, 148 still received the tumor-normal-mode "not-in-resource" default (POPAF = 6.00), while the remaining ~28 received real gnomAD-derived population allele frequencies (ranging from 0.008 to 8.33) — confirming the resource was genuinely consulted at those sites.
- **Runtime:** 48.52 minutes.

**Code:**
```bash
# Bash
# Re-run GATK Mutect2 with the germline resource added
bash gatk_mutect2.sh
```

## Variant Filtering with FilterMutectCalls

Filtered the raw Mutect2 calls with `FilterMutectCalls`, supplying the contamination and tumor-segmentation tables generated earlier, then compared the resulting FILTER-column breakdown against a prior run made without the germline resource to assess what the added population data changed.

- **Inputs:** `mutect2_NORMAL_TUMOR_GRCh38.raw.vcf`, `contamination_NORMAL_TUMOR.table`, `segments_TUMOR.table`.
- **Output:** Filtered somatic VCF (`mutect2_NORMAL_TUMOR_GRCh38.filtered.vcf`) with per-variant FILTER annotations and an accompanying `filteringStats.tsv`.

**Key Findings:**
- **Bottom line unchanged:** 176 total candidates and 12 `PASS` variants in both the original and germline-resource-informed runs — the germline resource did not alter the confident somatic call set.
- **`weak_evidence` concern resolved:** the total count of variants carrying a `weak_evidence` tag was identical (151) in both runs, as expected since that filter is driven by read-support log-odds (TLOD), independent of population allele frequency. Only the *alone* count shifted (109 → 104), because 5 of those variants now also carry a `germline` tag now that gnomAD has real data at those positions — same variants, same outcome, better-explained reason.
- **`germline` filtering improved:** germline-tagged variants rose from ~7 to 26, and in the new run every one is paired with at least one other filter reason rather than firing alone — consistent with real, corroborated evidence replacing a flat default at the ~28 gnomAD-informed sites.
- **`contamination` tagging also rose (~15 → 31)** despite an unchanged contamination estimate (0.77%), consistent with GATK's contamination filter also weighing population allele frequency alongside the contamination table.

**Code:**
```bash
# Bash
# Filter the germline-resource-informed Mutect2 calls
bash filter_calls.sh
```

