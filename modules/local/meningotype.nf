process MENINGOTYPE {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/meningotype@sha256:db45c259335cc7ad549e7a965d32f85c8b1ebaa42034ae625463772d90cb7af2"
    // "quay.io/biocontainers/meningotype:0.8.6b--pyhdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_meningotype_output.tsv")    , emit: tsv
    tuple val(meta), path("*_meningotype_summary.tsv")   , emit: summary
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    
    def fasta = null
    def is_compressed = false
    if (meta.has_assembly) {
        fasta = assembly[0]
        is_compressed = fasta.getName().endsWith('.gz')
        fasta_name = fasta.getName().replace('.gz', '')
    } else {
        error "ERROR: Sample ${meta.id} does not have valid assembly required by MeningoType!"
    }
    
    // Run MeningoType and handle unsuccessful predictions
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -cd $fasta > $fasta_name
    fi

    # Execute MeningoType
    exit_code=0

    meningotype \\
        $args \\
        $fasta_name \\
        > ${prefix}_meningotype_output.tsv \\
        2> ${prefix}_meningotype.log || exit_code=\$?

    # Extract serogroup if the tool succeeded
    serogroup=""

    if [ "\$exit_code" -eq 0 ] && \
       [ -s "${prefix}_meningotype_output.tsv" ]; then

        serogroup=\$(awk -F '\t' \
            'NR==2 {print \$2}' \
            "${prefix}_meningotype_output.tsv")
    fi

    # Default to Untypeable if no prediction
    if [ -z "\$serogroup" ] || \
       [ "\$serogroup" == "NA" ] || \
       [ "\$serogroup" == "-" ]; then

        serogroup="Untypeable"
    fi

    # Generate BaSSeT summary
    printf '%s\t%s\tmeningotype\tserogroup\t%s\n' \
        "${prefix}" \
        "${organism}" \
        "\$serogroup" \
        > "${prefix}_meningotype_summary.tsv"

    # Generate versions.yml
    meningotype_version=\$(meningotype --version 2>&1 | sed 's/^.*meningotype //')

    printf '"%s":\n    meningotype: "%s"\n' \
        "${task.process}" \
        "\$meningotype_version" > versions.yml
    """
}
