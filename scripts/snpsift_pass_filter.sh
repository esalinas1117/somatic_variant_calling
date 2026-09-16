#!/bin/bash
set -euo pipefail

BASEDIR="$HOME/somatic_variant_calling"
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"

OUTDIR="$BASEDIR/results/variant_filtering"
LOGDIR="$BASEDIR/logs"
mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

FILTERED_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.filtered.vcf"
PASS_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.pass.vcf"
LOG_FILE="${LOGDIR}/snpsift_pass_filter_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting SnpSift PASS-only filtering ==="
echo "Logging output to: ${LOG_FILE}"

conda run -n annotation_env SnpSift filter \
    -noLog \
    "( FILTER = 'PASS' )" \
    "${FILTERED_VCF}" > "${PASS_VCF}"

echo "=== SnpSift PASS filtering completed: ${PASS_VCF} ==="
