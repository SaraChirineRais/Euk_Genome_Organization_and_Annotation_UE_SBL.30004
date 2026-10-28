srun --partition=pibu_el8 \
--nodes=1 --ntasks=1 --cpus-per-task=4 \
--mem=32G --time=02:00:00 \
--account=class-sbl-30004-ws-2026 \
--reservation=class-sbl-30004-2026-10-21 \
--pty bash -l

#prepare a pusher sans les files qu'on veut pas
git add .

#enregistre comme les modifications fait sur mes scirpts du cluster " " donne aux changements
git commit -m "initial commit"

#pusher les info/modif
git push

#lier dossier git sur le cluster a mon repo sur le github: on a fait une fois avec aymeric, PLUS A FAIRE !!!!!!!!
git remote add "origin" git@github.com:SaraChirineRais/Euk_Genome_Organization_and_Annotation_UE_SBL.30004.git

#connaitre le nombre de gene maybe 
awk -F '\t' '$3 == "gene" {n++} END {print n+0}' \
/data/users/srais/genome_annotation_course/output/MAKER/assembly.all.maker.noseq.gff