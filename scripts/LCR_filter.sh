#!/bin/bash
set -euo pipefail

BASEDIR="$HOME/somatic_variant_calling"
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"

OUTDIR="$BASEDIR/results/variant_filtering"
LOGDIR="$BASEDIR/logs"
LCR_BED="$BASEDIR/data/resources/LCR-hs38.bed"
mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

PASS_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.pass.vcf"
LCR_FILTERED_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.pass.no_lcr.vcf"
LOG_FILE="${LOGDIR}/LCR_filter_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting SnpSift LCR removal ==="
echo "Logging output to: ${LOG_FILE}"

conda run -n annotation_env SnpSift intervals \
    -noLog \
    -x \
    -i "${PASS_VCF}" \
    "${LCR_BED}" > "${LCR_FILTERED_VCF}"

echo "=== SnpSift LCR removal completed: ${LCR_FILTERED_VCF} ==="
