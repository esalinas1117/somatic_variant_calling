#!/bin/bash
set -euo pipefail

# Base directory definitions
BASEDIR="$HOME/somatic_variant_calling"
REF_FA="$BASEDIR/data/reference/GRCh38.primary_assembly.genome.fa"

# Sample metadata
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"

# Input files
RAW_VCF="$BASEDIR/results/variant_calling/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.raw.vcf"
CONTAMINATION_TABLE="$BASEDIR/results/variant_filtering/contamination_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.table"
SEGMENTS_TABLE="$BASEDIR/results/variant_filtering/segments_${TUMOR_SAMPLE_NAME}.table"

# Output directories
OUTDIR="$BASEDIR/results/variant_filtering"
LOGDIR="$BASEDIR/logs"

mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

# Output files
FILTERED_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.filtered.vcf"
LOG_FILE="${LOGDIR}/filter_mutect_calls_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

# Route all script output into the log file
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting FilterMutectCalls (Memory: 4GB) ==="
echo "Logging output to: ${LOG_FILE}"

gatk --java-options "-Xmx4g" FilterMutectCalls \
    --reference "${REF_FA}" \
    --variant "${RAW_VCF}" \
    --contamination-table "${CONTAMINATION_TABLE}" \
    --tumor-segmentation "${SEGMENTS_TABLE}" \
    --output "${FILTERED_VCF}" 2>&1

echo "=== FilterMutectCalls Completed: ${FILTERED_VCF} ==="
