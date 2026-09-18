#!/bin/bash
set -euo pipefail

BASEDIR="$HOME/somatic_variant_calling"
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"

ANNOT_DIR="$BASEDIR/results/variant_annotation"
OUTDIR="$BASEDIR/results/variant_prioritization"
LOGDIR="$BASEDIR/logs"
mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

INPUT_VCF="${ANNOT_DIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.snpeff.dbSNP.vcf"
EXTRACTED_TABLE="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.annotated_variants.tsv"
LOG_FILE="${LOGDIR}/snpsift_extract_fields_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting field extraction (top annotation per variant) ==="

conda run -n annotation_env SnpSift extractFields \
    -s "," \
    -e "." \
    "${INPUT_VCF}" \
    CHROM POS REF ALT ID \
    "ANN[0].GENE" "ANN[0].TRID" "ANN[0].EFFECT" "ANN[0].IMPACT" "ANN[0].HGVS_C" "ANN[0].HGVS_P" \
    "GEN[${TUMOR_SAMPLE_NAME}].AF" "GEN[${TUMOR_SAMPLE_NAME}].AD" \
    "GEN[${NORMAL_SAMPLE_NAME}].AF" "GEN[${NORMAL_SAMPLE_NAME}].AD" \
    > "${EXTRACTED_TABLE}"

echo "=== Field extraction completed: ${EXTRACTED_TABLE} ==="
