# 🚀 Pipeline Usage

This page describes how to run **BaSSeT** and prepare the required input files.

Detailed descriptions of pipeline parameters can be found in
➡ **[`parameters.md`](parameters.md)**

## 1️⃣ Requirements

Install the following software:

* [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (≥ 22.10.1)
* A container runtime:

  * [`Docker`](https://docs.docker.com/engine/installation/) (recommended for local runs)
  * [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/)
  * [`Apptainer`](https://apptainer.org/docs/user/latest/) (recommended for HPC)

> [!NOTE]  
> If using **Singularity** set `NXF_SINGULARITY_CACHEDIR` (or `singularity.cacheDir`) to reuse images later. For example: 
> ```bash
> export NXF_SINGULARITY_CACHEDIR="/path/to/singularity_cache"
> ``````
>
> If using **Apptainer** set `NXF_APPTAINER_CACHEDIR` (or `apptainer.cacheDir`) to reuse images later. For example: 
> ```bash
> export NXF_APPTAINER_CACHEDIR="/path/to/apptainer_cache"
> ``````

---

## 2️⃣ Prepare the samplesheet

The pipeline requires a **CSV samplesheet** describing the samples to analyze.

Specify the file using:

```bash
--input samplesheet.csv
```

Each row corresponds to **one isolate/sample**.

---

### 📥 Samplesheet Specification

The samplesheet must contain **5 columns** with the following headers.

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Unique sample identifier. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina QC trimmed short reads 1. File has to be gzipped and have the extension `.fastq.gz` or `.fq.gz`. (leave empty if not available)                                                 |
| `fastq_2` | Full path to FastQ file for Illumina QC trimmed short reads 2. File has to be gzipped and have the extension `.fastq.gz` or `.fq.gz`. (leave empty for single-end, ONT or assemblies)                                                  |
| `assembly` | Full path to assembled genome file. File can be gzipped and have the extension `.fasta`, `.fa`, `.fas`, `.fna`, `.fasta.gz`, `.fa.gz`, `.fas.gz` or .`fna.gz`|
| `organism`  | Supported organism name (can be `Other` if running ABRicate for any other species). Spaces in organism are automatically converted to underscores (`_`).   |

---

## Supported input types

> [!IMPORTANT]
> All columns must still be present in the CSV file.

> [!IMPORTANT]
> All samples within a run must use the same sequencing format if using `--ont`. The only tools that accept ONT as input are `ECTyper`, `SeqSero2` and `ShigaTyper`.

Most analyses require assemblies as input, though tools like [`el_gato`](https://github.com/CDCgov/el_gato) and [`SeqSero2`](https://github.com/denglab/SeqSero2) provide more accurate results with reads. Reads are mandatory for [`ShigaTyper`](https://github.com/cfsan-biostatistics/shigatyper), [`SeroBA`](https://github.com/sanger-pathogens/seroba) and [ARIBA](https://github.com/sanger-pathogens/ariba).

If the reads are from ONT, add the flag `--ont` when running your analyses.

## Example samplesheet

```csv
sample,fastq_1,fastq_2,assembly,organism
SAMPLE_1,/path/S1_R1.fastq.gz,/path/S1_R2.fastq.gz,/path/S1.fasta,Vibrio_cholerae
SAMPLE_2,/path/S2_R1.fastq.gz,/path/S2_R2.fastq.gz,/path/S2.fasta,Shigella
SAMPLE_3,/path/S3.fastq.gz,,/path/S3.fasta,Salmonella
SAMPLE_4,,,/path/S4.fasta,Escherichia_coli
```

An example samplesheet is available in [`assets/samplesheet.csv`](../assets/samplesheet.csv)


**Supported inputs per tool**
| Organism                         | Tool                                                                 | Aim                                                                                             | fastq1                                      | fastq2                                      | Assembly                                  |
|----------------------------------|----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|---------------------------------------------|---------------------------------------------|---------------------------------------------|
| Acinetobacter baumannii         | [`Kaptive`](https://github.com/klebgenomics/Kaptive)                  | Serotyping based on K and OC antigens                                                           | -                                           | -                                           | ✔️     |
| Escherichia coli                | [`ECTyper`](https://github.com/phac-nml/ecoli_serotyping)             | Serotyping based on O/H antigens; optional pathotyping (only when using `--ecoli_pathotypes`)                                           | <span style="color:orange">Fallback ⚠️</span> (only when ONT) | - | <span style="color:green">Preferred ✔️</span> |
| Haemophilus influenzae          | [`HICap`](https://github.com/scwatts/hicap)                           | Serotyping based on cap locus (a–f)                                                             | -                                           | -                                           | ✔️     |
| Klebsiella pneumoniae complex   | [`Kleborate`](https://github.com/klebgenomics/Kleborate)              | Serotyping (K/O), MLST, virulence genes                                                          | -                                           | -                                           | ✔️     |
| Legionella pneumophila          | [`el_gato`](https://github.com/CDCgov/el_gato)                        | Sequence‑based typing (SBT)                                                                     | <span style="color:green">Preferred ✔️</span>  | <span style="color:green">Preferred ✔️</span>  | <span style="color:orange">Fallback ⚠️</span> |
| Legionella pneumophila          | [`ABRicate`](https://github.com/tseemann/abricate)                    | O‑antigen serogrouping (wzm/wzt)                                                                  | -                                           | -                                           | ✔️     |
| Listeria monocytogenes          | [`LisSero`](https://github.com/MDU-PHL/LisSero)                       | Serogrouping/serotyping (O/H)                                                                         | -                                           | -                                           | ✔️     |
| Neisseria gonorrhoeae           | [`NGMASTER`](https://github.com/MDU-PHL/ngmaster)                     | porB/tbpB typing; AMR typing                                                                    | -                                           | -                                           | ✔️     |
| Neisseria meningitidis          | [`meningotype`](https://github.com/MDU-PHL/meningotype)               | Serogrouping (capsule); MLST; BAST; MenDeVAR                                                               | -                                           | -                                           | ✔️     |
| Pseudomonas aeruginosa          | [`Pasty`](https://github.com/rpetit3/pasty)                           | Serotyping based on O antigen                                                                   | -                                           | -                                           | ✔️     |
| Salmonella                      | [`SeqSero2`](https://github.com/denglab/SeqSero2)                    | Serotyping and antigenic profile                                                                | <span style="color:green">Preferred ✔️</span> (can be ONT) | <span style="color:green">Preferred ✔️</span> (optional for single-end or ONT) | <span style="color:orange">Fallback ⚠️</span> |
| Salmonella                      | [`SISTR`](https://github.com/phac-nml/sistr_cmd)                      | Serovar prediction via antigen genes + cgMLST                                                   | -                                           | -                                           | ✔️     |
| Shigella                        | [`ShigaTyper`](https://github.com/cfsan-biostatistics/shigatyper)     | Serotyping + ipaB                                                                                | ✔️ (can be ONT) | ✔️ (optional for single-end or ONT) | - |
| Shigella                        | [`ShigEiFinder`](https://github.com/LanLab/ShigEiFinder)              | Shigella/EIEC diff.; serotyping; virulence plasmid                                              | <span style="color:orange">Fallback ⚠️</span>     | <span style="color:orange">Fallback ⚠️</span>     | <span style="color:green">Preferred ✔️</span>      |
| Staphylococcus aureus           | [`AgrVATE`](https://github.com/VishnuRaghuram94/AgrVATE)              | agr locus typing                                                                                 | -                                           | -                                           | ✔️     |
| Staphylococcus aureus           | [`sccmec`](https://github.com/rpetit3/sccmec)                         | SCCmec cassette typing                                                                           | -                                           | -                                           | ✔️     |
| Staphylococcus aureus           | [`spaTyper`](https://github.com/HCGB-IGTP/spaTyper)                   | spa repeat typing                                                                                | -                                           | -                                           | ✔️     |
| Streptococcus pneumoniae        | [`pbptyper`](https://github.com/rpetit3/pbptyper)                     | PBP typing                                                                                       | -                                           | -                                           | ✔️     |
| Streptococcus pneumoniae        | [`SeroBA`](https://github.com/sanger-pathogens/seroba)                | Serotyping via cps locus                                                                         | ✔️     | ✔️     | -                                           |
| Streptococcus pyogenes          | [`emmtyper`](https://github.com/MDU-PHL/emmtyper)                     | emm type assignment                                                                              | -                                           | -                                           | ✔️     |
| Vibrio parahaemolyticus         | [`Kaptive`](https://github.com/klebgenomics/Kaptive)                 | K/O serotyping                                                                                   | -                                           | -                                           | ✔️     |
| Vibrio cholerae                 | [ARIBA](https://github.com/sanger-pathogens/ariba)                  | Detect ctxA, ctxB, tcpA, rstR                                                                    | ✔️     | ✔️     | -                                           |
| Vibrio cholerae                 | [`Kaptive`](https://github.com/klebgenomics/Kaptive)                 | O‑antigen serotyping                                                                             | -                                           | -                                           | ✔️     |
| All organisms / Other           | [`ABRicate`](https://github.com/tseemann/abricate)                    | Locus detection, any db via `--abricate_db`                                                      | -                                           | -                                           | ✔️     |

[`ABRicate`](https://github.com/tseemann/abricate) bundles multiple databases for the detection of resistance determinants and virulence factors. This tool is optional and available for any organism in the sample sheet when using `--abricate_db <database>`. Only one database can be used per run:

| Database        | Description                                              | Gene Types                           |
|-----------------|----------------------------------------------------------|---------------------------------------|
| [argannot](https://github.com/katholt/argannot)                      | Antibiotic resistance gene annotation                    | AMR genes                              |
| [bacmet2](https://bacmet.biomedicine.gu.se/)                        | Bacterial biocide & metal resistance genes               | Metal/biocide resistance               |
| [card](https://card.mcmaster.ca/)                                | Comprehensive Antibiotic Resistance Database             | AMR genes                              |
| [ecoh](https://github.com/phac-nml/ecoli_vf)                     | E. coli virulence genes (subset)                         | Virulence factors                      |
| [ecoli_vf](https://github.com/phac-nml/ecoli_vf)                     | Expanded *E. coli* virulence gene set                    | Virulence factors                      |
| [megares](https://megares.meglab.org/)                            | Antibiotic resistance ontology                            | AMR genes                              |
| [ncbi](https://github.com/tseemann/abricate/tree/master/db/ncbi) | NCBI AMRFinder+ gene set                                 | AMR genes                              |
| [plasmidfinder](https://bitbucket.org/genomicepidemiology/plasmidfinder) | Plasmid replicon typing                                  | Plasmid replicons                      |
| [resfinder](https://github.com/cadwaller/resfinder)                  | Resistance gene detection                                 | AMR genes                              |
| [upec_expec_vf](https://github.com/phac-nml/ecoli_vf)                     | UPEC/ExPEC virulence markers                             | Virulence factors                      |
| [vfdb](http://www.mgc.ac.cn/VFs/)                               | Virulence Factor Database                                | Virulence genes                        |
| [victors](https://www.phidias.us/victors/)                         | Bacterial virulence database                             | Virulence genes                        |      


---

# ▶ Running the Pipeline

## Basic run

```bash
nextflow run MDHHS-Bioinformatics/basset \
  -profile singularity \
  --input samplesheet.csv \
  --outdir basset_results
```

This will execute typing analysis for the supported organisms.

>[!NOTE]
>This command downloads this pipeline to `~/.nextflow/assets/MDHHS-Bioinformatics/basset`. You can download the pipeline in a different location using `git clone https://github.com/MDHHS-Bioinformatics/basset.git`. To run the pipeline, specify the path to the cloned repository (e.g. `nextflow run /path/to/basset ...`).

---

## Advanced run

Example enabling optional analyses (ABRicate and _E. coli_ pathotyping with ECTyper) and adjusting resources:

```bash
nextflow run MDHHS-Bioinformatics/basset \
  -profile apptainer \
  --input samplesheet.csv \
  --outdir basset_results \
  --abricate_db vfdb \
  --ecoli_pathotypes \
  --max_memory 50.GB \
  --max_cpus 8 \
  --max_time 4.h
```

---

# 📂 Pipeline Outputs

The pipeline produces the following directories:

```
work/          # Nextflow working directory
results/       # Final pipeline outputs
.nextflow.log  # Execution log
```

The `work/` directory contains intermediate files and may be deleted after successful completion.


For more details about the output files and reports, please refer to the [`Output documentation`](output.md)

---

# 🧠 Best practices & caveats

* **Use high-quality sequences:** Ideally, assemblies should have **<500 contigs ≥500 bp**, reads **≥30× Illumina coverage**, and **no contamination**. Pipelines like [`PHoeNIX`](https://github.com/CDCgov/phoenix), [`Bactopia`](https://bactopia.github.io/latest/) and [`TheiaProk`](https://public-health-bacterial-genomics-theiagen.readthedocs.io/en/latest/theiaprok.html) provide quality checks.

* **Disk cleanup:** After the pipeline completes, you may safely remove the Nextflow `work/` directory to reclaim space.


# 🔁 Reproducibility

For reproducible analyses, run a specific pipeline release:

```bash
nextflow run MDHHS-Bioinformatics/basset \
  -r v1.0.0 \
  -profile singularity \
  --input samplesheet.csv \
  --outdir results
```

Using version tags ensures the same pipeline code and container versions are used.

---

# 🔄 Updating the Pipeline

Nextflow caches pipeline code locally.

To update to the latest version:

```bash
nextflow pull MDHHS-Bioinformatics/basset
```

