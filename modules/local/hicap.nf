process HICAP {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/hicap@sha256:c9d2d2bb63c1a869543217f79cd08c85989a8fac145f61b5402babbc4670764a"
    // "quay.io/biocontainers/hicap:1.0.4--pyhdfd78af_2"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*.gbk")                 , emit: gbk, optional: true
    tuple val(meta), path("*.svg")                 , emit: svg, optional: true
    tuple val(meta), path("*_hicap_output.tsv")    , emit: tsv, optional: true
    tuple val(meta), path("*_hicap_summary.tsv")   , emit: summary
    path "versions.yml"                            , emit: versions

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

    mkdir -p hicap

    exit_code=0

    hicap \\
        --query_fp $fasta_name \\
        $args \\
        --threads $task.cpus \\
        --output_dir hicap/ \\
        > ${prefix}_hicap.log 2>&1 || exit_code=\$?

    # Rename existing HICAP outputs
    for f in hicap/*; do
        [ -f "\$f" ] || continue

        base=\$(basename "\$f")
        mv "\$f" "hicap/${prefix}_hicap_\${base}"
    done

    # Collect files only if present
    for ext in gbk svg tsv; do
        files=(hicap/*.\$ext)

        if [ -f "\${files[0]}" ]; then
            if [ "\$ext" = "tsv" ]; then
                mv "\${files[0]}" \
                    "${prefix}_hicap_output.tsv"
            else
                mv "\${files[0]}" \
                    "${prefix}_hicap.\$ext"
            fi
        fi
    done

    # Default serotype
    serotype="Untypeable"

    if [ "\$exit_code" -eq 0 ] && \
       [ -s "${prefix}_hicap_output.tsv" ]; then

        predicted=\$(awk -F '\t' '
            NR==1 {
                for(i=1;i<=NF;i++) col[\$i]=i
            }
            NR==2 && ("predicted_serotype" in col) {
                print \$(col["predicted_serotype"])
            }
        ' "${prefix}_hicap_output.tsv")

        if [ -n "\$predicted" ] && \
           [ "\$predicted" != "NA" ] && \
           [ "\$predicted" != "-" ]; then
            serotype="\$predicted"
        fi
    fi

    printf '%s\t%s\thicap\tserotype\t%s\n' \
        "${prefix}" \
        "${organism}" \
        "\$serotype" \
        > "${prefix}_hicap_summary.tsv"
        
    # Generate versions.yml
    hicap_version=\$(hicap --version 2>&1 | sed 's/^.*hicap //')

    printf '"%s":\n    hicap: "%s"\n' \
        "${task.process}" \
        "\$hicap_version" > versions.yml
    """
}