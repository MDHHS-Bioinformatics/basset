process ARIBA {
    tag "$meta.id"
    label 'process_low'

    container "quay.io/biocontainers/ariba@sha256:1781fbf0ecd087f19627d604940aee4aa40158ce586ac2483815137424196bd7"
    // ariba:2.14.7--py310h5140242_0

    input:
    tuple val(meta), path(reads), path(assembly)
    path database

    output:
    tuple val(meta), path("${prefix}_ariba_output.tsv")           , emit: tsv
    tuple val(meta), path("${prefix}_ariba_summary.tsv")          , emit: summary
    path "versions.yml"                                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"

    def input_command
    if (meta.layout == 'paired_end'){
            input_command = "${reads[0]} ${reads[1]}"  // Paired-end reads
    } else {
        error "ERROR: Sample ${meta.id} does not have valid paired reads required by ARIBA!"
    }

    """
    export MPLCONFIGDIR=\$PWD/.matplotlib

    ariba \\
        run \\
        ${database} \\
        ${input_command} \\
        ${prefix} \\
        ${args} \\
        --threads ${task.cpus}
    
    mv ${prefix}/report.tsv ${prefix}_ariba_output.tsv

    # Generating BaSSeT summary file 
    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS="\t" }
    NR == 2 {
        print prefix, organism, "ariba", "ctxA", \$1
        print prefix, organism, "ariba", "ctxB", \$1
        print prefix, organism, "ariba", "rstR", \$1
        print prefix, organism, "ariba", "tcpA", \$1
    }
    ' "${prefix}_ariba_output.tsv" > "${prefix}_ariba_summary.tsv"

    awk -F'\t' -v prefix="${prefix}" -v organism="${organism}" '
    BEGIN { OFS = "\t"
        # List of marker genes you want to check
        markers["ctxA"] = 1
        markers["ctxB"] = 1
        markers["rstR"] = 1
        markers["tcpA"] = 1
    }
    NR > 1 {
        # Store detections from column 1
        gsub(/_.*/, "", \$1) 
        detected[\$1] = 1
    }
    END {
        for (m in markers) {
            status = (m in detected ? "+" : "-")
            print prefix, organism, "ariba", m, status
        }
    }
    ' "${prefix}_ariba_output.tsv" > "${prefix}_ariba_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ariba: "\$(ariba version 2>/dev/null  | grep -m1 'ARIBA version' | sed 's/[^0-9.]//g')"
    END_VERSIONS
    """
}
