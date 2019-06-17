# 使い方 Rを起動して
# >source("draw_fig6.R")

# 推奨：Docker版R/bioconductor環境で動かす
# 本スクリプトファイルがあるディレクトリで
# $ docker run -it -v $PWD:/mnt bioconductor/release_base2:R3.6.0_Bioc3.9 R
# >source("/mnt/draw_fig6.R")

# パッケージのインストール
# Bioconductor
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# phyloseq
if (!requireNamespace("phyloseq", quietly = TRUE)) {
  BiocManager::install("phyloseq", version = "3.9")
}
library("phyloseq")
library("ape")

# ggplot2
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
library("ggplot2")

# stringr
if (!requireNamespace("stringr", quietly = TRUE)) {
  install.packages("stringr")
}
library("stringr")

# phyloseqオブジェクトの作成
bim_fpath <- "/mnt/data/feature-table-w-taxonomy-w-md_NGSDRY.biom"
tre_fpath <- "/mnt/data/unrooted-tree.tre"
ps <- import_biom(bim_fpath, tre_fpath)

print(ps)
print(sample_data(ps))

# Taxonomy Tableの修正
print(head(tax_table(ps)))
colnames(tax_table(ps)) = c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")

tax_table(ps)[, "Domain"]  <- str_replace_all(tax_table(ps)[, "Domain"], pattern="D_[:digit:]__", replacement="")
tax_table(ps)[, "Phylum"]  <- str_replace_all(tax_table(ps)[, "Phylum"], pattern="D_[:digit:]__", replacement="")
tax_table(ps)[, "Class"]   <- str_replace_all(tax_table(ps)[, "Class"],  pattern="D_[:digit:]__", replacement="")
tax_table(ps)[, "Order"]   <- str_replace_all(tax_table(ps)[, "Order"],  pattern="D_[:digit:]__", replacement="")
tax_table(ps)[, "Family"]  <- str_replace_all(tax_table(ps)[, "Family"], pattern="D_[:digit:]__", replacement="")
tax_table(ps)[, "Genus"]   <- str_replace_all(tax_table(ps)[, "Genus"],  pattern="D_[:digit:]__", replacement="")
tax_table(ps)[, "Species"] <- str_replace_all(tax_table(ps)[, "Species"], pattern="D_[:digit:]__", replacement="")

print(head(tax_table(ps)))

# NAとChloroplast/MitochondriaのOTUをフィルター
ps0 <- subset_taxa(ps,!is.na(Phylum))
ps0 <- subset_taxa(ps0, Class != "Chloroplast")
ps0 <- subset_taxa(ps0, Family != "Mitochondria")
ps0 <- prune_taxa(taxa_sums(ps0) > 0, ps0)
print(ps0)

# Transform to even sampling depth.
# https://joey711.github.io/phyloseq/plot_ordination-examples.html
ps0evne <- transform_sample_counts(ps0, function(x) 1E6 * x / sum(x))
print(head(otu_table(ps0evne)))

# Figure 6a
# 無根系統樹からUniFrac距離を計算する際に毎回ランダムにrootのOTUが選択される
# 再現性確保のため論文でrootに使用したOTUをrootに指定
# 自分のデータで計算する際は以下の2行はコメントアウト
root <- "7597e5a1f9f330c2dd8c2f06edab12b0"
phy_tree(ps0evne) <- root(phy_tree(ps0evne), outgroup = root, resolve.root = T)

ps0evne.PUniW <- ordinate(ps0evne, "PCoA", "unifrac", weighted = TRUE)
p <-plot_ordination(ps0evne, ps0evne.PUniW, type = "samples", color = "Group")
p <- p + geom_point(size = 5, alpha = 0.75) +
  scale_colour_brewer(type = "qual", palette = "Set1") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5)) +
  ggtitle("PCoA on weighted-UniFrac distance")
ggsave(file = "/mnt/data/fig6-a.pdf", plot = p)

# Figure 6b
# 無根系統樹からUniFrac距離を計算する際に毎回ランダムにrootのOTUが選択される
# 再現性確保のため論文でrootに使用したOTUをrootに指定
# 自分のデータで計算する際は以下の2行はコメントアウト
root <- "f8363ab8e835b9d7d5fe97d1861eabfb"
phy_tree(ps0evne) <- root(phy_tree(ps0evne), outgroup = root, resolve.root = T)

ps0evne.PUniW <- phyloseq::distance(ps0evne, method = "wunifrac")
pdf("/mnt/data/fig6-b.pdf")
plot(as.phylo(hclust(ps0evne.PUniW, method = "complete")),
     show.tip.label = TRUE,
     use.edge.length = TRUE)
axisPhylo()
dev.off()

print("Finish!")