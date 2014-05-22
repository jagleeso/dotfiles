#!/usr/bin/env Rscript
df <- read.delim(file="stdin", header=F, sep = " ")
write.table(summary(df[1]), stdout(), sep="\t", quote=F, col.names=F)
