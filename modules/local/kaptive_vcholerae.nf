process KAPTIVE_VCHOLERAE {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/staphb/kaptive@sha256:dbf67cd9a82269e03cd0b0dbeb7079112d9ae50557eed0c1edc6011b4cf007a8"
    // "quay.io/staphb/kaptive:3.2.1"
    
    input:
    tuple val(meta), path(reads), path(assembly)
    path vibrio_cholerae_o_db
    path vibrio_cholerae_o_logic
    
    output:
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
        $vibrio_cholerae_o_db \\
        $fasta \\
        $args \\
        --out ${prefix}_kaptive_o.tsv

    # Generating BaSSeT summary file
    awk -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }

    NR == 2 {
        print prefix, organism, "kaptive", "o_locus", \$2

        if (\$4 == "Typeable") {
            if (\$3 == "O1-Ogawa" || \$3 == "O1-Inaba")
                o_antigen = "O1"
            else if (\$3 == "O139")
                o_antigen = "O139"
            else
                o_antigen = "non-O1/non-O139"

            print prefix, organism, "kaptive", "o_antigen", o_antigen
        }
        else {
            print prefix, organism, "kaptive", "o_antigen", "-"
        }
    }
    ' "${prefix}_kaptive_o.tsv" >> "${prefix}_kaptive_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kaptive: \$( echo \$(kaptive --version | sed 's/Kaptive v//;'))
    END_VERSIONS
    """
}
