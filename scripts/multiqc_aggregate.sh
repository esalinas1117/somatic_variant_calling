#!/usr/bin/env bash
set -euo pipefail

# Directory definitions
BASEDIR="$HOME/somatic_variant_calling"
RESULTSDIR="$BASEDIR/results"
OUTDIR="$RESULTSDIR/multiqc"
LOGDIR="$BASEDIR/logs"

# Ensure output and log directories exist
mkdir -p "${OUTDIR}"

# Redirect stdout and stderr to log file
exec > >(tee -i "${LOGDIR}/multiqc.log") 2>&1

echo "Starting MultiQC aggregation..."

# Run MultiQC across untrimmed FastQC and Aligned QC output locations
multiqc \
    "${RESULTSDIR}/fastqc/raw" \
    "${RESULTSDIR}/alignedqc" \
    --outdir "${OUTDIR}" \
    --filename "somatic_variant_calling_multiqc_report.html" \
    --force

echo "MultiQC report successfully generated at: ${OUTDIR}/somatic_variant_calling_multiqc_report.html"
