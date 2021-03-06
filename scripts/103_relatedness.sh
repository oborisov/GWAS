%%bash
# Checking relatedness using king http://people.virginia.edu/~wc9c/KING/manual.html
# make sure that family ids are not identical (e.g., "0" for all samples), if needed, change FIDs to IIDs
bfile=""
salloc --mem=16000M --time=5:00:00 --cpus-per-task=20 \
srun king -b ${bfile}.bed \
--kinship \
--prefix ${bfile} \
--cpus 20

%%bash
bfile=""
degree=3
# remove relatives
if [ $degree == 3 ]; then kinship=0.0442; fi
if [ $degree == 2 ]; then kinship=0.0884; fi
rm ${bfile}.related_excluded
plink --bfile ${bfile} \
--remove <(cat ${bfile}.kin0 | tail -n +2 | awk -v kinship=${kinship} '{if ($NF > kinship) print $0}' | \
while read l; do if [[ $(grep -wFf <(echo ${l} | awk '{print $1,$2}') ${bfile}.fam | awk '{print $6}') -eq 1 ]]; then \
echo ${l} | awk '{print $1,$2}' >> ${bfile}.related_excluded; echo ${l} | awk '{print $1,$2}'; \
else echo ${l} | awk '{print $3,$4}' >> ${bfile}.related_excluded; echo ${l} | awk '{print $3,$4}'; fi; done) \
--make-bed --out ${bfile}_norelated


############################################
%%bash
# call rate
bfile=""
plink --bfile ${bfile} \
--keep <(cat <(awk '{print $1,$2}' ${bfile}.kin0 | tail -n +2) <(awk '{print $3,$4}' ${bfile}.kin0 | tail -n +2) ) \
--missing --out ${bfile}_CR
cat ${bfile}_CR.imiss

%%bash
# script to update fids
bfile=""
awk '{print $1,$2,$2,$2}' ${bfile}.fam > ${bfile}_update_ids_temp
plink --bfile ${bfile} \
--update-ids ${bfile}_update_ids_temp \
--make-bed --out ${bfile}_updids
rm ${bfile}_update_ids_temp

