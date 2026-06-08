process LP_ABRICATE {
    tag "${meta.id}"
    label 'process_medium'

    container "quay.io/biocontainers/abricate@sha256:56f97396771e638bd3d1660f32afcb34c111734956498dd3a4ed6dae40a1137d"
    // "quay.io/biocontainers/abricate:1.4.0--h05cac1d_0"
    
    input:
    tuple val(meta), path(reads), path(assembly)
    path legionella_pneumophila_db

    output:
    tuple val(meta), path("${meta.id}_abricate_lp_serogroup.tsv")   , emit: serogroup
    tuple val(meta), path("${meta.id}_abricate_lp_subspecies.tsv")  , emit: subspecies
    tuple val(meta), path("${meta.id}_abricate_lp_summary.tsv")     , emit: summary
    path "versions.yml"                                          , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    prefix  = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"

    def fasta = null
    def is_compressed = false
    def fasta_name = null
    if (meta.has_assembly) {
        fasta = assembly[0]
        is_compressed = fasta.getName().endsWith('.gz')
        fasta_name = fasta.getName().replace('.gz', '')
    }  else {
        error "ERROR: Sample ${meta.id} does not have valid assembly required by ABRicate!"
    }

    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi


    abricate \\
        $fasta_name \\
        ${args} \\
        --datadir $legionella_pneumophila_db \\
        --db lp_serogroup \\
        --threads ${task.cpus} \\
        > ${prefix}_abricate_lp_serogroup.tsv

    abricate \\
        $fasta_name \\
        ${args} \\
        --datadir $legionella_pneumophila_db \\
        --db lp_subspecies \\
        --threads ${task.cpus} \\
        > ${prefix}_abricate_lp_subspecies.tsv

    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 1 { next }

    {
        coverage = \$10 + 0
        identity = \$11 + 0
        gene = \$6

        # extract serogroup number (after last underscore)
        match(gene, /_([0-9]+)\$/, arr)
        sg = arr[1]

        if (gene ~ /^wzt_/) {
            if (coverage > wzt_cov || (coverage == wzt_cov && identity > wzt_id)) {
                wzt_cov = coverage
                wzt_id = identity
                wzt_sg = sg
            }
        }

        if (gene ~ /^wzm_/) {
            if (coverage > wzm_cov || (coverage == wzm_cov && identity > wzm_id)) {
                wzm_cov = coverage
                wzm_id = identity
                wzm_sg = sg
            }
        }
    }

    END {
        if (wzt_sg != "")
            print prefix, organism, "abricate", "wzt_serogroup", wzt_sg

        if (wzm_sg != "")
            print prefix, organism, "abricate", "wzm_serogroup", wzm_sg

        if (wzt_sg != "" && wzm_sg != "" && wzt_sg == wzm_sg)
            final_sg = wzt_sg
        else
            final_sg = "unknown"

        print prefix, organism, "abricate", "serogroup", final_sg
    }
    ' "${prefix}_abricate_lp_serogroup.tsv" > "${prefix}_abricate_lp_summary.tsv"

    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 1 { next }
    {
        coverage = \$10 + 0
        identity = \$11 + 0

        if (coverage > best_coverage || (coverage == best_coverage && identity > best_identity)) {
            best_coverage = coverage
            best_identity = identity
            best_gene = \$6
        }
    }
    END {
        if (best_gene != "") {
            print prefix, organism, "abricate", "subspecies", best_gene
        }
    }
    ' "${prefix}_abricate_lp_subspecies.tsv" >> "${prefix}_abricate_lp_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$( echo \$( abricate --version 2>&1) | sed 's/^.* //' )
    END_VERSIONS
    """
}
