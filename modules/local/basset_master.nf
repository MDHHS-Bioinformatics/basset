process BASSET_MASTER {
    label 'process_single'

    conda "conda-forge::pandas=2.2.3"
    container 'quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'
    //'quay.io/biocontainers/pandas:2.2.1'
    
    input:
    path batch_summary
    path prior_master

    output:
    path "basset_summary_master.tsv", emit: master_summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def existing_master = prior_master ? "--existing_master ${prior_master}" : ""

    """
    basset_master.py \
        --run_summary $batch_summary \
        --out basset_summary_master.tsv $existing_master
        
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
