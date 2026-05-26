process BASSET_SUMMARY {
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas:2.2.1'

    input:
    path summaries
    path tool_versions
    val basset_version

    output:
    path '*.tsv'       , emit: tsv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    basset_summary.py \\
       --summary $summaries \\
       --versions $tool_versions \\
       --pipeline_version $basset_version \\
       --out basset_summary_batch.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
