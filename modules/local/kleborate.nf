process KLEBORATE {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/biocontainers/kleborate@sha256:51d5627fb1835f0e8600ef38dc1ed63c823cc0babe4e4f1e73e5f1a4722817cf"
    // "quay.io/biocontainers/kleborate:3.2.4--pyhdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${prefix}_kleborate_output.tsv") , emit: tsv
    tuple val(meta), path("${prefix}_kleborate_summary.tsv"), emit: summary
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    
    if (meta.has_assembly) {
        fasta = assembly[0]
    } else {
        error "ERROR: Sample ${meta.id} does not have valid assembly required by Kleborate!"
    }

    """
    kleborate \\
        $args \\
        --assemblies $fasta \\
        --outdir kleborate \\
        --preset kpsc \\
        --modules klebsiella_pneumo_complex__kaptive,klebsiella__ybst,klebsiella__cbst,klebsiella__abst,klebsiella__smst,klebsiella__rmst,klebsiella__rmpa2,klebsiella_pneumo_complex__virulence_score,klebsiella_pneumo_complex__wzi

    mv kleborate/klebsiella_pneumo_complex__kaptive_output.txt ${prefix}_kleborate_output.tsv

    # Make BaSSeT summary
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "kleborate", "k_locus", \$18
        print prefix, organism, "kleborate", "k_antigen", \$19
        print prefix, organism, "kleborate", "o_locus", \$26
        print prefix, organism, "kleborate", "o_antigen", \$27
    }
    ' "${prefix}_kleborate_output.tsv" > "${prefix}_kleborate_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kleborate: \$( echo \$(kleborate --version | sed 's/Kleborate v//;'))
    END_VERSIONS
    """
}
