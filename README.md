# BAM Post-Processing Workflow

Mapping 프로그램으로 생성한 SAM / BAM 파일을 가지고 BAM 파일의 Post processing이 가능한 workflow입니다.
GATK 4.0.0.0 Best Practicing 과정을 기반으로 해당 workflow을 구성했습니다.
해당 과정은 Sorting -> Mark Duplications -> BQSR (Base Quality Score Recalibration) -> Apply BAM 의 순서로 진행이 됩니다.
따로 주석 처리를 하지 않았으니 해당 README를 읽어 보시고 문의 사항이 있으시면 시스템 팀으로 문의해주시길 바랍니다.

# GATK Best Practices 참고 자료
- [GATK Best Practices](https://software.broadinstitute.org/gatk/best-practices/)
- [GATK Best Practices Parameter](https://github.com/gatk-workflows/five-dollar-genome-analysis-pipeline)

# 요구 사항
### 프로그램
- python 2.6.6
- java 1.0.8 101
- gatk 4.0.0.0
- samtools 1.1
- picard 2.17
### 워크플로우 미들웨어
- miniconda 3
- python 3.5
- snakemake >= 3.12.0
### Reference DB
- Build 38 reference fasta
- Build 38 dbSNP v138 VCF
- Build 38 Mills and 1000G Golden Standard InDel VCF

# 프로그램 주의 사항
해당 정보들은 시스템 팀의 Toolbox에 모두 적용되어 있습니다. 
청주 서버에서 실행시에는 /tools /db 폴더가 마운트 되어 있는지 체크 하시길 바랍니다. (스크립트에서 체크하기는 합니다.)
마운트가 안되었거나, 대전 서버에서 실행하고 싶으시면 시스템팀에 문의 부탁드립니다.

# Usage
	Usage:
		./post_processing.py <parameters>

	Requried parameters:
		-i | --bam <BAM> [<BAM> ...] : 분석하고 싶은 BAM 파일의 위치 정보 여러개를 입력 가능하다.

	Optional parameters:
		-o | --output <PATH>    : 결과들이 저장이 되는 디렉토리의 위치 정보 (default: 현재 돌리는 위치 정보)
		-p | --process <THREAD> : 여러가지 BAM 파일을 넣었을때, 몇개의 BAM 파일을 Parallel 하게 돌릴 것인지 결정하는 정보 
                                  현재 JAVA에서 16G 사용하도록 세팅 되었기 때문에 서버에 따라서 다르게 세팅하시길 바랍니다.
                                  (default: 4)
		--tool.samtools <PATH>   : samtools 프로그램의 위치 정보
		--tool.picard <PATH>     : picard 프로그램의 위치 정보
		--tool.gatk <PATH>       : gatk 프로그램의 위치 정보
		--tool.java <PATH>       : java 프로그램의 위치 정보
		--db.ref_fa <PATH>       : Mapping 할 시에 사용한 reference fasta 파일의 위치 정보
		--db.dbsnp <PATH>        : Mapping 할 시에 사용한 reference fasta 파일과 같은 버전의 dbSNP VCF 파일 위치
		--db.mills <PATH>        : Mapping 할 시에 사용한 reference fasta 파일과 같은 버전의 
		                           Mills and 1000G Golden standard InDel VCF 파일 위치

	Simple Usage:
		python post_process.py -i ../input/test.bam

# 스크립트 사용시 주의 사항
1. 입력하는 BAM 파일은 기본적으로 .[bam|sam] 앞의 있는 입력 정보를 표본의 정보로 인식합니다. 
그렇기 때문에 같은 이름으로 입력시에 오류를 출력하게 되어 있습니다. 그렇기 때문에 입력하는 BAM 파일의 파일 정보를 유니크하게 수정 부탁드립니다.
2. tool 이나 db로 시작하는 파라미터를 입력하지 않을 시에는 임의적으로 Toolbox에서 해당 정보를 찾아서 입력하게 되어 있습니다. 다른 위치에서 사용하시고 싶으신 분만 입력하시면 됩니다.
5. process 파라미터의 경우, 시스템의 스펙에 따라서 다르게 입력하셔야 합니다. 해당 부분에 대해서는 각 프로그램에서 16 Giga byte의 메모리를 사용하도록 세팅을 해놓은 상태이기 때문에, Computing node의 Memory에 따라서 16 Giga byte의 배수에 맞도록 세팅해주시면 됩니다.
3. Script 내에서 Toolbox가 mount 가 되어 있는지 확인합니다. mount 오류가 있을 경우 시스템팀에 문의 부탁드립니다.
4. run.sh 나 Snakefile 같은 경우에는 해당 Workflow을 돌리기 위한 보조 장치 입니다. 해당 부분에 대해서 궁금하신 점이 있으시면 시스템 팀으로 문의 부탁드립니다.
