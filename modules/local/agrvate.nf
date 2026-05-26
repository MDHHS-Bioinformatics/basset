process AGRVATE {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/agrvate:1.0.2--hdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_agrvate_output.tsv")        , emit: results
    tuple val(meta), path("${meta.id}_agrvate_agr_gp.tab")        , emit: tab
    tuple val(meta), path("${meta.id}_agrvate_summary.tsv")       , emit: summary
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    
    def input_command
    def fasta = null
    def is_compressed = false
    def fasta_name = null
    if (meta.has_assembly) {
        fasta = assembly[0]
        is_compressed = fasta.getName().endsWith('.gz')
        fasta_name = fasta.getName().replace('.gz', '')
        input_command = "--input ${fasta_name}"
    // If no assembly, fail
    }  else {
        error "ERROR: Sample ${meta.id} does not have assembly required by AGRVate!"
    }
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    agrvate \\
        ${args} \\
        $input_command

    mv *-results/*-agr_gp.tab ${prefix}_agrvate_agr_gp.tab
    mv *-results/*-summary.tab ${prefix}_agrvate_output.tsv

    # Make BaSSeT summary
    awk -F'\t' -v sample="${prefix}" -v organism="${organism}" '
    NR==1 {
        for(i=1;i<=NF;i++) col[\$i]=i
    }
    NR==2 {
        print sample "\t" organism "\tagrvate\tagr_group\t" \$2
    }
    ' ${prefix}_agrvate_output.tsv > ${prefix}_agrvate_summary.tsv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        agrvate: \$(echo \$(agrvate --version 2>&1)  | sed 's/[^0-9.]//g')
    END_VERSIONS
    """
}
