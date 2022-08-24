# QIIME2-02

## 変更履歴

- 2019/11/09
  - 公開
- 2022/08/24
  - SRA Toolkit の仕様が変更されたのでインストール方法を追記
  - SRA Toolkit の仕様が変更されたので解析用データのダウンロード手順を修正

## 解析準備

### 解析用のディレクトリの作成

```
$ mkdir ~/qiime2_excerise
```

### 16S rRNA遺伝子リファレンスデータベースのダウンロード

```
$ cd ~/Downloads/
$ ls -lh gg-13-8-99-nb-classifier.qza
$ mv gg-13-8-99-nb-classifier.qza ~/qiime2_excerise
$ cd ~/qiime2_excerise
$ ls
```

### 16S rRNA遺伝子リファレンスデータベースのダウンロード

```
$ cd ~/Downloads/
$ ls -lh gg-13-8-99-nb-classifier.qza
$ mkdir ~/qiime2_excerise
$ mv gg-13-8-99-nb-classifier.qza ~/qiime2_excerise
$ cd ~/qiime2_excerise
$ ls
```

### 解析用データのダウンロード

```
$ cd ~/qiime2_excerise
$ mv ~/Downloads/SRR_Acc_List.txt .
$ mv ~/Downloads/SraRunTable.txt .
$ cat SRR_Acc_List.txt
$ prefetch --option-file SRR_Acc_List.txt
$ mkdir fastq
$ cd fastq
$ cat ../SRR_Acc_List.txt | xargs -n1 fastq-dump --gzip --split-files
$ ls *
$ ls * | wc -l
$ rename 's/_1/_S1_L001_R1_001/' *.fastq.gz
$ rename 's/_2/_S1_L001_R2_001/' *.fastq.gz
$ ls
```

## 解析

### FASTQファイルのインポート

```
$ conda activate qiime2-2019.4
$ cd ~/qiime2_excerise

$ qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path fastq \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path demux.qza

$ qiime demux summarize \
--i-data demux.qza \
--o-visualization demux.qzv
```

### シーケンスQCとFeature tableの構築

```
# 使用可能なCPUコア数を確認
$ sysctl -n hw.logicalcpu_max
$ qiime dada2 denoise-paired \
--verbose \
--p-n-threads 0 \
--p-trim-left-f 17 \
--p-trim-left-r 21 \
--p-trunc-len-f 250 \
--p-trunc-len-r 250 \
--i-demultiplexed-seqs demux.qza \
--o-table table.qza \
--o-representative-sequences rep-seqs.qza \
--o-denoising-stats stats-dada2.qza

$ qiime metadata tabulate \
--m-input-file stats-dada2.qza \
--o-visualization stats-dada2.qzv
```

### Feature tableとFeatureDataの集計

```
$ qiime feature-table summarize \
--i-table table.qza \
--o-visualization table.qzv \
--m-sample-metadata-file metadata.txt

$ qiime feature-table tabulate-seqs \
--i-data rep-seqs.qza \
--o-visualization rep-seqs.qzv
```

### 分子系統樹の計算

```
$ qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences rep-seqs.qza \
--o-alignment aligned-rep-seqs.qza \
--o-masked-alignment masked-aligned-rep-seqs.qza \
--o-tree unrooted-tree.qza \
--o-rooted-tree rooted-tree.qza
```

### α多様性とβ多様性の解析

```
$ qiime diversity core-metrics-phylogenetic \
--i-phylogeny rooted-tree.qza \
--i-table table.qza \
--p-sampling-depth 28476 \
--m-metadata-file metadata.txt \
--output-dir core-metrics-results

$ qiime diversity alpha-group-significance \
 --i-alpha-diversity core-metrics-results/observed_otus_vector.qza \
 --m-metadata-file metadata.txt \
 --o-visualization core-metrics-results/observed_otus-group-significance.qzv

 $ qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/shannon_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization core-metrics-results/shannon-group-significance.qzv

  $ qiime diversity alpha-group-significance \
   --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
   --m-metadata-file metadata.txt \
   --o-visualization core-metrics-results/faith-pd-group-significance.qzv
```

```
$ qiime diversity beta-group-significance \
--i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
--m-metadata-file metadata.txt \
--m-metadata-column group \
--o-visualization core-metrics-results/unweighted-unifrac-group-significance.qzv \
--p-pairwise

$ qiime diversity beta-group-significance \
--i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza \
--m-metadata-file metadata.txt \
--m-metadata-column group \
--o-visualization core-metrics-results/weighted-unifrac-group-significance.qzv \
--p-pairwise
```

### α-レアファクションカーブの作図

```
$ qiime diversity alpha-rarefaction \
--i-table table.qza \
--i-phylogeny rooted-tree.qza \
--p-max-depth 65114 \
--m-metadata-file metadata.txt \
--o-visualization alpha-rarefaction.qzv
```

### 系統解析

```
# 使用可能なCPUコア数を確認
$ sysctl -n hw.logicalcpu_max
$ qiime feature-classifier classify-sklearn \
--p-n-jobs -1 \
--i-classifier gg-13-8-99-nb-classifier.qza \
--i-reads rep-seqs.qza \
--o-classification taxonomy.qza

$ qiime metadata tabulate \
--m-input-file taxonomy.qza \
--o-visualization taxonomy.qzv

$ qiime taxa barplot \
--i-table table.qza \
--i-taxonomy taxonomy.qza \
--m-metadata-file metadata.txt \
--o-visualization taxa-bar-plots.qzv
```

### ヒートマップの作図

```
$ qiime taxa collapse \
--i-table table.qza \
--i-taxonomy taxonomy.qza \
--p-level 6 \
--o-collapsed-table table-l6.qza

$ qiime feature-table heatmap \
--i-table table-l6.qza \
--m-metadata-file metadata.txt \
--m-metadata-column group \
--o-visualization heatmap_l6_group.qzv
```

### 変動菌種の検出

```
$ qiime composition add-pseudocount \
--i-table table-l6.qza \
--o-composition-table comp_table_l6.qza

$ qiime composition ancom \
--i-table comp_table_l6.qza \
--m-metadata-file metadata.txt \
--m-metadata-column group \
--o-visualization ancom_table_l6_group.qzv
```
