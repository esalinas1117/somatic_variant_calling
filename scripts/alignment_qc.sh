#!/usr/bin/env bash
set -euo pipefail

# Directory definitions
BASEDIR="$HOME/somatic_variant_calling"
REF="$BASEDIR/data/reference/GRCh38.primary_assembly.genome.fa"
BAMDIR="$BASEDIR/data/aligned"
QCDIR="$BASEDIR/results/alignedqc"
LOGDIR="$BASEDIR/logs"

mkdir -p "${QCDIR}"

exec > >(tee -i "${LOGDIR}/alignedqc.log") 2>&1

echo "Starting Picard Alignment QC..."

samples=("normal" "tumor")

for sample in "${samples[@]}"; do
    input_bam="${BAMDIR}/${sample}_markdup.bam"
    
    aln_metrics="${QCDIR}/${sample}_alignment_metrics.txt"
    insert_metrics="${QCDIR}/${sample}_insert_size_metrics.txt"
    insert_pdf="${QCDIR}/${sample}_insert_size_histogram.pdf"

    echo "=== Processing Picard Metrics for: ${sample} ==="

    # 1. Collect Alignment Summary Metrics
    picard CollectAlignmentSummaryMetrics \
        -I "${input_bam}" \
        -R "${REF}" \
        -O "${aln_metrics}"

    # 2. Collect Insert Size Metrics
    picard CollectInsertSizeMetrics \
        -I "${input_bam}" \
        -O "${insert_metrics}" \
        -H "${insert_pdf}" \
        -M 0.5
done

echo "Picard QC processing complete. Outputs saved in ${QCDIR}"
