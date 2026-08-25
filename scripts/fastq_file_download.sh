#!/bin/bash
# Description: Download and subsample somatic variant calling benchmark data
set -e

RAW_DIR="data/raw_fastq"
mkdir -p "$RAW_DIR"
cd "$RAW_DIR"

echo "Downloading 1M reads from normal sample (SRR29788251)..."
fastq-dump --split-files -X 1000000 --gzip SRR29788251
mv SRR29788251_1.fastq.gz normal_R1.fastq.gz
mv SRR29788251_2.fastq.gz normal_R2.fastq.gz

echo "Downloading 1M reads from tumor sample (SRR29788252)..."
fastq-dump --split-files -X 1000000 --gzip SRR29788252
mv SRR29788252_1.fastq.gz tumor_R1.fastq.gz
mv SRR29788252_2.fastq.gz tumor_R2.fastq.gz

echo "Data download complete."
