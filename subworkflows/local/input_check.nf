//
// Check input samplesheet and get organism-specific channels
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMPLESHEET_CHECK     } from '../../modules/local/samplesheet_check'

/*
========================================================================================
    SUBWORKFLOW FUNCTIONS
========================================================================================
*/

// Returns: [ meta, reads_files, assembly_files ]
def create_input_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.organism     = row.organism
    meta.has_assembly = row.assembly && row.assembly.trim()

    def has_fastq_1 = row.fastq_1 && row.fastq_1.trim()
    def has_fastq_2 = row.fastq_2 && row.fastq_2.trim()

    def reads_files = []
    def assembly_files = []

    /*
     * Determine input type:
     * - paired_end: fastq_1 + fastq_2
     * - single_end: fastq_1 only
     * - assembly: no reads, only assembly
     */
    if (has_fastq_1) {
        if (!file(row.fastq_1).exists()) {
            exit 1, "ERROR: Read 1 FastQ file does not exist for sample '${row.sample}': ${row.fastq_1}"
        }

        if (has_fastq_2) {
            if (!file(row.fastq_2).exists()) {
                exit 1, "ERROR: Read 2 FastQ file does not exist for sample '${row.sample}': ${row.fastq_2}"
            }
            meta.layout = 'paired_end'
            reads_files = [ file(row.fastq_1), file(row.fastq_2) ]
        } else {
            meta.layout = 'single_end'
            reads_files = [ file(row.fastq_1) ]
        }
    }

    if (meta.has_assembly) {
        def assembly_file = file(row.assembly)
        if (!assembly_file.exists()) {
            exit 1, "ERROR: Assembly file does not exist for sample '${row.sample}': ${row.assembly}"
        }
        assembly_files = [ assembly_file ]
    }

    if (!has_fastq_1 && !meta.has_assembly) {
        exit 1, "ERROR: Sample '${row.sample}' must contain reads or an assembly."
    }

    // If no reads were provided, mark as assembly input
    if (!has_fastq_1) {
        meta.layout = 'assembly'
    }

    return [ meta, reads_files, assembly_files ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow INPUT_CHECK {

    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK(samplesheet)

    SAMPLESHEET_CHECK.out.csv
        .splitCsv(header: true, sep: ',')
        .map { create_input_channel(it) }
        .set { input_files }

    // Create one channel per organism
    input_files
        .branch { meta, reads_files, assembly_files ->
            acinetobacter        : meta.organism == 'Acinetobacter_baumannii'
            salmonella           : meta.organism == 'Salmonella'
            escherichia          : meta.organism == 'Escherichia_coli'
            shigella             : meta.organism == 'Shigella'
            lpneumophila         : meta.organism == 'Legionella_pneumophila'
            listeria             : meta.organism == 'Listeria_monocytogenes'
            kpneumoniae          : meta.organism == 'Klebsiella_pneumoniae_complex'
            hinfluenzae          : meta.organism == 'Haemophilus_influenzae'
            saureus              : meta.organism == 'Staphylococcus_aureus'
            sdysgalactiae        : meta.organism == 'Streptococcus_dysgalactiae'
            spyogenes            : meta.organism == 'Streptococcus_pyogenes'
            spneumoniae          : meta.organism == 'Streptococcus_pneumoniae'
            nmeningitidis        : meta.organism == 'Neisseria_meningitidis'
            ngonorrhoeae         : meta.organism == 'Neisseria_gonorrhoeae'
            pseudomonas          : meta.organism == 'Pseudomonas_aeruginosa'
            vibrio_cholerae      : meta.organism == 'Vibrio_cholerae'
            vibrio_parahaemolyticus         : meta.organism == 'Vibrio_parahaemolyticus'
            other                : meta.organism == 'Other'
        }
        .set { organism_inputs }


    acinetobacter_input_files = organism_inputs.acinetobacter
    salmonella_input_files    = organism_inputs.salmonella
    escherichia_input_files   = organism_inputs.escherichia
    shigella_input_files      = organism_inputs.shigella
    lpneumophila_input_files  = organism_inputs.lpneumophila
    listeria_input_files      = organism_inputs.listeria
    kpneumoniae_input_files   = organism_inputs.kpneumoniae
    hinfluenzae_input_files   = organism_inputs.hinfluenzae
    saureus_input_files       = organism_inputs.saureus
    sdysgalactiae_input_files = organism_inputs.sdysgalactiae
    spyogenes_input_files     = organism_inputs.spyogenes
    spneumoniae_input_files   = organism_inputs.spneumoniae
    nmeningitidis_input_files = organism_inputs.nmeningitidis
    ngonorrhoeae_input_files  = organism_inputs.ngonorrhoeae
    pseudomonas_input_files   = organism_inputs.pseudomonas
    vibrio_cholerae_input_files  = organism_inputs.vibrio_cholerae
    vibrio_parahaemolyticus_input_files  = organism_inputs.vibrio_parahaemolyticus

    emit:
    acinetobacter_input_files                  // channel: [ val(meta), [reads], assembly ]
    escherichia_input_files                    // channel: [ val(meta), [reads], assembly ]
    hinfluenzae_input_files                    // channel: [ val(meta), [reads], assembly ]
    kpneumoniae_input_files                    // channel: [ val(meta), [reads], assembly ]
    listeria_input_files                       // channel: [ val(meta), [reads], assembly ]
    lpneumophila_input_files                   // channel: [ val(meta), [reads], assembly ]
    ngonorrhoeae_input_files                   // channel: [ val(meta), [reads], assembly ]
    nmeningitidis_input_files                  // channel: [ val(meta), [reads], assembly ]
    pseudomonas_input_files                    // channel: [ val(meta), [reads], assembly ]
    salmonella_input_files                     // channel: [ val(meta), [reads], assembly ]
    saureus_input_files                        // channel: [ val(meta), [reads], assembly ]
    shigella_input_files                       // channel: [ val(meta), [reads], assembly ]
    spneumoniae_input_files                    // channel: [ val(meta), [reads], assembly ]
    sdysgalactiae_input_files                  // channel: [ val(meta), [reads], assembly ]
    spyogenes_input_files                      // channel: [ val(meta), [reads], assembly ]
    vibrio_cholerae_input_files                // channel: [ val(meta), [reads], assembly ]
    vibrio_parahaemolyticus_input_files        // channel: [ val(meta), [reads], assembly ]
    all_input_files = input_files              // channel: [ val(meta), [reads], assembly ]
    versions = SAMPLESHEET_CHECK.out.versions  // channel: [ versions.yml ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
