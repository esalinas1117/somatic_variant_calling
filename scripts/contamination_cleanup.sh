#!/bin/bash
set -euo pipefail

# Base directory definitions
BASEDIR="$HOME/somatic_variant_calling"
COMMON_VCF="$BASEDIR/data/resources/small_exac_common_3.hg38.vcf.gz"

# Input BAM files
NORMAL_BAM="$BASEDIR/data/aligned/normal_markdup.bam"
TUMOR_BAM="$BASEDIR/data/aligned/tumor_markdup.bam"

# Sample metadata
NORMAL_SAMPLE_NAME="NORMAL"
TUMOR_SAMPLE_NAME="TUMOR"

# Output directories
OUTDIR="$BASEDIR/results/variant_filtering"
LOGDIR="$BASEDIR/logs"

mkdir -p "${OUTDIR}"
mkdir -p "${LOGDIR}"

# Output files
NORMAL_PILEUPS="${OUTDIR}/${NORMAL_SAMPLE_NAME}_pileups.table"
TUMOR_PILEUPS="${OUTDIR}/${TUMOR_SAMPLE_NAME}_pileups.table"
CONTAMINATION_TABLE="${OUTDIR}/contamination_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.table"
SEGMENTS_TABLE="${OUTDIR}/segments_${TUMOR_SAMPLE_NAME}.table"
LOG_FILE="${LOGDIR}/contamination_${NORMAL_SAMPLE_NAME}_${TUMOR_SAMPLE_NAME}.log"

echo "=== Starting Contamination Estimation Workflow (Memory: 4GB per GATK call) ==="
echo "Logging output to: ${LOG_FILE}"

# Step 0: Download common-SNP germline resource if not already present
if [[ ! -f "${COMMON_VCF}" ]]; then
    echo "--- Downloading small_exac_common_3.hg38.vcf.gz resource ---" | tee -a "${LOG_FILE}"
    wget -nc -P "$(dirname "${COMMON_VCF}")" \
        "https://storage.googleapis.com/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz" 2>&1 | tee -a "${LOG_FILE}"
    wget -nc -P "$(dirname "${COMMON_VCF}")" \
        "https://storage.googleapis.com/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz.tbi" 2>&1 | tee -a "${LOG_FILE}"
fi

# Step 1: Pileup summaries for the tumor sample
echo "--- Running GetPileupSummaries on ${TUMOR_SAMPLE_NAME} ---" | tee -a "${LOG_FILE}"
gatk --java-options "-Xmx4g" GetPileupSummaries \
    --input "${TUMOR_BAM}" \
    --variant "${COMMON_VCF}" \
    --intervals "${COMMON_VCF}" \
    --output "${TUMOR_PILEUPS}" 2>&1 | tee -a "${LOG_FILE}"

# Step 2: Pileup summaries for the normal sample
echo "--- Running GetPileupSummaries on ${NORMAL_SAMPLE_NAME} ---" | tee -a "${LOG_FILE}"
gatk --java-options "-Xmx4g" GetPileupSummaries \
    --input "${NORMAL_BAM}" \
    --variant "${COMMON_VCF}" \
    --intervals "${COMMON_VCF}" \
    --output "${NORMAL_PILEUPS}" 2>&1 | tee -a "${LOG_FILE}"

# Step 3: Calculate contamination (normal used as the matched sample)
echo "--- Running CalculateContamination ---" | tee -a "${LOG_FILE}"
gatk --java-options "-Xmx4g" CalculateContamination \
    --input "${TUMOR_PILEUPS}" \
    --matched-normal "${NORMAL_PILEUPS}" \
    --output "${CONTAMINATION_TABLE}" \
    --tumor-segmentation "${SEGMENTS_TABLE}" 2>&1 | tee -a "${LOG_FILE}"

echo "=== Contamination Estimation Completed ==="
echo "Contamination table: ${CONTAMINATION_TABLE}"
echo "Segments table:      ${SEGMENTS_TABLE}"
