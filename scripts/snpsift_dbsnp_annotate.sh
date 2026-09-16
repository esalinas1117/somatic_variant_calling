#!/bin/bash
set -euo pipefail

BASEDIR="$HOME/somatic_variant_calling"
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"

RESOURCE_DIR="$BASEDIR/data/resources"
OUTDIR="$BASEDIR/results/variant_annotation"
LOGDIR="$BASEDIR/logs"
mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

DBSNP_VCF="${RESOURCE_DIR}/Homo_sapiens_assembly38.dbsnp138.vcf.gz"
SNPEFF_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.snpeff.vcf"
DBSNP_ANNOTATED_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.snpeff.dbSNP.vcf"
LOG_FILE="${LOGDIR}/snpsift_dbsnp_annotate_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Starting dbSNP annotation ==="
conda run -n annotation_env SnpSift annotate \
    "${DBSNP_VCF}" \
    -tabix \
    -noLog \
    "${SNPEFF_VCF}" \
    > "${DBSNP_ANNOTATED_VCF}"

echo "=== dbSNP annotation completed: ${DBSNP_ANNOTATED_VCF} ==="

