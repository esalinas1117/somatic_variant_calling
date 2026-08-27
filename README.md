# Somatic Variant Calling Workflow
Documenting processing steps from FastQ QC to somatic variant calling using GATK4 on cell lines HCC1395 (ATCC, CRL-2324) and HCC1395BL (ATCC, CRL-2325).

## Data Download Strategy
- **Normal Sample (HCC1395BL):** SRR29788251
- **Tumor Sample (HCC1395):** SRR29788252
- **Subsampling:** Subsampled first 1,000,000 reads (-X 1000000) using fastq-dump to optimize EC2 disk usage during pipeline development.
- **Target Region:** Whole-genome reads; alignment will be restricted to Chromosome 22 downstream.
- **Per Base Sequence Quality:** Pass across all cycles.
- **Adapter Content:** $<0.1\%$ contamination detected.
- **Trimming Decision:** High base quality ($Q > 30$); no preliminary trimming required prior to alignment.

- **Assembly:** GRCh38 Primary Assembly (GENCODE Release 44)
- **Indexing:** BWA whole-genome index built successfully (`.amb`, `.ann`, `.bwt`, `.pac`, `.sa`).
