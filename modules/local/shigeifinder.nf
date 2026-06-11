process SHIGEIFINDER {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/biocontainers/shigeifinder@sha256:938e6d771ce71f87b625c0ff616d595d55b0b742fcffb89742b67aad81b57013"
    // "quay.io/biocontainers/shigeifinder:1.3.5--pyhdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_shigeifinder_output.tsv")     , emit: output
    tuple val(meta), path("${meta.id}_shigeifinder_summary.tsv")    , emit: summary
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"

    def input_command
    def prep_command = ''

    if (meta.has_assembly) {
        def fasta = assembly[0]
        def is_compressed = fasta.getName().endsWith('.gz')
        def fasta_name = fasta.getName().replaceFirst(/\.gz$/, '')

        if (is_compressed) {
            prep_command = "gzip -dc ${fasta} > ${fasta_name}"
            input_command = "-i ${fasta_name}"
        } else {
            input_command = "-i ${fasta}"
        }

    } else if (meta.layout == 'single_end') {
        input_command = "-i ${reads[0]} --single-end"

    } else if (meta.layout == 'paired_end') {
        input_command = "-i ${reads[0]} ${reads[1]}"

    } else {
        error "ERROR: Sample ${meta.id} does not have valid reads or assembly required by ShigEiFinder!"
    }

    """
    ${prep_command}

    shigeifinder \\
        $args \\
        $input_command \\
        -t $task.cpus \\
        --output ${prefix}_shigeifinder_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "shigeifinder", "ipaH", \$2
        print prefix, organism, "shigeifinder", "virulence_plasmid", \$3
        print prefix, organism, "shigeifinder", "cluster", \$4
        print prefix, organism, "shigeifinder", "serotype", \$5
        print prefix, organism, "shigeifinder", "o_antigen", \$6
        print prefix, organism, "shigeifinder", "h_antigen", \$7
    }
    ' "${prefix}_shigeifinder_output.tsv" > "${prefix}_shigeifinder_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        shigeifinder: \$( echo \$( shigeifinder --version 2>&1) | sed 's/^.*shigeifinder //' )
    END_VERSIONS
    """
}
