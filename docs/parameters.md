# ⚙️ Pipeline Parameters

This page documents all parameters available for **BaSSeT**.

Pipeline parameters use **double hyphens (`--`)**, while Nextflow runtime options use **single hyphens (`-`)**.

Example:

```bash
nextflow run MDHHS-Bioinformatics/basset \
  -profile singularity \
  --input samplesheet.csv \
  --outdir results
```

---

## 📥 Core Pipeline Parameters

These parameters are required for most pipeline runs.

| Parameter  | Type   | Required | Default     | Description                                                            |
| ---------- | ------ | -------- | ----------- | ---------------------------------------------------------------------- |
| `--input`  | string | ✓        | –           | Path to the input samplesheet (CSV) describing the samples to process. |
| `--outdir` | string | ✓        | `./basset_results` | Directory where pipeline results will be written.               |

---

## 🧬 Analysis Options

These parameters enable optional analysis steps.

| Parameter            | Type    | Default | Description                                                        |
| -------------------- | ------- | ------- | ------------------------------------------------------------------ |
| `--abricate_db` | string | – | ABRicate database to use. If not specified, ABRicate is not run. Supported options: `argannot`, `bacmet2`, `card`, `ecoh`, `ecoli_vf`, `megares`, `ncbi`, `plasmidfinder`, `resfinder`, `upec_expec_vf`, `vfdb`, or `victors`. |
| `--ecoli_pathotypes`  | boolean | `false`  | Use ECTyper to type the 7 diarrheagenic _Escherichia coli_ (DEC) pathotypes: DAEC, EAEC, EHEC, EIEC, EPEC, ETEC and STEC.                            |
| `--master`          | boolean | `true` | Generate a master output.                     |
| `--master_path`      | string | `<outdir>/basset_summary_master.tsv` | Path to prior master file.               |
| `--ont`          | boolean | `false` | Use only if all the reads in the sample sheet are from ONT.                     |

---

## ⚙️ Execution Configuration

These parameters control compute resource limits.

| Parameter      | Type    | Default  | Description                                      |
| -------------- | ------- | -------- | ------------------------------------------------ |
| `--max_cpus`   | integer | `16`     | Maximum CPUs that can be requested by any job.   |
| `--max_memory` | string  | `128.GB` | Maximum memory that can be requested by any job. |
| `--max_time`   | string  | `24.h`   | Maximum execution time for any job.              |

---

## 🔧 Generic Pipeline Options

These parameters control pipeline behavior.

| Parameter              | Type    | Default | Description                              |
| ---------------------- | ------- | ------- | ---------------------------------------- |
| `--help`               | boolean | –       | Display help message and exit.           |
| `--version`            | boolean | –       | Print pipeline version and exit.         |
| `--validate_params`    | boolean | `true`  | Validate parameters against schema.      |
| `--show_hidden_params` | boolean | `false` | Show advanced parameters in help output. |
| `--monochrome_logs`    | boolean | `false` | Disable colored logging output.          |

---

## 🧠 Core Nextflow Arguments

These options are part of **Nextflow itself** and use a **single hyphen (`-`)**.

---

## `-profile`

Select the execution configuration profile.

Example:

```bash
-profile singularity
```

Available profiles typically include:

| Profile       | Description                         |
| ------------- | ----------------------------------- |
| `docker`      | Run using Docker containers         |
| `singularity` | Run using Singularity containers    |
| `apptainer`   | Run using Apptainer containers      |
| `test`        | Run pipeline with bundled test data |

Multiple profiles can be combined:

```bash
-profile test,singularity
```


---

## `-r` (Pipeline Release Version)

Specify the **pipeline version or Git revision** to run.

Example:

```bash
nextflow run MDHHS-Bioinformatics/basset -r v1.0.0
```

This ensures that the **exact same pipeline version** is used for analysis.

You can also run:

| Example       | Description                        |
| ------------- | ---------------------------------- |
| `-r v1.0.0`   | Run a tagged release               |
| `-r main`     | Run the latest development version |
| `-r <commit>` | Run a specific Git commit          |

⚠️ For **reproducible analyses**, it is strongly recommended to run a **tagged release**.

---

## `-resume`

Resume a previously failed or interrupted pipeline run.

```bash
-resume
```

Nextflow will reuse cached results when possible.

---

## `-c`

Provide a custom Nextflow configuration file.

```bash
-c custom.config
```

---

## 🏛 Institutional Configuration Options

These parameters are used when loading configurations from [`nf-core/configs`](https://nf-co.re/configs/).

| Parameter                      | Description                                         |
| ------------------------------ | --------------------------------------------------- |
| `--custom_config_version`      | Git commit ID for institutional configs             |
| `--custom_config_base`         | Base URL for institutional configuration repository |
| `--config_profile_name`        | Name of institutional profile                       |
| `--config_profile_description` | Description of institutional profile                |
| `--config_profile_contact`     | Contact information                                 |
| `--config_profile_url`         | Documentation URL                                   |

---

## ⚡ Custom Configuration (Advanced)

Users can override pipeline resource requirements using custom configuration files.

Example:

```nextflow
process {
    withName: ALIGNMENT {
        memory = 100.GB
        cpus = 8
    }
}
```

Run with:

```bash
nextflow run basset -c custom.config
```

---

## 🧰 Troubleshooting Resource Issues

If a job fails due to insufficient memory or CPUs, you can increase global resource limits:

```bash
--max_memory 200.GB \
--max_cpus 32 \
-resume
```
