process KAPTIVE_VPARAH {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/staphb/kaptive@sha256:dbf67cd9a82269e03cd0b0dbeb7079112d9ae50557eed0c1edc6011b4cf007a8"
    // "quay.io/staphb/kaptive:3.2.1"
    
    input:
    tuple val(meta), path(reads), path(assembly)
    path vibriopara_k_db
    path vibriopara_o_db

    output:
    tuple val(meta), path("${meta.id}_kaptive_k.tsv")             , emit: k_antigen
    tuple val(meta), path("${meta.id}_kaptive_o.tsv")             , emit: o_antigen
    tuple val(meta), path("${meta.id}_kaptive_summary.tsv")       , emit: summary
    path "versions.yml"                                           , emit: versions

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
        error "ERROR: Sample ${meta.id} does not have valid assembly required by KAPTIVE!"
    }

    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    kaptive assembly \\
        $vibriopara_k_db \\
        $fasta_name \\
        $args \\
        --out ${prefix}_kaptive_k.tsv

    kaptive assembly \\
        $vibriopara_o_db \\
        $fasta_name \\
        $args \\
        --out ${prefix}_kaptive_o.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "kaptive", "k_locus", \$2
        if (\$4 == "Typeable")
            print prefix, organism, "kaptive", "k_antigen", \$3
        else
            print prefix, organism, "kaptive", "k_antigen", "-"
    }
    ' "${prefix}_kaptive_k.tsv" > "${prefix}_kaptive_summary.tsv"

    awk -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "kaptive", "o_locus", \$2
        if (\$4 == "Typeable")
            print prefix, organism, "kaptive", "o_antigen", \$3
        else
            print prefix, organism, "kaptive", "o_antigen", "-"
    }
    ' "${prefix}_kaptive_o.tsv" >> "${prefix}_kaptive_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaptive: \$( echo \$(kaptive --version | sed 's/Kaptive v//;'))
    END_VERSIONS
    """
}
