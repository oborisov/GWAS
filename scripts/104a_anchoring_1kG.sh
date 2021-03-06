%%bash
# anchoring to 1kG
bfile=""

# extracting SNPs from 1000 Genomes
echo ${bfile} > ${bfile}_1kg_temp
for chr in {1..22}; do
plink --bfile /home/borisov/software/1000GP_Phase3/vcf/chr${chr} \
--extract <(awk '{print $2}' ${bfile}.bim) \
--make-bed --out ${bfile}_1kg_temp_chr${chr} > /dev/null 2>&1
echo ${bfile}_1kg_temp_chr${chr} >> ${bfile}_1kg_temp
done

# merging 1000 genomes and data
plink --merge-list ${bfile}_1kg_temp --out ${bfile}_1kg_temp
plink --bfile ${bfile} \
--exclude ${bfile}_1kg_temp.missnp \
--make-bed --out ${bfile}_filt
suffix=$(echo $bfile | sed 's/.*\///')
cat ${bfile}_1kg_temp | sed "s/${suffix}$/${suffix}_filt/" > ${bfile}_1kg_temp2
plink --merge-list ${bfile}_1kg_temp2 --out ${bfile}_1kg_temp

# filter geno 0.01
plink --bfile ${bfile}_1kg_temp --geno 0.01 --make-bed --out ${bfile}_1kg_temp_geno001

# performing pca with plink2
bfile=${bfile}_1kg_temp_geno001
plink --bfile ${bfile} \
--indep-pairwise 1000 50 0.2 \
--out ${bfile}_pruned
plink --bfile ${bfile} \
--extract <(cat ${bfile}_pruned.prune.in) \
--make-bed --out ${bfile}_pruned
salloc --mem=16000M --time=5:00:00 --cpus-per-task=20 \
srun plink2 --bfile ${bfile}_pruned --pca --out ${bfile}_eigen


%%R
### Visualizing
bfile=""
n_PC=4; bfile_population="EUR"

# library
library(ggrepel)

# sample, fam, eigenvec, eigenval
kg_sample_file="/home/borisov/software/1000GP_Phase3/1000GP_Phase3.sample"
kg_sample=fread(kg_sample_file)
fam=fread(paste0(bfile, ".fam"))
eigenvec=fread(paste0(bfile, "_1kg_temp_geno001_eigen.eigenvec"))
eigenval=fread(paste0(bfile, "_1kg_temp_geno001_eigen.eigenval"))

# Processing
eigenvec=merge(eigenvec, kg_sample, by.x="IID", by.y="sample", all.x=T)
eigenvec[is.na(population), population := "samples"]
eigenvec[is.na(group), group := "samples"]
PC_means=eigenvec[group != "samples"][,list(PC1_mean=mean(PC1), PC2_mean=mean(PC2), PC3_mean=mean(PC3),PC4_mean=mean(PC4), PC5_mean=mean(PC5), PC6_mean=mean(PC6), PC7_mean=mean(PC7),PC8_mean=mean(PC8), PC9_mean=mean(PC9),PC10_mean=mean(PC10)),by=group]
distances_dt=data.table(IID=eigenvec[group == "samples"]$IID, t(apply(eigenvec[group == "samples"][,3:(n_PC+2)], 1, function(person) { apply(PC_means[,2:(n_PC+1)],1, function(x) { dist(rbind(person,x))  })})))
colnames(distances_dt) = c("IID", PC_means$group)
distances_dt$PC_group = PC_means$group[apply(distances_dt[,2:6], 1, which.min)]

# Print outliers IDs to stdout
print(distances_dt[PC_group != bfile_population][,c(1,ncol(distances_dt)), with=F])
fwrite(eigenvec[IID %in% distances_dt[PC_group != bfile_population]$IID, c(2,1)], paste0(bfile, "_1kG.rm"), sep=" ", col.names=F, quote=F, na=NA)

# PCA plot. Highlight outliers IDs
print(ggplot(eigenvec, aes(x=PC1, y=PC2, color=group, label=IID)) +
geom_point() + geom_label_repel(data=eigenvec[IID %in% distances_dt[PC_group != bfile_population]$IID]))
ggsave(paste0(bfile, "_1kg_temp_geno001_eigen.eigenvec_pca.jpeg"))

# Eigenvalues
colnames(eigenval)="Eigenvalues"
eigenval$PC=factor(paste0("PC", 1:10), levels=paste0("PC", 1:10))
eigenval$PC_temp=as.integer(1:10)
eigenval[, perc_var_explained := round(eigenval[[1]]*100/sum(eigenval[[1]]),1)]

# Variance explained by PCs
print(eigenval[,c(2,1,4)])

# Scree plot
print(ggplot(eigenval, aes(x=PC, y=Eigenvalues)) +
geom_point() + geom_line(aes(x=PC_temp, y=Eigenvalues)) + theme_bw() +
ggtitle(paste0("PC1=", eigenval[1,4], "%; PC2=", eigenval[2,4], "%; PC3=", eigenval[3,4], "%; PC4=", eigenval[4,4], "%")))
ggsave(paste0(bfile, "_1kg_temp_geno001_eigen.eigenval_scree.jpeg"))

# remove temp files
system(paste0("rm ", bfile, "_1kg_temp_chr*"))
system(paste0("rm ", bfile, "_filt*"))


%%bash
bfile=""
plink --bfile ${bfile} \
--remove ${bfile}_1kG.rm \
--make-bed \
--out ${bfile}_1kG
