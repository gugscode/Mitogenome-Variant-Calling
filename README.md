---

#### FASTQ Processing and mtDNA Variant Calling Pipeline

---

#### Overview

This Bash script automates the processing of paired-end FASTQ files, including quality assessment, trimming, alignment, duplicate marking, and **mitochondrial variant calling (SNVs and INDELs)**.

It leverages the following tools:

* **FastQC**
* **MultiQC**
* **Fastp**
* **BWA**
* **SAMtools**
* **Picard**
* **Nextflow**
* **mtDNA-Server 2 (Docker execution)**

The pipeline performs:

1. Quality Analysis using *FastQC* and *MultiQC* (Pre- and Post-trimming).
2. Trimming and Adapter Removal using *Fastp*.
3. Alignment of trimmed reads against a mitochondrial reference genome using *BWA*.
4. Conversion of SAM to BAM, sorting, and duplicate marking using *SAMtools* and *Picard*.
5. **Mitochondrial variant calling (SNVs + INDELs) using mtDNA-Server 2 (Nextflow DSL2).**

---

#### Prerequisites

Ensure the following software/tools are installed and accessible in your `$PATH`:

* `FastQC`
* `MultiQC`
* `Fastp`
* `BWA`
* `SAMtools`
* `Picard`
* Java Runtime Environment (for Picard)
* `Nextflow` (>= 22.10.4)
* `Docker` (required for mtDNA-Server 2 execution)

Verify Nextflow installation:

```bash
nextflow -version
```

---

#### Directory Structure

Before running the script, create and organize your directories as follows:

* **Input Directory:** Contains raw FASTQ files (`*_R1.fastq` and `*_R2.fastq`).
* **Output Directories:** The script will automatically create these:

  * Processed FASTQ files
  * Quality reports (pre- and post-trimming)
  * SAM/BAM files and final sorted BAM files
  * Marked duplicate files and metrics
  * mtDNA-Server-2 results directory

---

#### How to Use

1. **Set Variables**: Update the following paths in the script to match your file structure:

   * `input_dir`: Path to raw FASTQ files.
   * `output_dir`: Directory for trimmed FASTQ files.
   * `fastqc_dir_pre`: Directory for pre-trimming quality reports.
   * `fastqc_dir_post`: Directory for post-trimming quality reports.
   * `multiqc_dir`: Directory for consolidated MultiQC reports.
   * `alignment_dir`: Directory for alignment (SAM) files.
   * `reference_mtDNA`: Path to the reference genome file (FASTA format).
   * `picard_output_dir`: Directory for Picard-marked BAM files.
   * `mtdna_server_dir`: Directory where mtDNA-Server 2 will run.
   * `mtdna_server_project`: Project name for mtDNA-Server 2.
   * `mtdna_server_detection_limit`: Heteroplasmy detection limit (e.g., 0.03).
   * `mtdna_server_mode`: Variant detection mode (e.g., `"fusion"`).

2. Make Executable:

```bash
chmod +x mitogenome_processing.sh
```

3. Run the Script:

```bash
./mitogenome_processing.sh
```

---

#### Pipeline Workflow

1. Initial Quality Check:

   * Generates pre-trimming quality reports for raw FASTQ files using `FastQC`.
   * Combines individual reports using `MultiQC`.

2. Trimming with Fastp:

   * Removes adapters and low-quality bases.
   * Produces trimmed FASTQ files with a summary HTML report.

3. Post-Quality Check:

   * Generates quality reports for trimmed FASTQ files.

4. Alignment:

   * Aligns trimmed reads to the mitochondrial reference genome using `BWA` and outputs SAM files.

5. Conversion and Sorting:

   * Converts SAM files to BAM format using `SAMtools`.
   * Sorts BAM files for downstream processing.

6. Duplicate Marking:

   * Marks and removes duplicates from BAM files using `Picard`.

7. Variant Calling with mtDNA-Server 2:

   * All duplicate-removed BAM files (`*.marked_remov.bam`) are automatically passed to **mtDNA-Server 2**.
   * Executed using Nextflow DSL2 with Docker.
   * Detects:

     * SNVs
     * INDELs
     * Heteroplasmy levels
     * Coverage statistics
     * Annotated variant tables

---

#### Outputs

* Quality Reports:

  * Pre-trimming FastQC reports
  * Post-trimming FastQC reports
  * MultiQC summary reports

* Processed Files:

  * Trimmed FASTQ files in `output_dir`
  * Aligned SAM files in `alignment_dir`
  * Sorted BAM files in `sorted_bam`
  * Marked BAM files and metrics in `picard_output_dir`

* Variant Calling Results:

  * SNV tables
  * INDEL tables
  * Heteroplasmy estimates
  * Quality control metrics
  * Final annotated variant datasets
  * Located in: `mtdna_server_dir/results/`

---

#### Troubleshooting

* Ensure paths to tools and reference files are correct.
* Confirm the mitochondrial reference genome is indexed:

```bash
bwa index reference.fasta
```

* Ensure Docker is running before executing mtDNA-Server 2.
* Verify BAM files are sorted and duplicate-removed.
* Inspect Nextflow logs if variant calling fails.

---

#### Acknowledgments

This pipeline uses tools developed by open-source communities. Please refer to their documentation for further details:

* [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
* [MultiQC](https://multiqc.info/)
* [Fastp](https://github.com/OpenGene/fastp)
* [BWA](http://bio-bwa.sourceforge.net/)
* [SAMtools](http://www.htslib.org/)
* [Picard](https://broadinstitute.github.io/picard/)
* [Nextflow](https://www.nextflow.io/)
* [mtDNA-Server 2](https://github.com/genepi/mtdna-server-2)

---

#### References

* FastQC: Andrews, S. FastQC: A Quality Control Tool for High Throughput Sequence Data.
* MultiQC: Ewels et al. (2016). MultiQC. *Bioinformatics*, 32(19), 3047–3048.
* Fastp: Chen et al. (2018). fastp. *Bioinformatics*, 34(17), i884–i890.
* BWA: Li & Durbin (2009). *Bioinformatics*, 25(14), 1754–1760.
* SAMtools: Li et al. (2009). *Bioinformatics*, 25(16), 2078–2079.
* Picard Tools: Broad Institute.
* mtDNA-Server 2: Weissensteiner et al. Cloud-based mitochondrial DNA analysis platform.

---
