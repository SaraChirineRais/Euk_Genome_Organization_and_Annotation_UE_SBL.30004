library(tidyverse)
library(data.table)

# Read the TE library classification.
cls_file <- "/data/users/srais/genome_annotation_course/results/TE_annotation/LTR_full_length/TElib_LTR.fa.rexdb-plant.cls.tsv"

cls <- as.data.frame(fread(cls_file))
names(cls)[1] <- "TE"

# Keep Athila and CRM and extract their TE family names.
target_clades <- cls %>%
    filter(Clade %in% c("Athila", "CRM")) %>%
    mutate(Name = sub("#.*$", "", TE)) %>%
    select(Name, Clade) %>%
    distinct()

print(target_clades)
print(table(target_clades$Clade))

# Read the genomic TE annotations.
gff_file <- "/data/users/srais/genome_annotation_course/results/TE_annotation/EDTA/ERR11437324_Altai-5.fa.mod.EDTA.TEanno.gff3"

gff <- read.table(
    gff_file,
    header = FALSE,
    sep = "\t",
    comment.char = "#",
    quote = "",
    stringsAsFactors = FALSE
)

# Extract the family name and exclude structural subfeatures.
gff <- gff %>%
    filter(!V3 %in% c(
        "long_terminal_repeat",
        "repeat_region",
        "target_site_duplication"
    )) %>%
    mutate(
        Name = str_match(V9, "(?:^|;)Name=([^;]+)")[, 2]
    )

# Match Athila and CRM family names to their genomic positions.
clade_annotations <- gff %>%
    inner_join(target_clades, by = "Name") %>%
    transmute(
        chrom = V1,
        start = V4,
        end = V5,
        Name,
        Clade
    )

print(head(clade_annotations))
print(table(clade_annotations$Clade))

library(circlize)
library(ComplexHeatmap)
library(grid)

# Read scaffold lengths.
fai_file <- "/data/users/srais/genome_annotation_course/data/assemblies/ERR11437324_Altai-5.fa.fai"

fai <- read.table(fai_file, header = FALSE, stringsAsFactors = FALSE)

# Select the 20 longest scaffolds.
custom_ideogram <- fai %>%
    transmute(chr = V1, start = 0, end = V2) %>%
    arrange(desc(end)) %>%
    slice_head(n = 20)

# Prepare one track per clade.
clade_track <- function(clade_name) {
    clade_annotations %>%
        filter(
            Clade == clade_name,
            chrom %in% custom_ideogram$chr
        ) %>%
        select(chrom, start, end) %>%
        as.data.frame()
}

# Check that both clades have positions to plot.
for (clade_name in c("Athila", "CRM")) {
    if (nrow(clade_track(clade_name)) == 0) {
        stop(paste("No annotations to plot for", clade_name))
    }
}

# Create the output directory and open the PDF.
outdir <- "/data/users/srais/genome_annotation_course/plots/TE_density"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

pdf(file.path(outdir, "04-TE_density_Athila_CRM.pdf"), width = 10, height = 10)

circos.clear()
gaps <- c(rep(1, nrow(custom_ideogram) - 1), 5)

circos.par(start.degree = 90, gap.after = gaps, track.margin = c(0, 0))

circos.genomicInitialize(custom_ideogram, labels.cex = 0.5, axis.labels.cex = 0.35)

# Outer track: Athila.
circos.genomicDensity(clade_track("Athila"), count_by = "number", col = "darkgreen", track.height = 0.12, window.size = 1e5)

# Inner track: CRM.
circos.genomicDensity(clade_track("CRM"),count_by = "number", col = "darkred", track.height = 0.12, window.size = 1e5)
circos.clear()

lgd <- Legend(
    title = "Clades (outside to inside)",
    at = c("Athila", "CRM"),
    legend_gp = gpar(fill = c("darkgreen", "darkred"))
)

draw(
    lgd,
    x = unit(0.5, "npc"),
    y = unit(0.5, "npc"),
    just = c("center", "center")
)

dev.off()