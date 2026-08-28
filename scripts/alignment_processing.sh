#!/bin/bash
# Description: Post-alignment processing using samtools (querysort -> fixmate -> positionsort -> markdup -> index)
# Following HBC Training Intro to Variant Analysis guidelines

set -euo pipefail

BASE_DIR="$HOME/somatic_variant_calling"
ALIGNED_DIR="$BASE_DIR/data/aligned"
LOG_DIR="$BASE_DIR/logs"

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/process_alignments.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Auto-detect CPU threads
THREADS=$(nproc)
if [ "$THREADS" -gt 2 ]; then
    SAM_THREADS=$((THREADS - 1))
else
    SAM_THREADS=$THREADS
fi

echo "=== Starting Alignment File Processing (samtools) ==="
echo "Execution time: $(date)"
echo "Utilizing CPU threads: $SAM_THREADS"

process_sam() {
    local sample_name=$1
    local sam_input="$ALIGNED_DIR/${sample_name}.sam"
    local querysort_bam="$ALIGNED_DIR/${sample_name}_querysort.bam"
    local fixmate_bam="$ALIGNED_DIR/${sample_name}_fixmate.bam"
    local coordsort_bam="$ALIGNED_DIR/${sample_name}_coordsort.bam"
    local final_bam="$ALIGNED_DIR/${sample_name}_markdup.bam"

    echo "----------------------------------------"
    echo "Processing sample: ${sample_name}"

    if [ ! -f "$sam_input" ]; then
        echo "Error: Input SAM file $sam_input not found!"
        exit 1
    fi

    # Step 1: Query-name sort (Required by samtools fixmate)
    echo "[1/4] Sorting by query name (samtools sort -n)..."
    samtools sort -n -@ "$SAM_THREADS" -o "$querysort_bam" "$sam_input"

    # Step 2: Add mate tags required for duplicate marking
    echo "[2/4] Running samtools fixmate -m..."
    samtools fixmate -m -@ "$SAM_THREADS" "$querysort_bam" "$fixmate_bam"

    # Step 3: Coordinate sort
    echo "[3/4] Sorting by genomic coordinate..."
    samtools sort -@ "$SAM_THREADS" -o "$coordsort_bam" "$fixmate_bam"

    # Step 4: Mark duplicates
    echo "[4/4] Marking duplicates with samtools markdup..."
    samtools markdup -r -@ "$SAM_THREADS" "$coordsort_bam" "$final_bam"

    # Step 5: Index final BAM
    echo "Indexing final BAM file..."
    samtools index -@ "$SAM_THREADS" "$final_bam"

    # Clean up intermediate files
    echo "Cleaning up intermediate BAM files for ${sample_name}..."
    rm -f "$querysort_bam" "$fixmate_bam" "$coordsort_bam"

    echo "Completed processing for ${sample_name}. Final file: ${final_bam}"
}

# Process Normal and Tumor samples
process_sam "normal"
process_sam "tumor"

echo "----------------------------------------"
echo "Execution completed at: $(date)"
echo "=== Processing Complete ==="
