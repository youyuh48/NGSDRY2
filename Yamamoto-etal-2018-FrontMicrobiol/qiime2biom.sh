#!/bin/bash

# Export .biom file including taxon assignments and sample metadata
# https://forum.qiime2.org/t/export-biom-file-including-taxon-assignments-and-sample-metadata/1847/5

# Input QIIME2 files
FEATAB=table.qza
TREE=unrooted-tree.qza
TAXON=taxonomy.qza
META=metadata.txt

# output dir
CONVDIR=biom
TREEOUT=unrooted-tree.tre

# conversion steps
# ----------------
# export files from Qiime
mkdir ${CONVDIR}
qiime tools export --input-path ${FEATAB} --output-path ${CONVDIR}
qiime tools export --input-path ${TREE} --output-path ${CONVDIR}
qiime tools export --input-path ${TAXON} --output-path ${CONVDIR}

mv ${CONVDIR}/tree.nwk ${CONVDIR}/${TREEOUT}

# modifying taxonomy file to match exported feature table
new_header='#OTUID	taxonomy	confidence'
sed -i.bak "1 s/^.*$/$new_header/" ${CONVDIR}/taxonomy.tsv

# adding taxonomy information to .biom file
biom add-metadata \
  -i ${CONVDIR}/feature-table.biom \
  -o ${CONVDIR}/feature-table-w-taxonomy.biom \
  --observation-metadata-fp ${CONVDIR}/taxonomy.tsv \
  --observation-header OTUID,taxonomy,confidence \
  --sc-separated taxonomy

# adding metadata to .biom file
biom add-metadata \
  -i ${CONVDIR}/feature-table-w-taxonomy.biom \
  -o ${CONVDIR}/feature-table-w-taxonomy-w-md.biom \
  --sample-metadata-fp ${META} \
  --observation-header OTUID,taxonomy,confidence

echo "Finish!"
