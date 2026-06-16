/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowBasset.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

// Get BaSSeT version
def basset_version = workflow.manifest.version

// Function to make master channel
def get_master() {
    def master = "${params.master_path}"
    return new File(master).exists() ? file(master) : [] }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { ABRICATE                                   } from '../modules/local/abricate'
include { AGRVATE                                    } from '../modules/local/agrvate'
include { ARIBA                                      } from '../modules/local/ariba'
include { ECTYPER                                    } from '../modules/local/ectyper'
include { EL_GATO                                    } from '../modules/local/el_gato'
include { EMMTYPER as EMMTYPER_SPYOGENES             } from '../modules/local/emmtyper'
include { EMMTYPER as EMMTYPER_SDYSGALACTIAE         } from '../modules/local/emmtyper'
include { HICAP                                      } from '../modules/local/hicap'
include { KAPTIVE_ABAUMANNII                         } from '../modules/local/kaptive_abaumannii'
include { KAPTIVE_VCHOLERAE                          } from '../modules/local/kaptive_vcholerae'
include { KAPTIVE_VPARAH                             } from '../modules/local/kaptive_vparah'
include { KLEBORATE                                  } from '../modules/local/kleborate'
include { LP_ABRICATE                                } from '../modules/local/lp_abricate'
include { LISSERO                                    } from '../modules/local/lissero'
include { MENINGOTYPE                                } from '../modules/local/meningotype'
include { NGMASTER                                   } from '../modules/local/ngmaster'
include { PASTY                                      } from '../modules/local/pasty'
include { PBPTYPER                                   } from '../modules/local/pbptyper'
include { SCCMEC                                     } from '../modules/local/sccmec'
include { SEQSERO2                                   } from '../modules/local/seqsero2'
include { SEROBA                                     } from '../modules/local/seroba'
include { SHIGATYPER                                 } from '../modules/local/shigatyper'
include { SHIGEIFINDER                               } from '../modules/local/shigeifinder'
include { SISTR                                      } from '../modules/local/sistr'
include { SPATYPER                                   } from '../modules/local/spatyper'
include { BASSET_SUMMARY                             } from '../modules/local/basset_summary'
include { BASSET_MASTER                              } from '../modules/local/basset_master'

// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK             } from '../subworkflows/local/input_check'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS  } from '../modules/nf-core/custom/dumpsoftwareversions/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow BASSET {

    ch_versions = Channel.empty()
    ch_summaries = Channel.empty()
    
    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Virulence factor identification with ABRicate
    //
    if (params.abricate_db) {
    ABRICATE(
        INPUT_CHECK.out.all_input_files
    )
    ch_versions = ch_versions.mix(ABRICATE.out.versions.first())
    }

    //
    // MODULE: Staphylococcus aureus Agr typing
    //
    AGRVATE(
        INPUT_CHECK.out.saureus_input_files
    )
    ch_versions = ch_versions.mix(AGRVATE.out.versions.first())

    //
    // MODULE: Vibrio cholerae virulence factor identification
    //
    ch_ariba_reads = INPUT_CHECK.out.shigella_input_files
        .filter { meta, reads_files, assembly_files ->
            meta.layout in ['paired_end']
    }

    ARIBA(
        ch_ariba_reads,
        params.vibrio_cholerae_vf_db
    )
    ch_summaries = ch_summaries.mix(ARIBA.out.summary)
    ch_versions = ch_versions.mix(ARIBA.out.versions.first())

    //
    // MODULE: Escherichia coli serotyping with ECTyper
    //
    ECTYPER(
        INPUT_CHECK.out.escherichia_input_files,
        params.ecoli_pathotypes
    )
    ch_summaries = ch_summaries.mix(ECTYPER.out.summary)
    ch_versions = ch_versions.mix(ECTYPER.out.versions.first())

    //
    // MODULE: Legionella pneumophila SBT with el_gato
    //
    EL_GATO(
        INPUT_CHECK.out.lpneumophila_input_files
    )
    ch_summaries = ch_summaries.mix(EL_GATO.out.summary)
    ch_versions = ch_versions.mix(EL_GATO.out.versions.first())

    //
    // MODULE: Streptococcus pyogenes emm-typing
    //
    EMMTYPER_SPYOGENES(
        INPUT_CHECK.out.spyogenes_input_files
    )
    ch_summaries = ch_summaries.mix(EMMTYPER_SPYOGENES.out.summary)
    ch_versions = ch_versions.mix(EMMTYPER_SPYOGENES.out.versions.first())

    EMMTYPER_SDYSGALACTIAE(
        INPUT_CHECK.out.sdysgalactiae_input_files
    )
    ch_summaries = ch_summaries.mix(EMMTYPER_SDYSGALACTIAE.out.summary)
    ch_versions = ch_versions.mix(EMMTYPER_SDYSGALACTIAE.out.versions.first())

    //
    // MODULE: Identify cap locus serotype and structure of Haemophilus influenzae assemblies
    //
    HICAP(
        INPUT_CHECK.out.hinfluenzae_input_files
    )
    ch_summaries = ch_summaries.mix(HICAP.out.summary)
    ch_versions = ch_versions.mix(HICAP.out.versions.first())

    //
    // MODULE: Acinetobacter baumannii serotyping (K and OC antigens)
    //
    KAPTIVE_ABAUMANNII(
        INPUT_CHECK.out.acinetobacter_input_files
    )
    ch_summaries = ch_summaries.mix(KAPTIVE_ABAUMANNII.out.summary)
    ch_versions = ch_versions.mix(KAPTIVE_ABAUMANNII.out.versions.first())

    //
    // MODULE: Vibrio cholerae serotyping (O antigen)
    //
    KAPTIVE_VCHOLERAE(
        INPUT_CHECK.out.vibrio_cholerae_input_files,
        file(params.vibrio_cholerae_o_db),
        file(params.vibrio_cholerae_o_logic)
    )
    ch_summaries = ch_summaries.mix(KAPTIVE_VCHOLERAE.out.summary)
    ch_versions = ch_versions.mix(KAPTIVE_VCHOLERAE.out.versions.first())
    
    //
    // MODULE: Vibrio parahaemolyticus serotyping (K and O antigens)
    //
    KAPTIVE_VPARAH(
        INPUT_CHECK.out.vibrio_parahaemolyticus_input_files,
        file(params.vibriopara_k_db),
        file(params.vibriopara_o_db)
    )
    ch_summaries = ch_summaries.mix(KAPTIVE_VPARAH.out.summary)
    ch_versions = ch_versions.mix(KAPTIVE_VPARAH.out.versions.first())


    //
    // MODULE: Klebsiella pneumoniae species complex (KpSC) virulence genes and serotype prediction
    //
    KLEBORATE(
        INPUT_CHECK.out.kpneumoniae_input_files
    )
    ch_summaries = ch_summaries.mix(KLEBORATE.out.summary)
    ch_versions = ch_versions.mix(KLEBORATE.out.versions.first())

    //
    // MODULE: In silico serogroup typing prediction for Listeria monocytogenes
    //
    LISSERO(
        INPUT_CHECK.out.listeria_input_files
    )
    ch_summaries = ch_summaries.mix(LISSERO.out.summary)
    ch_versions = ch_versions.mix(LISSERO.out.versions.first())

    //
    // MODULE: In silico serogroup typing prediction and subspecies for Legionella pneumophila
    //
    LP_ABRICATE(
        INPUT_CHECK.out.lpneumophila_input_files,
        file(params.legionella_pneumophila_db)
    )
    ch_summaries = ch_summaries.mix(LP_ABRICATE.out.summary)
    ch_versions = ch_versions.mix(LP_ABRICATE.out.versions.first())

    //
    // MODULE: In silico typing of Neisseria meningitidis contigs
    //
    MENINGOTYPE(
        INPUT_CHECK.out.nmeningitidis_input_files
    )
    ch_summaries = ch_summaries.mix(MENINGOTYPE.out.summary)
    ch_versions = ch_versions.mix(MENINGOTYPE.out.versions.first())

    //
    // MODULE: Multi-antigen sequence typing for Neisseria gonorrhoeae (NG-MAST) and Neisseria gonorrhoeae sequence typing for antimicrobial resistance (NG-STAR).
    //
    NGMASTER(
        INPUT_CHECK.out.ngonorrhoeae_input_files
    )
    ch_summaries = ch_summaries.mix(NGMASTER.out.summary)
    ch_versions = ch_versions.mix(NGMASTER.out.versions.first())

    //
    // MODULE: Pseudomonas aeruginosa serotyping
    //
    PASTY(
        INPUT_CHECK.out.pseudomonas_input_files
    )
    ch_summaries = ch_summaries.mix(PASTY.out.summary)
    ch_versions = ch_versions.mix(PASTY.out.versions.first())

    //
    // MODULE: Penicillin Binding Protein (PBP) of Streptococcus pneumoniae
    //
    PBPTYPER(
        INPUT_CHECK.out.spneumoniae_input_files
    )
    ch_summaries = ch_summaries.mix(PBPTYPER.out.summary)
    ch_versions = ch_versions.mix(PBPTYPER.out.versions.first())

    //
    // MODULE: Staphylococcus aureus SCCmec cassettes typing 
    //
    SCCMEC(
        INPUT_CHECK.out.saureus_input_files
    )
    ch_summaries = ch_summaries.mix(SCCMEC.out.summary)
    ch_versions = ch_versions.mix(SCCMEC.out.versions.first())

    // MODULE: Salmonella serotyping with SeqSero2
    //
    SEQSERO2(
        INPUT_CHECK.out.salmonella_input_files
    )
    ch_summaries = ch_summaries.mix(SEQSERO2.out.summary)
    ch_versions = ch_versions.mix(SEQSERO2.out.versions.first())
  
    // MODULE: Streptococcus pneumoniae serotyping
    //
    ch_seroba_reads = INPUT_CHECK.out.shigella_input_files
        .filter { meta, reads_files, assembly_files ->
            meta.layout in ['paired_end']
    }

    SEROBA(
        ch_seroba_reads
    )
    ch_summaries = ch_summaries.mix(SEROBA.out.summary)
    ch_versions = ch_versions.mix(SEROBA.out.versions.first())

    //
    // MODULE: Shigella serotyping
    //
    ch_shigatyper_reads = INPUT_CHECK.out.shigella_input_files
        .filter { meta, reads_files, assembly_files ->
            meta.layout in ['single_end', 'paired_end']
    }

    SHIGATYPER(
       ch_shigatyper_reads
    )
    ch_summaries = ch_summaries.mix(SHIGATYPER.out.summary)
    ch_versions = ch_versions.mix(SHIGATYPER.out.versions.first())

    //
    // MODULE: Shigella serotyping and EIEC differenciation
    //
    SHIGEIFINDER(
        INPUT_CHECK.out.shigella_input_files
    )
    ch_summaries = ch_summaries.mix(SHIGEIFINDER.out.summary)
    ch_versions = ch_versions.mix(SHIGEIFINDER.out.versions.first())

    //
    // MODULE: Salmonella In Silico Typing Resource (SISTR)
    //
    SISTR(
        INPUT_CHECK.out.salmonella_input_files
    )
    ch_summaries = ch_summaries.mix(SISTR.out.summary)
    ch_versions = ch_versions.mix(SISTR.out.versions.first())

    //
    // MODULE: Staphylococcus aureus spa typing
    //
    SPATYPER(
        INPUT_CHECK.out.saureus_input_files,
        file(params.spatyper_repeats),
        file(params.spatyper_reporder)
    )
    ch_summaries = ch_summaries.mix(SPATYPER.out.summary)
    ch_versions = ch_versions.mix(SPATYPER.out.versions.first())

    //
    // MODULE: Summary table
    //
    ch_tool_versions = ch_versions.unique().collectFile(name:'collated_versions.yml')

    BASSET_SUMMARY(
        ch_summaries.map { meta, file -> file }.collectFile(name:'batch_results.tsv'),
        ch_tool_versions,
        basset_version
    )
    ch_versions = ch_versions.mix(BASSET_SUMMARY.out.versions.first())

    //
    // MODULE: Append results to master file
    //
    if (params.master) {
    ch_master = get_master()

    BASSET_MASTER(
        BASSET_SUMMARY.out.tsv,
        ch_master
    )
    ch_versions = ch_versions.mix(BASSET_MASTER.out.versions.first())
    }

    //
    //MODULE: Get software versions
    //
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name:'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowBasset.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
