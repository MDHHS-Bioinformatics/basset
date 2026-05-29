process ABRICATE {
    tag "${meta.id}"
    label 'process_medium'

    container "quay.io/biocontainers/abricate@sha256:56f97396771e638bd3d1660f32afcb34c111734956498dd3a4ed6dae40a1137d"
    // "quay.io/biocontainers/abricate:1.4.0--h05cac1d_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_abricate*.tsv")   , emit: tsv
    path "versions.yml"                                , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    prefix  = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"

    def fasta = null
    def is_compressed = false
    def fasta_name = null
    if (meta.has_assembly) {
        fasta = assembly[0]
        is_compressed = fasta.getName().endsWith('.gz')
        fasta_name = fasta.getName().replace('.gz', '')
    }  else {
        error "ERROR: Sample ${meta.id} does not have valid assembly required by ABRicate!"
    }

    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    abricate \\
        $fasta_name \\
        ${args} \\
        --db $params.abricate_db \\
        --threads ${task.cpus} \\
        > ${prefix}_abricate_${params.abricate_db}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$( echo \$( abricate --version 2>&1) | sed 's/^.* //' )
    END_VERSIONS
    """
}
