process HICAP {
    tag "$meta.id"
    label 'process_low'
    errorStrategy 'ignore'

    container "quay.io/biocontainers/hicap@sha256:c9d2d2bb63c1a869543217f79cd08c85989a8fac145f61b5402babbc4670764a"
    // "quay.io/biocontainers/hicap:1.0.4--pyhdfd78af_2"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.gbk")                 , emit: gbk, optional: true
    tuple val(meta), path("*.svg")                 , emit: svg, optional: true
    tuple val(meta), path("*.tsv")                 , emit: tsv, optional: true
    tuple val(meta), path("*_hicap_summary.tsv")   , emit: summary
    path "versions.yml"                 , emit: versions

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
        error "ERROR: Sample ${meta.id} does not have valid assembly required by hicap!"
    }
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    mkdir hicap
    
    hicap \\
        --query_fp $fasta_name \\
        $args \\
        --threads $task.cpus \\
        --output_dir hicap/
   
    # Rename with sample id
    for f in hicap/*; do
        base=\$(basename "\$f")
        mv "\$f" "hicap/${prefix}_hicap_\${base}"
    done

    mv hicap/*.gbk ${prefix}_hicap.gbk
    mv hicap/*.svg ${prefix}_hicap.svg
    mv hicap/*.tsv ${prefix}_hicap_output.tsv

    # Make BaSSeT summary
    awk -F'\t' -v sample="${prefix}" -v organism="${organism}" '
    NR==1 {
        for(i=1;i<=NF;i++) col[\$i]=i
    }
    NR==2 {
        print sample "\t" organism "\thicap\tserotype\t" \$col["predicted_serotype"]
    }
    ' ${prefix}_hicap_output.tsv > ${prefix}_hicap_summary.tsv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hicap: \$( echo \$( hicap --version 2>&1 ) | sed 's/^.*hicap //' )
    END_VERSIONS
    """
}