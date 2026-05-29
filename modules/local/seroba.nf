process SEROBA {
    tag "$meta.id"
    label 'process_low'

    container "sangerbentleygroup/seroba@sha256:f72ff38a051dde6bf3c755e3d5c96ba6e8f5e15c0dc967187065c72f7f1a0ff2"
    // "sangerbentleygroup/seroba:2.0.6"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_seroba_output.csv")     , emit: csv
    tuple val(meta), path("${meta.id}_seroba_summary.tsv")    , emit: summary
    path "versions.yml"                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    
    def input_command
    if (meta.layout == 'paired_end'){
            input_command = "${reads[0]} ${reads[1]}"  // Paired-end reads
    } else {
        error "ERROR: Sample ${meta.id} does not have valid paired reads required by SeroBA!"
    }

    """
    seroba \\
        runSerotyping \\
        /seroba/database \\
        $input_command \\
        $prefix $args

    # Renaming file
    mv ${prefix}/pred.csv ${prefix}_seroba_output.csv

    # Generating BaSSeT summary file 
    awk -F, -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "seroba", "serotype", \$2
        print prefix, organism, "seroba", "genetic_variant", \$3
    }
    ' "${prefix}_seroba_output.csv" > "${prefix}_seroba_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seroba: \$(seroba version)
    END_VERSIONS
    """
}
