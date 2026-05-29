process SCCMEC {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/sccmec@sha256:6b8f6b25bd125bbc9b5997fbea9a2a61c56659594af65c47c3790b34d4c34a76"
    // "quay.io/biocontainers/sccmec:1.2.0--hdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_sccmec_output.tsv")               , emit: tsv
    tuple val(meta), path("${meta.id}_sccmec_summary.tsv")              , emit: summary
    tuple val(meta), path("${meta.id}_sccmec.regions.blastn.tsv")       , emit: regions_blastn
    tuple val(meta), path("${meta.id}_sccmec.regions.details.tsv")      , emit: regions_details
    tuple val(meta), path("${meta.id}_sccmec.targets.blastn.tsv")       , emit: targets_blastn
    tuple val(meta), path("${meta.id}_sccmec.targets.details.tsv")      , emit: targets_details
    path "versions.yml"                                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    
    """
    sccmec --input $assembly $args \\
        --outdir sccmec \\
        --prefix ${prefix}
    
    for f in sccmec/${prefix}*; do
        b=\$(basename "\$f")
        mv "\$f" "\${b/#${prefix}/${prefix}_sccmec}"
    done

    mv ${prefix}_sccmec.tsv ${prefix}_sccmec_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "sccmec", "sccmectype", \$2
        print prefix, organism, "sccmec", "sccmecsubtype", \$3
        print prefix, organism, "sccmec", "mecA", \$4
    }
    ' "${prefix}_sccmec_output.tsv" > "${prefix}_sccmec_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    \$(sccmec --version 2>&1 | awk -F', version ' '
    {
        gsub(/ /,"_",\$1)
        print "    " \$1 ": " \$2

        if (\$1 == "schema_sccmec_targets")
            print "    sccmec: " \$2
    }')
    END_VERSIONS
    """
}
