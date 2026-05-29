process SEQSERO2 {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/biocontainers/seqsero2@sha256:f21a1590fa916deab4418a232c3b1c4e8ade920effda82f8fca88b932fc0e769"
    // "quay.io/biocontainers/seqsero2:1.3.2--pyhdfd78af_0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*SeqSero_log.txt")     , emit: log
    tuple val(meta), path("*_result.tsv")         , emit: tsv
    tuple val(meta), path("*_result.txt")         , emit: txt
    tuple val(meta), path("*_summary.tsv")        , emit: summary
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    // Determine which input to use: prioritize reads, fallback to assembly if no reads
    def use_assembly = false
    def input_command
    if (meta.layout == 'single_end') {
        input_command = "-i ${reads[0]} -m k"   + (params.ont ? " -t 5" : " -t 3") // Single-end reads or nanopore
    } else if (meta.layout == 'paired_end'){
            input_command = "-i ${reads[0]} ${reads[1]} -m a -t 2"  // Paired-end reads
    } else if (meta.layout == 'assembly') {
        // If no reads, fallback to the assembly
        use_assembly = true
        fasta = assembly[0]
        is_compressed = fasta.getName().endsWith('.gz')
        fasta_name    = fasta.getName().replace('.gz', '')
        input_command = "-i ${fasta_name} -m k -t 4"  // Assembly (contigs)
    } else {
        error "ERROR: Sample ${meta.id} does not have valid reads or assembly required by SeqSero2!"
    }

    """
    if [ "${use_assembly}" = "true" ]; then
        if [ "${is_compressed}" = "true" ]; then
            gzip -dc ${fasta} > ${fasta_name}
        fi
    fi

    SeqSero2_package.py \\
        $args \\
        -d seqsero2/ \\
        -n ${prefix} \\
        -p $task.cpus \\
        $input_command
    
    # Rename with sample id
    for f in seqsero2/*; do
        base=\$(basename "\$f")
        mv "\$f" "seqsero2/${prefix}_\${base}"
    done
    
    mv seqsero2/* .

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "seqsero2", "identification", \$7
        print prefix, organism, "seqsero2", "antigenic_profile", \$8
        print prefix, organism, "seqsero2", "serotype", \$9
    }
    ' "${prefix}_SeqSero_result.tsv" > "${prefix}_seqsero2_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqsero2: \$( echo \$( SeqSero2_package.py --version 2>&1) | sed 's/^.*SeqSero2_package.py //' )
    END_VERSIONS
    """
}
