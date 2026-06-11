process EL_GATO {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/staphb/elgato@sha256:4841ee5642816725358e173ca91c01f6fb2eece5b3a82dca8e175081f52ccc40"
    // "quay.io/staphb/elgato:1.22.0"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_intermediate_outputs.txt")   , emit: txt
    tuple val(meta), path("*_possible_mlsts.txt")         , emit: sbt
    tuple val(meta), path("*_report.json")                , emit: json
    tuple val(meta), path("*_run.log")                    , emit: log
    tuple val(meta), path("*_summary.tsv")                , emit: summary
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"
    // Determine which input to use: prioritize reads, fallback to assembly if no reads
    def input_command
    def prep_command = ''

    if (meta.layout == 'paired_end') {
        input_command = "--read1 ${reads[0]} --read2 ${reads[1]}"
    } else if (meta.layout == 'assembly') {
        def fasta = assembly[0]
        def is_compressed = fasta.getName().endsWith('.gz')
        def fasta_name = fasta.getName().replaceFirst(/\.gz$/, '')

        if (is_compressed) {
            prep_command = "gzip -dc ${fasta} > ${fasta_name}"
            input_command = "--assembly ${fasta_name}"
        } else {
            input_command = "--assembly ${fasta}"
        }
    } else {
        error "ERROR: Sample ${meta.id} does not have paired-end reads or assembly required by el_gato!"
    }

    """
    ${prep_command}

    el_gato.py \\
        $args \\
        --out el_gato \\
        --overwrite \\
        --sample ${prefix} \\
        --header \\
        --threads $task.cpus \\
        $input_command
    
    # Rename with sample id
    for f in el_gato/*; do
        base=\$(basename "\$f")
        mv "\$f" "el_gato/${prefix}_elgato_\${base}"
    done
    
    # Make BaSSeT summary
    awk -F'\t' -v sample="${prefix}" -v organism="${organism}" '
    NR==1 {
        for(i=1;i<=NF;i++) col[\$i]=i
    }
    NR==2 {
        print sample "\t" organism "\tel_gato\tsbt\t" \$col["ST"]
    }
    ' el_gato/${prefix}_elgato_possible_mlsts.txt > el_gato/${prefix}_el_gato_summary.tsv

    mv el_gato/* .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        el_gato: \$( echo \$( el_gato.py --version 2>&1) | sed 's/^el_gato version: //' )
    END_VERSIONS
    """
}
