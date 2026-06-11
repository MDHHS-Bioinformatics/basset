process ECTYPER {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/biocontainers/ectyper@sha256:eb98dad0da8a8dbf8864ab724aa51bd59db1a5a80705cadb9c6e0a834ab4ba85"
    // "quay.io/biocontainers/ectyper:2.0.0--pyhdfd78af_4"

    input:
    tuple val(meta), path(reads), path(assembly)
    val ecoli_pathotypes

    output:
    tuple val(meta), path("*_ectyper.log")              , emit: log
    tuple val(meta), path("*_output.tsv")               , emit: tsv
    tuple val(meta), path("*_blastn_output_alleles.txt"), emit: txt
    tuple val(meta), path("*_summary.tsv")              , emit: summary
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"

    def input_command
    def prep_command = ''

    if (meta.has_assembly) {
        def fasta = assembly[0]
        def is_compressed = fasta.getName().endsWith('.gz')
        def fasta_name = fasta.getName().replaceFirst(/\.gz$/, '')

        if (is_compressed) {
            prep_command = "gzip -dc ${fasta} > ${fasta_name}"
            input_command = "--input ${fasta_name}"
        } else {
            input_command = "--input ${fasta}"
        }

    // If no assembly, fallback to the long reads
    } else if (meta.layout == 'single_end' && params.ont) {
        input_command = "--input ${reads[0]} --longreads"

    } else {
        error "ERROR: Sample ${meta.id} does not have valid longreads or assembly required by ECTyper!"
    }

    def pathotypes = ecoli_pathotypes ? "--pathotype" : ""

    """
    ${prep_command}

    ectyper \\
        $args \\
        --cores $task.cpus \\
        --output ectyper \\
        $input_command \\
        $pathotypes

    # Rename with sample id
    for f in ectyper/*; do
        base=\$(basename "\$f")
        mv "\$f" "ectyper/${prefix}_\${base}"
    done
    
    # Make BaSSeT summary
    awk -F'\t' -v sample="${prefix}" -v organism="${organism}" '
    NR==1 {
        for(i=1;i<=NF;i++) col[\$i]=i
    }
    NR==2 {
        print sample "\t" organism "\tectyper\to_antigen\t" \$col["O-type"]
        print sample "\t" organism "\tectyper\th_antigen\t" \$col["H-type"]
        print sample "\t" organism "\tectyper\tserotype\t" \$col["Serotype"]
    }
    ' ectyper/${prefix}_output.tsv > ectyper/${prefix}_ectyper_summary.tsv
    
    # Renaming files to include tool name
    mv ectyper/${prefix}_output.tsv ectyper/${prefix}_ectyper_output.tsv
    mv ectyper/${prefix}_blastn_output_alleles.txt ectyper/${prefix}_ectyper_blastn_output_alleles.txt
    mv ectyper/* .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ectyper: \$(echo \$(ectyper --version 2>&1)  | sed 's/.*ectyper //; s/ .*\$//')
    END_VERSIONS
    """
}
