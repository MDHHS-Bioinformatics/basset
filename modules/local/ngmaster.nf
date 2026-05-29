process NGMASTER {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/ngmaster@sha256:e915dc192be212ab7f9813b937a3ad0c7afd2f32e7f7d7a58326a1fe91b1899c"
    // "quay.io/biocontainers/ngmaster:2.0.0--pyhdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_ngmaster_output.tsv")  , emit: tsv
    tuple val(meta), path("*_ngmaster_summary.tsv") , emit: summary
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
        error "ERROR: Sample ${meta.id} does not have valid assembly required by NGMASTER!"
    }
    
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    ngmaster \\
        $args \\
        $fasta_name \\
        > ${prefix}_ngmaster_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "ngmaster", "ng-mast/ng-star", \$3
    }
    ' "${prefix}_ngmaster_output.tsv" > "${prefix}_ngmaster_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ngmaster: \$(ngmaster --version 2>&1 | sed -n '2p')
        ngmast_db: \$(ngmaster --version 2>&1 | tail -1 | sed -n 's/.*ngmast_\\([0-9-]*\\).*/\\1/p')
        ngstar_db: \$(ngmaster --version 2>&1 | tail -1 | sed -n 's/.*ngstar_\\([0-9-]*\\).*/\\1/p')
    END_VERSIONS
    """
}
