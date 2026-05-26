process SPATYPER {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/spatyper:0.3.3--pyhdfd78af_3"

    input:
    tuple val(meta), path(reads), path(assembly)
    path spatyper_repeats
    path spatyper_reporder

    output:
    tuple val(meta), path("*_spatyper_output.tsv")   , emit: tsv
    tuple val(meta), path("*_spatyper_summary.tsv")  , emit: summary
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    def input_args = spatyper_repeats && spatyper_reporder ? "-r ${spatyper_repeats} -o ${spatyper_reporder}" : ""
    if (meta.has_assembly) {
        fasta = assembly[0]
        is_compressed = fasta.getName().endsWith('.gz')
        fasta_name = fasta.getName().replace('.gz', '')
    } else {
        error "ERROR: Sample ${meta.id} does not have valid assembly required by SpaTyper!"
    }
    
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    spaTyper \\
        $args \\
        $input_args \\
        --fasta $fasta_name \\
        --output ${prefix}_spatyper_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "spaTyper", "spatype", \$3
    }
    ' "${prefix}_spatyper_output.tsv" > "${prefix}_spatyper_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatyper: \$( echo \$(spaTyper --version 2>&1) | sed 's/^.*spaTyper //' )
    END_VERSIONS
    """
}
