import json
import os
from snakemake.io import Namedlist
from collections import OrderedDict

config = json.loads(os.environ['CONFIG_JSON'])

SAMPLE_LIST = config['sample']
OUTPUT_DIR  = config['output']
IN_DICT     = config['input']
TOOLS_DICT  = config['tools']

def get_input_bam(wildcards):
    in_dict = {
        'bam': IN_DICT[wildcards.sample]
    }
    
    return in_dict

def named_params(conf: dict):
    return \
        Namedlist(
            fromdict = dict(map(lambda k:
                                    (k, named_params(conf[k])) if type(conf[k]) in (dict, OrderedDict) else
                                    (k, conf[k])
                                ,conf
                            )
                        )
        )

rule all:
    input:
        bam = expand(os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl_recalib.bam'), sample=SAMPLE_LIST),
        bai = expand(os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl_recalib.bam.bai'), sample=SAMPLE_LIST)

rule sorting:
    input:
        unpack(get_input_bam)
    output:
        bam      = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted.bam')
    params:
        samtools = named_params(config['tools']['tool.samtools'])
    log:
        file     = os.path.join(OUTPUT_DIR, '{sample}', 'log', 'sorting.log')
    shell: '''
{params.samtools.path} sort {input.bam} -f {output.bam} &> {log.file}
'''

rule indexing:
    input:
        bam      = os.path.join(OUTPUT_DIR, '{sample}', 'bam', '{bam}.bam'),
    output:
        bai      = os.path.join(OUTPUT_DIR, '{sample}', 'bam', '{bam}.bam.bai'),
    params:
        samtools = named_params(config['tools']['tool.samtools'])
    log:
        file     = os.path.join(OUTPUT_DIR, '{sample}', 'log', '{bam}.indexing.log')
    shell: '''
{params.samtools.path} index {input.bam} &> {log.file}
'''

rule mark_duplicates:
    input:
        bam    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted.bam'),
        bai    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted.bam.bai'),
    output:
        bam    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl.bam'),
        met    = os.path.join(OUTPUT_DIR, '{sample}', 'qc',  'met'),
    params:
        java   = named_params(config['tools']['tool.java']),
        picard = named_params(config['tools']['tool.picard']),
    log:
        file   = os.path.join(OUTPUT_DIR, '{sample}', 'log', 'mark_duplicates.log'),
    shell: '''
{params.java.path} -Xms12G -Xmx16G -jar {params.picard.path} MarkDuplicates \
INPUT={input.bam} \
OUTPUT={output.bam} \
METRICS_FILE={output.met} \
OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 \
ASSUME_SORT_ORDER="coordinate" \
CREATE_MD5_FILE=true \
REMOVE_DUPLICATES=true \
&> {log.file}
'''

rule base_recalibrator:
    input:
        bam    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl.bam'),
        bai    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl.bam.bai'),
    output:
        bqsr   = os.path.join(OUTPUT_DIR, '{sample}', 'qc', 'recal_data.table'),
    params:
        java   = named_params(config['tools']['tool.java']),
        gatk   = named_params(config['tools']['tool.gatk']),
        ref_fa = named_params(config['tools']['db.ref_fa']),
        dbsnp  = named_params(config['tools']['db.dbsnp']),
        mills  = named_params(config['tools']['db.mills']),
    log:
        file   = os.path.join(OUTPUT_DIR, '{sample}', 'log', 'base_recalibrator.log'),
    shell: '''
{params.java.path} -Xms12G -Xmx16G -jar {params.gatk.path} \
BaseRecalibrator \
-I {input.bam} \
-R {params.ref_fa.path} \
--use-original-qualities \
--known-sites {params.mills.path} \
--known-sites {params.dbsnp.path} \
--output {output.bqsr} \
&> {log.file}
'''

rule applybqsr:
    input:
        bam    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl.bam'),
        bai    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl.bam.bai'),
        bqsr   = os.path.join(OUTPUT_DIR, '{sample}', 'qc', 'recal_data.table'),
    output:
        bam    = os.path.join(OUTPUT_DIR, '{sample}', 'bam', 'sorted_dupl_recalib.bam'),
    params:
        java   = named_params(config['tools']['tool.java']),
        gatk   = named_params(config['tools']['tool.gatk']),
        ref_fa = named_params(config['tools']['db.ref_fa']),
    log:
        file   = os.path.join(OUTPUT_DIR, '{sample}', 'log', 'applybqsr.log'),
    shell: '''
{params.java.path} -Xms12G -Xmx16G -jar {params.gatk.path} \
ApplyBQSR \
--create-output-bam-md5 \
--add-output-sam-program-record \
--use-original-qualities \
--static-quantized-quals 10 \
--static-quantized-quals 20 \
--static-quantized-quals 30 \
--input {input.bam} \
-R {params.ref_fa.path} \
-bqsr {input.bqsr} \
--output {output.bam} \
&> {log.file}
'''
