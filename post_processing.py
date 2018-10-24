#!/usr/bin/env python
#-*- coding: utf-8 -*-

import subprocess
import argparse
import json
import os
import re

def getopts():
    parser = argparse.ArgumentParser(description='Get argument for BAM post processing pipeline')
    parser.add_argument('-i', '--bam',           type=str, nargs='+', required=True, metavar='<BAM>',    help='[Required]: Input BAM')
    parser.add_argument('-o', '--output',        type=str, default='.',              metavar='<PATH>',   help='[Optional]: Output directory path')
    parser.add_argument('-p', '--process',       type=int, default=4,                metavar='<THREAD>', help='[Optional]: Use at most N cores in parallel')
    parser.add_argument(      '--tool.samtools', type=str,                           metavar='<PATH>',   help='[Optional]: Samtools path')
    parser.add_argument(      '--tool.picard',   type=str,                           metavar='<PATH>',   help='[Optional]: PICARD path')
    parser.add_argument(      '--tool.gatk',     type=str,                           metavar='<PATH>',   help='[Optional]: GATK path')
    parser.add_argument(      '--tool.java',     type=str,                           metavar='<PATH>',   help='[Optional]: JAVA v1.8 path')
    parser.add_argument(      '--db.ref_fa',     type=str,                           metavar='<PATH>',   help='[Optional]: Build v38 reference fasta and bwa indexed path')
    parser.add_argument(      '--db.dbsnp',      type=str,                           metavar='<PATH>',   help='[Optional]: dbSNP v138 path')
    parser.add_argument(      '--db.mills',      type=str,                           metavar='<PATH>',   help='[Optional]: Mills and 1000g golden standard indel vcf path')

    argv = parser.parse_args()

    return argv

def setParams(argv):
    tools_dir = '/tools'
    db_dir    = '/db'

    if not os.path.exists(tools_dir):
        raise Exception('toolbox의 tools가 마운트 되지 않았습니다. 시스템팀에 문의 해주세요')
    if not os.path.exists(db_dir):
        raise Exception('toolbox의 db가 마운트 되지 않았습니다. 시스템팀에 문의 해주세요')

    tools_dict = {
        'tool.samtools': {'path': os.path.join(tools_dir, 'Bio-tools', 'samtools-1.1', 'samtools'),             'name': 'samtools v1.1'},
        'tool.picard'  : {'path': os.path.join(tools_dir, 'Bio-tools', 'picard', 'build', 'libs', 'picard.jar'),        'name': 'picard 2.17'},
        'tool.gatk'    : {'path': os.path.join(tools_dir, 'Bio-tools', 'gatk', 'gatk-package-4.0.0.0-local.jar'),       'name': 'gatk 4.0.0.0'},
        'tool.java'    : {'path': os.path.join(tools_dir, 'utils', 'jdk1.8.0_101', 'bin', 'java'),              'name': 'java 1.8.0_101'},
        'db.ref_fa'    : {'path': os.path.join(db_dir, 'ref', 'bwa_index', 'hs38DH.fa'),                    'name': 'Build 38 reference fasta'},
        'db.mills'     : {'path': os.path.join(db_dir, 'ref', 'bwa_index', 'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz'), 'name': 'Mills and 1000g golden standard indel vcf'},
        'db.dbsnp'     : {'path': os.path.join(db_dir, 'ref', 'bwa_index', 'dbsnp_138.hg38.vcf.gz'),                'name': 'dbSNP v138 vcf'},
    }

    for k, v in filter(lambda x: x[0] != 'bam' and x[0] != 'output' and x[0] != 'process', argv.__dict__.items()):
        if v != None:
            tools_dict[k].update({'path': check_path(v, tools_dict[k]['name'])})

    return tools_dict
        
def check_path(path, name):
    if not os.path.exists(path):
        raise Exception('%s 이 없습니다. 시스템팀에 문의 주세요'%(name))
    else:
        return os.path.abspath(path)

def check_input_path(in_list):
    out_list = []
    for s in in_list:
        if not os.path.exists(s):
            raise argparse.ArgumentTypeError('%s 파일이 존재하지 않습니다. 확인해주세요'%(s))
        else:
            out_list.append(os.path.abspath(s))

    return out_list

def get_output_sample_name_list(in_list):
    sample_list = []
    ex_dict     = {}

    for path in in_list:
        if re.search('(\S+)\.[b|s]am', path):
            match  = re.search('(\S+)\.[b|s]am', os.path.basename(path))
            sample = match.group(1)
            if sample not in ex_dict.keys():
                ex_dict[sample] = 0
                sample_list.append(sample)

    if len(in_list) == len(sample_list):
        return sample_list
    else:
        raise Exception('bam 파일의 정보가 겹치는 것이 있습니다. 확인해주세요(%s)'%(' '.join(ex_dict.keys())))

if __name__ == '__main__':
    argv = getopts()
    in_list      = check_input_path(argv.bam)
    tools_dict   = setParams(argv)
    samples_list = get_output_sample_name_list(argv.bam)

    config_dict = {
        'sample' : samples_list,
        'output' : os.path.abspath(argv.output),
        'tools'  : tools_dict,
        'process': argv.process,
        'input'  : dict(map(lambda x: (samples_list[x[0]], in_list[x[0]]), enumerate(in_list)))
    }

    json_str = json.dumps(config_dict)
    os.environ['CONFIG_JSON'] = json_str
    print(json_str)
    src_dir = os.path.dirname(os.path.abspath(__file__))

    cmd  = '/bin/bash '
    cmd += '-c '
    cmd += '%s '%(os.path.join(src_dir, 'run.sh'))

    subprocess.call(cmd, shell=True)

