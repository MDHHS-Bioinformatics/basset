process PASTY {
    tag "${meta.id}"
    label 'process_medium'

    container "quay.io/biocontainers/pasty@sha256:2176d371c9061e8ad52bbac90b3eca5f1b79888d9fc59a6f7df845ba92c1c841"
    // "quay.io/biocontainers/pasty:2.2.1--hdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.blastn.tsv")                    , emit: blastn
    tuple val(meta), path("*.details.tsv*")                  , emit: details
    tuple val(meta), path("${meta.id}_pasty_output.tsv*")    , emit: tsv
    tuple val(meta), path("${meta.id}_pasty_summary.tsv*")   , emit: summary
    path "versions.yml"                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    
    """
    pasty \\
        ${args} \\
        --input $assembly \\
        --prefix ${prefix} \\
        --outdir pasty 

    for f in pasty/${prefix}*; do
        b=\$(basename "\$f")
        mv "\$f" "\${b/#${prefix}/${prefix}_pasty}"
    done

    mv ${prefix}_pasty.tsv ${prefix}_pasty_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "pasty", "serotype", \$2
    }
    ' "${prefix}_pasty_output.tsv" > "${prefix}_pasty_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    \$(pasty --version 2>&1 | awk -F', version ' '
    {
        gsub(/ /,"_",\$1)
        if (\$1 == "schema_pasty")
            \$1 = "pasty"
        print "    " \$1 ": " \$2
    }')
    END_VERSIONS
    """
}
