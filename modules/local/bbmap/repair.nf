// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process BBMAP_REPAIR {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }
    conda (params.enable_conda ? "bioconda::bbmap=38.90" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/bbmap:38.90--he522d1c_1"
    } else {
        container "quay.io/biocontainers/bbmap:38.90--he522d1c_1"
    }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.repair.R{1,2}.fastq.gz"), emit: fixed_fqs
    path "*.version.txt"                      , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    repair.sh \\
        repair.sh \\
        in=$reads[0] \\
        in2=$reads[1] \\
        out=${prefix}.repair.R1.fastq.gz \\
        out2=${prefix}.repair.R2.fastq.gz \\
        threads=$task.cpus 
    
    echo \$(bbversion.sh) > ${software}.version.txt
    """
    stub:
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    touch ${prefix}.repair.R1.fastq.gz
    touch ${prefix}.repair.R2.fastq.gz
    touch repair.stub.version.txt
    """
}
