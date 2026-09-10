#!/bin/bash
set -euo pipefail

# Base directory definitions
BASEDIR="$HOME/somatic_variant_calling"
REF_FA="$BASEDIR/data/reference/GRCh38.primary_assembly.genome.fa"
PON_VCF="$BASEDIR/data/resources/1000g_pon.hg38.vcf.gz"
GERMLINE_RESOURCE="$BASEDIR/data/resources/af-only-gnomad.hg38.vcf.gz"

# Input BAM files
NORMAL_BAM="$BASEDIR/data/aligned/normal_markdup.bam"
TUMOR_BAM="$BASEDIR/data/aligned/tumor_markdup.bam"

# Sample metadata
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"

# Output directories
OUTDIR="$BASEDIR/results/variant_calling"
LOGDIR="$BASEDIR/logs"

mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

# Output files
RAW_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.raw.vcf"
LOG_FILE="${LOGDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

# Route all script output (not just the gatk command) into the log file
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting GATK Mutect2 Somatic Calling (Memory: 6GB) ==="
echo "Logging output to: ${LOG_FILE}"

gatk --java-options "-Xmx6g" Mutect2 \
    --reference "${REF_FA}" \
    --input "${NORMAL_BAM}" \
    --normal-sample "${NORMAL_SAMPLE_NAME}" \
    --input "${TUMOR_BAM}" \
    --tumor-sample "${TUMOR_SAMPLE_NAME}" \
    --panel-of-normals "${PON_VCF}" \
    --germline-resource "${GERMLINE_RESOURCE}" \
    --output "${RAW_VCF}"

echo "=== Mutect2 Calling Completed: ${RAW_VCF} ==="
