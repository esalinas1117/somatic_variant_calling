#!/bin/bash
set -euo pipefail

# Base directory definitions
BASEDIR="$HOME/somatic_variant_calling"
REF_FA="$BASEDIR/data/reference/GRCh38.primary_assembly.genome.fa"
PON_VCF="$BASEDIR/data/resources/1000g_pon.hg38.vcf.gz"

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

echo "=== Starting GATK Mutect2 Somatic Calling (Memory: 32GB) ==="
echo "Logging output to: ${LOG_FILE}"

# Execute Mutect2 and mirror stderr/stdout to terminal and log file
gatk --java-options "-Xmx4g" Mutect2 \ #adapt Xmx4g according to available RAM
    --reference "${REF_FA}" \
    --input "${NORMAL_BAM}" \
    --normal-sample "${NORMAL_SAMPLE_NAME}" \
    --input "${TUMOR_BAM}" \
    --tumor-sample "${TUMOR_SAMPLE_NAME}" \
    --panel-of-normals "${PON_VCF}" \
    --output "${RAW_VCF}" 2>&1 | tee "${LOG_FILE}"

echo "=== Mutect2 Calling Completed: ${RAW_VCF} ==="
