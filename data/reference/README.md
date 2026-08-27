### FastQC Observations (Raw Reads)
- **Base Quality:** Mean Phred scores remained high across all 4 files ($Q > 24$), indicating high sequencing accuracy.
- **Per Base Sequence Content:** Noted expected positional bias in positions 2–5 (~30% higher T, ~20% lower A) across all samples, corresponding to random hexamer priming during library preparation (no trimming needed).
- **Overrepresented Sequences:** Low-abundance poly-G tails (~0.2%) observed in R2 reads (`normal_R2` and `tumor_R2`), typical of 2-color Illumina sequencing chemistry. Soft-clipping by `bwa mem` will handle these during local alignment.
