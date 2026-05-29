process LISSERO {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/lissero@sha256:7f98157516187944a503985e8a307f666207b4e3c2969abe5235b2b328fad007"
    // "quay.io/biocontainers/lissero:0.4.10--pyhdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_lissero_output.tsv")   , emit: tsv
    tuple val(meta), path("*_lissero_summary.tsv")  , emit: summary
    path "versions.yml"                             , emit: versions

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
        error "ERROR: Sample ${meta.id} does not have valid assembly required by LisSero!"
    }

    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    lissero \\
        $args \\
        $fasta_name \\
        > ${prefix}_lissero_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "lissero", "serotype", \$2
    }
    ' "${prefix}_lissero_output.tsv" > "${prefix}_lissero_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lissero: \$( echo \$(lissero --version 2>&1) | sed 's/^.*LisSero //' )
    END_VERSIONS
    """
}
