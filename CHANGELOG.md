# MDHHS-Bioinformatics/basset: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project follows [Semantic Versioning](https://semver.org/).

## v1.1.0 - [10/13/2026]

This release improves the robustness of species-specific typing workflows, corrects input channel assignments, updates software dependencies, and improves documentation and input validation.

### Improvements
- Updated HICAP and MeningoType modules to report `Untypeable` results for unsuccessful typing predictions without terminating the pipeline.
- Updated the EL_GATO container from v1.22.0 to v1.23.0.

### Bug fixes
- Fixed incorrect input channel assignments for ARIBA (*Vibrio cholerae*) and SeroBA (*Streptococcus pneumoniae*).
- Corrected input validation and parameter descriptions in `nextflow_schema.json` and `schema_input.json`.

### Documentation
- Updated `README.md`, `docs/output.md`, and `docs/parameters.md` to reflect current pipeline functionality, input requirements, parameters, and outputs.

### Notes
- Users analyzing *V. cholerae* or *S. pneumoniae* should consider reanalyzing previously processed isolates affected by the incorrect input channel assignments.

## v1.0.0 - [06/25/2026]

### Added
- Initial release of BaSSeT.
- Core workflow implemented.
- Documentation for usage, workflow, parameters, and outputs.
- Containerized execution using Docker/Apptainer/Singularity.
- Example samplesheet provided in `assets/`.

### Notes
- First stable release of the pipeline.

