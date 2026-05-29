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
    // Determine which input to use: prioritize reads, fallback to assembly if no reads
    def input_command
    if (meta.has_assembly) {
        // If no reads, fallback to the assembly
        input_command = "-i ${assembly}"  // Assembly (contigs)
    } else if (meta.layout == 'single_end') {
        input_command = "-i ${reads[0]} --single-end" // Single-end reads
    } else if (meta.layout == 'paired_end'){
            input_command = "-i ${reads[0]} ${reads[1]}"  // Paired-end reads
    } else {
        error "ERROR: Sample ${meta.id} does not have valid reads or assembly required by ShigEiFinder!"
    }

    """
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
