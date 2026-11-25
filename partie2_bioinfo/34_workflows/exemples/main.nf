// main.nf — même logique que l'exemple Snakemake : STAR puis featureCounts
params.reads = "data/raw/*_R{1,2}.fastq.gz"
params.index = "index/"
params.gtf   = "annotation.gtf"

process ALIGN {
    input:
    // fromFilePairs émet (identifiant, [R1, R2]) : une valeur et une LISTE de fichiers
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}_Aligned.sortedByCoord.out.bam")

    script:
    """
    STAR --genomeDir ${params.index} --readFilesIn ${reads[0]} ${reads[1]} \
         --readFilesCommand zcat --outSAMtype BAM SortedByCoordinate \
         --runThreadN ${task.cpus} --outFileNamePrefix ${sample_id}_
    """

    stub:   // utilisé par `nextflow run main.nf -stub-run` : teste le workflow sans STAR
    """
    touch ${sample_id}_Aligned.sortedByCoord.out.bam
    """
}

process COUNT {
    input:
    tuple val(sample_id), path(bam)

    output:
    path("${sample_id}.counts.txt")

    script:
    """
    featureCounts -p --countReadPairs -a ${params.gtf} -o ${sample_id}.counts.txt ${bam}
    """

    stub:
    """
    echo "${sample_id}" > ${sample_id}.counts.txt
    """
}

workflow {
    samples_ch = Channel.fromFilePairs(params.reads, checkIfExists: true)
    ALIGN(samples_ch) | COUNT
}
