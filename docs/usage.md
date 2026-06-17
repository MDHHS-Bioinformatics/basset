# 🚀 Pipeline Usage

This page describes how to run **BaSSeT** and prepare the required input files.

Detailed descriptions of pipeline parameters can be found in
➡ **[`parameters.md`](parameters.md)**

## 1️⃣ Requirements

Install the following software:

* [`Nextflow`](https://docs.seqera.io/nextflow/install) (≥ 22.10.1)
* A container runtime:

  * [`Docker`](https://docs.docker.com/engine/installation/) (recommended for local runs)
  * [`Apptainer`](https://apptainer.org/docs/user/latest/) (recommended for HPC)
  * [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/)

### Container cache setup

For Apptainer or Singularity, use a persistent shared cache directory so container images can be reused across runs and accessed by all compute nodes.

For Apptainer:

```bash
export NXF_APPTAINER_CACHEDIR=/path/to/shared/nextflow/apptainer/cache
```

For Singularity:

```bash
export NXF_SINGULARITY_CACHEDIR=/path/to/shared/nextflow/singularity/cache
```

You can also set these paths in your Nextflow configuration using `apptainer.cacheDir` or `singularity.cacheDir`.

### Optional: prefetch containers

For Apptainer and Singularity users, we recommend pre-pulling all required BaSSeT container images before launching the workflow. This helps avoid issues caused by multiple Nextflow tasks pulling images concurrently, such as race conditions or incomplete cache files.

Helper scripts are provided:

* [`bin/prefetch_basset_containers_apptainer.sh`](./../bin/prefetch_basset_containers_apptainer.sh)
* [`bin/prefetch_basset_containers_singularity.sh`](./../bin/prefetch_basset_containers_singularity.sh)

For Apptainer:

```bash
export NXF_APPTAINER_CACHEDIR=/path/to/shared/nextflow/apptainer/cache
bash prefetch_basset_containers_apptainer.sh
```

For Singularity:

```bash
export NXF_SINGULARITY_CACHEDIR=/path/to/shared/nextflow/singularity/cache
bash prefetch_basset_containers_singularity.sh
```

> [!NOTE]
> `NXF_APPTAINER_CACHEDIR` and `NXF_SINGULARITY_CACHEDIR` control where Nextflow stores SIF images. Apptainer and Singularity also have their own OCI/layer caches, such as `APPTAINER_CACHEDIR` and `SINGULARITY_CACHEDIR`, which are mainly used while pulling or converting OCI images.


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
| `sample`  | Unique sample identifier. Spaces in sample names are automatically converted to underscores (`_`). No symbols other than hyphens (-) or underscores (_) are allowed |
| `fastq_1` | Full path to FastQ file for Illumina or Nanopore QC trimmed reads 1. File has to be gzipped and have the extension `.fastq.gz` or `.fq.gz`. (leave empty if not available)                                                 |
| `fastq_2` | Full path to FastQ file for Illumina QC trimmed short reads 2. File has to be gzipped and have the extension `.fastq.gz` or `.fq.gz`. (leave empty for single-end, ONT or assemblies)                                                  |
| `assembly` | Full path to assembled genome file. File can be gzipped and have the extension `.fasta`, `.fa`, `.fas`, `.fna`, `.fasta.gz`, `.fa.gz`, `.fas.gz` or .`fna.gz`|
| `organism`  | Supported organism name (can be `Other` if running ABRicate for any other species). Spaces in organism are automatically converted to underscores (`_`).   |

---

## Supported input types

> [!IMPORTANT]
> All columns must still be present in the CSV file.

>[!IMPORTANT]
> - Most analyses require assemblies as input. However, tools such as [`el_gato`](https://github.com/CDCgov/el_gato) and [`SeqSero2`](https://github.com/denglab/SeqSero2) may provide more accurate results when reads are supplied.
> - Reads are required for [`ShigaTyper`](https://github.com/CFSAN-Biostatistics/shigatyper), [`SeroBA`](https://github.com/sanger-pathogens/seroba), and [`ARIBA`](https://github.com/sanger-pathogens/ariba). If reads are not provided for a sample, these analyses will be skipped for that sample.

>[!NOTE]
>If the reads are from ONT, add the flag `--ont` when running your analyses. ONT reads are only supported for [`ECTyper`](https://github.com/phac-nml/ecoli_serotyping), [`SeqSero2`](https://github.com/denglab/SeqSero2), and [`ShigaTyper`](https://github.com/CFSAN-Biostatistics/shigatyper)


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
| _Acinetobacter baumannii_         | [`Kaptive`](https://github.com/klebgenomics/Kaptive) with [Wyres et. al](https://doi.org/10.1099/mgen.0.000339) database                  | Serotyping based on K and OC antigens                                                           | -                                           | -                                           | ✔️     |
| _Escherichia coli_                | [`ECTyper`](https://github.com/phac-nml/ecoli_serotyping)             | Serotyping based on O/H antigens; optional pathotyping (only when using `--ecoli_pathotypes`)                                           | <span style="color:orange">Fallback ⚠️</span> (only when ONT) | - | <span style="color:green">Preferred ✔️</span> |
| _Haemophilus influenzae_          | [`HICap`](https://github.com/scwatts/hicap)                           | Serotyping based on _cap_ locus (a–f)                                                             | -                                           | -                                           | ✔️     |
| _Klebsiella pneumoniae_ complex   | [`Kleborate`](https://github.com/klebgenomics/Kleborate)              | Serotyping (K/O), MLST, virulence genes                                                          | -                                           | -                                           | ✔️     |
| _Legionella pneumophila_          | [`el_gato`](https://github.com/CDCgov/el_gato)                        | Sequence‑based typing (SBT)                                                                     | <span style="color:green">Preferred ✔️</span>  | <span style="color:green">Preferred ✔️</span>  | <span style="color:orange">Fallback ⚠️</span> |
| _Legionella pneumophila_          | [`ABRicate`](https://github.com/tseemann/abricate) with [`ReporType`](https://github.com/insapathogenomics/ReporType/tree/main/databases) databases                   | O‑antigen serogrouping (_wzm/wzt_) and subsepcies                                                                 | -                                           | -                                           | ✔️     |
| _Listeria monocytogenes_          | [`LisSero`](https://github.com/MDU-PHL/LisSero)                       | Serogrouping/serotyping (O/H)                                                                         | -                                           | -                                           | ✔️     |
| _Neisseria gonorrhoeae_           | [`NGMASTER`](https://github.com/MDU-PHL/ngmaster)                     | porB/tbpB typing; AMR typing                                                                    | -                                           | -                                           | ✔️     |
| _Neisseria meningitidis_          | [`meningotype`](https://github.com/MDU-PHL/meningotype)               | Serogrouping (capsule); MLST; BAST; MenDeVAR                                                               | -                                           | -                                           | ✔️     |
| _Pseudomonas aeruginosa_          | [`Pasty`](https://github.com/rpetit3/pasty)                           | Serotyping based on O antigen                                                                   | -                                           | -                                           | ✔️     |
| _Salmonella_                      | [`SeqSero2`](https://github.com/denglab/SeqSero2)                    | Serotyping and antigenic profile                                                                | <span style="color:green">Preferred ✔️</span> (can be ONT) | <span style="color:green">Preferred ✔️</span> (optional for single-end or ONT) | <span style="color:orange">Fallback ⚠️</span> |
| _Salmonella_                      | [`SISTR`](https://github.com/phac-nml/sistr_cmd)                      | Serovar prediction via antigen genes + cgMLST                                                   | -                                           | -                                           | ✔️     |
| _Shigella_                        | [`ShigaTyper`](https://github.com/cfsan-biostatistics/shigatyper)     | Serotyping + ipaB                                                                                | ✔️ (can be ONT) | ✔️ (optional for single-end or ONT) | - |
| _Shigella_                        | [`ShigEiFinder`](https://github.com/LanLab/ShigEiFinder)              | Shigella/EIEC diff.; serotyping; virulence plasmid                                              | <span style="color:orange">Fallback ⚠️</span>     | <span style="color:orange">Fallback ⚠️</span>     | <span style="color:green">Preferred ✔️</span>      |
| _Staphylococcus aureus_           | [`AgrVATE`](https://github.com/VishnuRaghuram94/AgrVATE)              | _agr_ locus typing                                                                                 | -                                           | -                                           | ✔️     |
| _Staphylococcus aureus_           | [`sccmec`](https://github.com/rpetit3/sccmec)                         | SCCmec cassette typing                                                                           | -                                           | -                                           | ✔️     |
| _Staphylococcus aureus_           | [`spaTyper`](https://github.com/HCGB-IGTP/spaTyper)                   | _spa_ repeat typing                                                                                | -                                           | -                                           | ✔️     |
| _Streptococcus dysgalactiae_          | [`emmtyper`](https://github.com/MDU-PHL/emmtyper)                     | _emm_ type assignment                                                                              | -                                           | -                                           | ✔️     |
| _Streptococcus pneumoniae_        | [`pbptyper`](https://github.com/rpetit3/pbptyper)                     | PBP typing                                                                                       | -                                           | -                                           | ✔️     |
| _Streptococcus pneumoniae_        | [`SeroBA`](https://github.com/sanger-pathogens/seroba)                | Serotyping via _cps_ locus                                                                         | ✔️     | ✔️     | -                                           |
| _Streptococcus pyogenes_          | [`emmtyper`](https://github.com/MDU-PHL/emmtyper)                     | _emm_ type assignment                                                                              | -                                           | -                                           | ✔️     |
| _Vibrio parahaemolyticus_         | [`Kaptive`](https://github.com/klebgenomics/Kaptive) with [`Zomer Lab`](https://github.com/aldertzomer/vibrio_parahaemolyticus_genomoserotyping) databases                 | K/O serotyping                                                                                   | -                                           | -                                           | ✔️     |
| _Vibrio cholerae_                 | [`ARIBA`](https://github.com/sanger-pathogens/ariba)                  | Detect _ctxA, ctxB, tcpA, rstR_                                                                    | ✔️     | ✔️     | -                                           |
| _Vibrio cholerae_                 | [`Kaptive`](https://github.com/klebgenomics/Kaptive) with [`VicPred`](https://doi.org/10.3389/fmicb.2021.691895) OAGC database                 | O‑antigen serotyping                                                                             | -                                           | -                                           | ✔️     |
| All organisms / Other           | [`ABRicate`](https://github.com/tseemann/abricate)                    | Locus detection, any db via `--abricate_db`                                                      | -                                           | -                                           | ✔️     |

[`ABRicate`](https://github.com/tseemann/abricate) bundles multiple databases for the detection of resistance determinants and virulence factors. This tool is optional and available for any organism in the sample sheet when using `--abricate_db <database>`. Only one database can be used per run:

| Database        | Description                                              | Gene Types                           |
|-----------------|----------------------------------------------------------|---------------------------------------|
| [argannot](https://doi.org/10.1128/aac.01310-13)                      | Antibiotic resistance gene annotation                    | AMR genes                              |
| [bacmet2](https://doi.org/10.1093/nar/gkt1252)                        | Bacterial biocide & metal resistance genes               | Metal/biocide resistance               |
| [card](https://doi.org/10.1093/nar/gkac920)                                | Comprehensive Antibiotic Resistance Database             | AMR genes                              |
| [ecoh](https://doi.org/10.1099/mgen.0.000064)                     | *E. coli* virulence genes (subset)                         | Virulence factors                      |
| [ecoli_vf](https://github.com/phac-nml/ecoli_vf)                     | Expanded *E. coli* virulence gene set                    | Virulence factors                      |
| [megares](https://doi.org/10.1093/nar/gkac1047)                            | Antibiotic resistance ontology                            | AMR genes                              |
| [ncbi](https://doi.org/10.1038/s41598-021-91456-0) | NCBI AMRFinder+ gene set                                 | AMR genes                              |
| [plasmidfinder](https://doi.org/10.1128/AAC.02412-14) | Plasmid replicon typing                                  | Plasmid replicons                      |
| [resfinder](https://doi.org/10.1093/jac/dkaa345)                  | Resistance gene detection                                 | AMR genes                              |
| [upec_expec_vf](https://github.com/FordeGenomics/ST167_Code/blob/main/UPEC-ExPEC_VF/UPEC_ExPEC_VF.tsv)                     | UPEC/ExPEC virulence markers                             | Virulence factors                      |
| [vfdb](https://doi.org/10.1093/nar/gkae968)                               | Virulence Factor Database                                | Virulence genes                        |
| [victors](https://doi.org/10.1093/nar/gky999)                         | Bacterial virulence database                             | Virulence genes                        |      


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

* HICap may fail when no _cap_ is detected. Therefore, HICap errors are ignored. In these cases, you may see the following message:

  ```bash
  -[MDHHS-Bioinformatics/basset] Pipeline completed successfully, but with errored process(es)-
  [xxxx/yyyyy] NOTE: Process `BASSET:HICAP (<sample>)` terminated with an error exit status (1) -- Error is ignored
  ```

  If this occurs, HICAP results cannot be reported.


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

