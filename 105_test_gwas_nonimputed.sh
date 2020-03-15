%%bash
bfile=""
plink --bfile ${bfile} \
--covar ${bfile}_eigen.eigenvec \
--covar-name PC1, PC2, PC3, PC4 \
--logistic \
--out ${bfile}_test_4pc

%%R
bfile=""
lapply(c("qqman", "RColorBrewer"), require, character.only = TRUE)
pvec_4pc=fread(paste0(bfile, "_test_4pc", ".assoc.logistic"))
pvec_4pc=pvec_4pc[TEST=="ADD"]
print(pvec_4pc[order(P)][1:10])
# adjusting CHR and p
pvec_4pc[CHR == "X", CHR := 23]
pvec_4pc[, CHR := as.numeric(CHR)]
pvec_4pc=pvec_4pc[!is.na(pvec_4pc$P) & P > 0]
print("Lambda"); print(median(qchisq(1 - pvec_4pc[[9]], 1), na.rm=T) / qchisq(0.5, 1))
# producing Manhattan plot
print(manhattan(rbind(pvec_4pc[P<5e-2], pvec_4pc[P>5e-2][seq(1,nrow(pvec_4pc[P>5e-2]),10)]), chr="CHR", bp="BP", p="P", snp="SNP", annotatePval = 1, annotateTop = T, col=brewer.pal(8, "Dark2")))
# producing Q-Q plot
print(qq(pvec_4pc$P))
title(main = paste0("Lambda=", round(lambda,4)))


%%bash
# manual check of some SNPs
bfile=""
plink --bfile ${bfile} \
--extract <(echo rs4252209) \
--freq case-control --hardy \
--out ${bfile}_rs4252209
cat /home/borisov/nsCLP/LKG_2019_HEXMEX/LKG_2019_HEXMEX_checkedsex_geno02_mind02_geno002_mind002_norelated_pca_pca_pca_pca_pca_pca_rs4252209.hwe
cat /home/borisov/nsCLP/LKG_2019_HEXMEX/LKG_2019_HEXMEX_checkedsex_geno02_mind02_geno002_mind002_norelated_pca_pca_pca_pca_pca_pca_rs4252209.frq.cc
