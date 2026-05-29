process EMMTYPER {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/staphb/emmtyper@sha256:544873e26de1753691f7765118cfc6295e18c46008a70968b251ad830ebf344a"
    // "quay.io/staphb/emmtyper:0.2.0-2505"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_emmtyper_output.tsv")       , emit: tsv
    tuple val(meta), path("*_emmtyper_summary.tsv")      , emit: summary
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
        error "ERROR: Sample ${meta.id} does not have valid assembly required by EmmTyper!"
    }
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    emmtyper \\
        $args \\
        $fasta_name \\
        > ${prefix}_emmtyper_output.tsv

    # Make BaSSeT summary
    awk -F'\t' -v sample="${prefix}" -v organism="${organism}" '
    NR==1 {
        print sample "\t" organism "\temmtyper\temm_type\t" \$3
        print sample "\t" organism "\temmtyper\temm_cluster\t" \$5
    }
    ' ${prefix}_emmtyper_output.tsv > ${prefix}_emmtyper_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        emmtyper: \$( echo \$(emmtyper --version 2>&1) | sed 's/^.*emmtyper v//' )
    END_VERSIONS
    """
}
