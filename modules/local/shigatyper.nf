process SHIGATYPER {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/shigatyper:2.0.5--pyhdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${prefix}_shigatyper_output.tsv")      , emit: output
    tuple val(meta), path("${prefix}_shigatyper_hits.tsv")        , optional: true, emit: hits
    tuple val(meta), path("${prefix}_shigatyper_summary.tsv")     , emit: summary
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"

    def input_command
    if (meta.layout == 'single_end') {
        input_command = "--SE ${reads[0]}" + (params.ont ? " --ont" : "") // Single-end reads or ONT
    } else if (meta.layout == 'paired_end'){
            input_command = "--R1 ${reads[0]} --R2 ${reads[1]}"  // Paired-end reads
    } else {
        error "ERROR: Sample ${meta.id} does not have valid reads required by ShigaTyper!"
    }

    """
    shigatyper \\
        $args \\
        --name ${prefix} \\
        $input_command

    mv ${prefix}-hits.tsv ${prefix}_shigatyper_hits.tsv
    mv ${prefix}.tsv ${prefix}_shigatyper_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "shigatyper", "prediction", \$2
        print prefix, organism, "shigatyper", "ipaB", \$3
    }
    ' "${prefix}_shigatyper_output.tsv" > "${prefix}_shigatyper_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        shigatyper: \$(shigatyper --version | sed -n 's/ShigaTyper \\(.*\\)/\\1/p')
    END_VERSIONS
    """
}
