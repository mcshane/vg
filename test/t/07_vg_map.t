#!/usr/bin/env bash

BASH_TAP_ROOT=../bash-tap
. ../bash-tap/bash-tap-bootstrap

PATH=..:$PATH # for vg

plan tests 7

vg construct -r small/x.fa -v small/x.vcf.gz >x.vg
vg index -s -k 11 x.vg

is $(vg map -s CTACTGACAGCAGAAGTTTGCTGTGAAGATTAAATTAGGTGATGCTTG x.vg -J | tr ',' '\n' | grep node_id | grep "72\|74\|75\|77" | wc -l) 4 "global alignment traverses the correct path"

is $(vg map -s CTACTGACAGCAGAAGTTTGCTGTGAAGATTAAATTAGGTGATGCTTG x.vg -J | tr ',' '\n' | grep score | sed "s/}//g" | awk '{ print $2 }') 96 "alignment score is as expected"

vg map -s CTACTGACAGCAGAAGTTTGCTGTGAAGATTAAATTAGGTGATGCTTG -d x.vg.index >/dev/null
is $? 0 "vg map takes -d as input without a variant graph"

is $(vg map -s TCAGATTCTCATCCCTCCTCAAGGGCTTCTAACTACTCCACATCAAAGCTACCCAGGCCATTTTAAGTTTCCTGTGGACTAAGGACAAAGGTGCGGGGAG -J x.vg | grep to_length | grep '"sequence": "T"' | wc -l) 1 "vg map can align across a SNP"

is $(vg map -r <(vg sim -s 69 -n 1000 -l 100 x.vg) x.vg | vg view -a - | jq -c '.score == 200 // [.score, .sequence]' | grep -v true | wc -l) 0 "alignment works on a small graph"

seq=TCAGATTCTCATCCCTCCTCAAGGGCTTCTAACTACTCCACATCAAAGCTACCCAGGCCATTTTAAGTTTCCTGTGGACTAAGGACAAAGGTGCGGGGAG
is $(vg map -s $seq x.vg | vg view -a - | jq -c '[.score, .sequence, .path.node_id]' | md5sum | awk '{print $1}') \
   $(vg map -s $seq -J x.vg | jq -c '[.score, .sequence, .path.node_id]' | md5sum | awk '{print $1}') \
   "binary alignment format is equivalent to json version"

rm x.vg
rm -rf x.vg.index

vg construct -r minigiab/q.fa -v minigiab/NA12878.chr22.tiny.giab.vcf.gz >giab.vg
vg index -s -k 27 -e 7 giab.vg                                                   
is $(vg map -b minigiab/NA12878.chr22.tiny.bam giab.vg | vg view -a - | wc -l) $(samtools view minigiab/NA12878.chr22.tiny.bam | wc -l) "mapping of BAM file produces expected number of alignments"

rm giab.vg
rm -rf giab.vg.index
