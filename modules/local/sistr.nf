process SISTR {
    tag "$meta.id"
    label 'process_medium'
    //errorStrategy 'ignore'

    container "quay.io/biocontainers/sistr_cmd@sha256:91619cb8daecadeeb457f56e38bd6e5ec980d76e521067eccf1355984bfd4171"
    // "quay.io/biocontainers/sistr_cmd:1.1.3--pyhdc42f0e_2"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_sistr_output.csv")         , emit: csv
    tuple val(meta), path("*_sistr_summary.tsv")        , emit: summary
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    organism = task.ext.organism ?: "${meta.organism}"

    def fasta = null
    def is_compressed = false
    def fasta_name = null
    if (meta.has_assembly) {
        fasta = assembly[0]
        is_compressed = fasta.getName().endsWith('.gz')
        fasta_name = fasta.getName().replace('.gz', '')
    }  else {
        error "ERROR: Sample ${meta.id} does not have valid assembly required by SISTR!"
    }
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $fasta > $fasta_name
    fi

    sistr \\
        --qc \\
        $args \\
        --threads $task.cpus \\
        --output-prediction ${prefix}_sistr_output \\
        --output-format csv \\
        --input-fasta-genome-name $fasta_name ${prefix}

    # Generating BaSSeT summary file 
    python3 - <<EOF > "${prefix}_sistr_summary.tsv"
import csv

prefix = "${prefix}"
organism = "${organism}"

with open("${prefix}_sistr_output.csv", newline="") as f:
    reader = csv.DictReader(f)
    row = next(reader)

print(f"{prefix}\\t{organism}\\tsistr\\tsubspecies\\t{row['cgmlst_subspecies']}")
print(f"{prefix}\\t{organism}\\tsistr\\tantigenic_profile\\t{row['antigenic_formula']}")
print(f"{prefix}\\t{organism}\\tsistr\\tserotype\\t{row['serovar_cgmlst']}")
print(f"{prefix}\\t{organism}\\tsistr\\tqc_status\\t{row['qc_status']}")
EOF

    cat > versions.yml <<END_VERSIONS
"${task.process}":
    sistr: \$(echo \$(sistr --version 2>&1) | sed 's/^.*sistr_cmd //; s/ .*\$//' )
END_VERSIONS
    """
}
