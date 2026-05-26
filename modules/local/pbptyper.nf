process PBPTYPER {
    tag "${meta.id}"
    label 'process_medium'

    container "quay.io/biocontainers/pbptyper:2.0.0--hdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_pbptyper_tblastn.tsv")   , emit: blastn
    tuple val(meta), path("*_pbptyper_output.tsv")    , emit: tsv
    tuple val(meta), path("*_pbptyper_summary.tsv")   , emit: summary
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    
    """
    pbptyper \\
        ${args} \\
        --input $assembly \\
        --prefix $prefix \\
        --outdir . 
    
    mv ${prefix}.tblastn.tsv ${prefix}_pbptyper_tblastn.tsv
    mv ${prefix}.tsv ${prefix}_pbptyper_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "pbptyper", "pbptype", \$2
    }
    ' "${prefix}_pbptyper_output.tsv" > "${prefix}_pbptyper_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbptyper: \$( echo \$( pbptyper --version 2>&1) | sed 's/^.* //' )
    END_VERSIONS
    """
}
