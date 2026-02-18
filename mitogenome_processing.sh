#!/bin/bash
set -euo pipefail

# Directory settings
input_dir="/path/to/input/directory"                 # Directory containing the original FASTQ files
output_dir="/path/to/output/directory"               # Directory for Fastp processed files
fastqc_dir_pre="/path/to/FastQC_pre_reports"         # Directory for FastQC reports before Fastp
fastqc_dir_post="/path/to/FastQC_post_reports"       # Directory for FastQC reports after Fastp
multiqc_dir="/path/to/MultiQC_reports"               # Directory for MultiQC reports
alignment_dir="/path/to/alignment/files"             # Directory for SAM files
reference_mtDNA="/path/to/reference/fasta/file"      # mtDNA reference sequence
picard_output_dir="/path/to/marked/files"            # Directory for marked BAM files

# mtDNA-server-2 settings (NEW)
mtdna_server_dir="/path/to/mtdna_server_2_run"        # Working directory for mtDNA-server-2 run (will be created)
mtdna_server_results="$mtdna_server_dir/results"      # Output results directory
mtdna_server_project="my-mtdna-job"                   # Project name shown in outputs
mtdna_server_detection_limit="0.03"                   # e.g., 0.03
mtdna_server_mode="fusion"                            # e.g., fusion
mtdna_server_revision="v2.1.16"                       # pipeline version/tag
mtdna_server_profile="docker"                         # docker or singularity (if you use that)

# Creating necessary directories
mkdir -p "$output_dir" "$fastqc_dir_pre" "$fastqc_dir_post" "$multiqc_dir" "$alignment_dir" "$picard_output_dir"
mkdir -p bam_files sorted_bam
mkdir -p "$mtdna_server_dir" "$mtdna_server_results"

# Step 1: Initial quality analysis with FastQC
echo "Starting initial quality analysis..."
fastqc "$input_dir"/*_R1.fastq "$input_dir"/*_R2.fastq --outdir "$fastqc_dir_pre"
multiqc "$fastqc_dir_pre" -o "$multiqc_dir"
echo "Initial quality analysis completed!"

# Step 2: Processing FASTQ files with Fastp
echo "Starting FASTQ file processing..."
for r1 in "$input_dir"/*_R1.fastq; do
    r2=${r1/_R1/_R2}
    base=$(basename "$r1" _R1.fastq)

    trimmed_r1="$output_dir/${base}_R1_trimmed.fastq"
    trimmed_r2="$output_dir/${base}_R2_trimmed.fastq"

    fastp -i "$r1" -I "$r2" -o "$trimmed_r1" -O "$trimmed_r2" \
          -q 20 -5 20 -3 20 -r 20 \
          --cut_front_window_size 3 \
          --cut_tail_window_size 3 --cut_right_window_size 3 \
          --detect_adapter_for_pe \
          -w 10 -D --dup_calc_accuracy 6 \
          --report_title "$base Report" --html "$output_dir/${base}_report.html"
done
echo "Processing completed!"

# Step 3: Post-processing quality analysis with FastQC and MultiQC
echo "Starting post-processing quality analysis..."
fastqc "$output_dir"/*trimmed.fastq --outdir "$fastqc_dir_post"
multiqc "$fastqc_dir_post" -o "$multiqc_dir"
echo "Post-processing quality analysis completed!"

# Step 4: Alignment with BWA
echo "Starting alignment with BWA..."
for r1_file in "$output_dir"/*R1_trimmed.fastq; do
    base_name=$(basename "$r1_file" _R1_trimmed.fastq)
    r2_file="$output_dir/${base_name}_R2_trimmed.fastq"
    output_file="$alignment_dir/${base_name}.sam"

    bwa mem "$reference_mtDNA" "$r1_file" "$r2_file" > "$output_file"
done
echo "Alignment completed!"

# Step 5: Conversion of SAM to BAM
echo "Converting SAM files to BAM..."
for sam_file in "$alignment_dir"/*.sam; do
    base_name=$(basename "$sam_file" .sam)
    bam_file="bam_files/${base_name}.bam"

    samtools view -bS "$sam_file" -o "$bam_file"
done
echo "Conversion to BAM completed!"

# Step 6: Sorting BAM files
echo "Sorting BAM files..."
for bam_file in bam_files/*.bam; do
    base_name=$(basename "$bam_file" .bam)
    sorted_bam_file="sorted_bam/${base_name}_sorted.bam"

    samtools sort -o "$sorted_bam_file" "$bam_file"
done
echo "Sorting completed!"

# Step 7: Marking and removing duplicates with Picard
echo "Marking and removing duplicates..."
for sorted_bam_file in sorted_bam/*_sorted.bam; do
    base_name=$(basename "$sorted_bam_file" _sorted.bam)
    output_file="$picard_output_dir/${base_name}.marked_remov.bam"
    metrics_file="$picard_output_dir/${base_name}.metrics.txt"

    java -jar picard.jar MarkDuplicates \
        REMOVE_DUPLICATES=true \
        I="$sorted_bam_file" \
        O="$output_file" \
        M="$metrics_file"
done
echo "Marking duplicates completed!"

# Step 8 (NEW): Run mtDNA-server-2 (SNVs + INDELs) via Nextflow on deduplicated BAMs
echo "Starting mtDNA-server-2 (Nextflow) variant calling on BAMs..."

# Create mtDNA-server-2 config file dynamically
mtdna_cfg="$mtdna_server_dir/mtdna-server-2.config"

cat > "$mtdna_cfg" <<EOF
params {
    project         = "${mtdna_server_project}"
    files           = "${picard_output_dir}/*.marked_remov.bam"
    output          = "${mtdna_server_results}/"
    detection_limit = ${mtdna_server_detection_limit}
    mode            = "${mtdna_server_mode}"
}
EOF

# Run pipeline
# Requires: nextflow >=22.10.4 and docker installed/configured
nextflow run genepi/mtdna-server-2 -r "${mtdna_server_revision}" -c "$mtdna_cfg" -profile "${mtdna_server_profile}"

echo "mtDNA-server-2 completed! Results in: $mtdna_server_results"

# Finalization
echo "Pipeline complete! Check the processed files and generated reports."
