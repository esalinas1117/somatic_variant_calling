#!/bin/bash
set -euo pipefail

BASEDIR="$HOME/somatic_variant_calling"
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"
SNPEFF_GENOME="hg38"

RESOURCE_DIR="$BASEDIR/data/resources"
OUTDIR="$BASEDIR/results/variant_annotation"
LOGDIR="$BASEDIR/logs"
mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

INPUT_VCF="$BASEDIR/results/variant_filtering/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.pass.no_lcr.vcf"
PEDIGREE_HEADER="${RESOURCE_DIR}/${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_pedigree_header.txt"
PEDIGREE_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.pedigree_header.vcf"
SNPEFF_VCF="${OUTDIR}/mutect2_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}_GRCh38.snpeff.vcf"
CSV_STATS="${OUTDIR}/snpeff_stats_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.csv"
HTML_REPORT="${OUTDIR}/snpeff_stats_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.html"
LOG_FILE="${LOGDIR}/snpeff_annotate_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== Step 1: Appending pedigree header ==="
bcftools annotate \
    --header-lines "${PEDIGREE_HEADER}" \
    "${INPUT_VCF}" \
    > "${PEDIGREE_VCF}"

echo "=== Step 2: Running SnpEff annotation (cancer mode) ==="
_JAVA_OPTIONS="-Xmx4g" conda run -n annotation_env snpEff eff \
    -cancer \
    -noLog \
    -csvStats "${CSV_STATS}" \
    -s "${HTML_REPORT}" \
    "${SNPEFF_GENOME}" \
    "${PEDIGREE_VCF}" \
    > "${SNPEFF_VCF}"

echo "=== SnpEff annotation completed: ${SNPEFF_VCF} ==="
