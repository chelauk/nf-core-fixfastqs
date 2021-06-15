#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

include { INPUT_CHECK  } from './subworkflows/local/input_check' addParams( options: [:] )
include { BBMAP_REPAIR } from './modules/local/bbmap/repair'     addParams(options: [:])

workflow {
    INPUT_CHECK(ch_input)
        .map {
        meta, fastq ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            [ meta, fastq ] }
    .groupTuple(by: [0])
    .branch {
        meta, fastq ->
            single  : fastq.size() == 1
                return [ meta, fastq.flatten() ]
            multiple: fastq.size() > 1
                return [ meta, fastq.flatten() ]
    }
    .set { ch_fastq }
    BBMAP_REPAIR(INPUT_CHECK.out)
}