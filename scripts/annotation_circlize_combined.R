# =============================================================================
# Script: annotation_circlize_combined.R
#
# Input files:
#   results/TE_annotation/EDTA/ERR11437324_Altai-5.fa.mod.EDTA.TEanno.gff3
#   results/TE_annotation/LTR_full_length/TElib_LTR.fa.rexdb-plant.cls.tsv
#   data/assemblies/ERR11437324_Altai-5.fa.fai
#
# Match Athila and CRM family names from TEsorter to EDTA annotations.
# Select the 20 longest scaffolds.
# Plot Gypsy, Athila, CRM, Copia, Helitron, 5S SINE, Mutator and CACTA.
#
# Output:
#   plots/TE_density/05-TE_density_combined.pdf
# =============================================================================

library(circlize)
library(tidyverse)
library(data.table)
library(ComplexHeatmap)
library(grid)

# Project directory.
WORKDIR <- "/data/users/srais/genome_annotation_course"

# Input files.
gff_file <- file.path(WORKDIR, "results/TE_annotation/EDTA", "ERR11437324_Altai-5.fa.mod.EDTA.TEanno.gff3")
cls_file <- file.path(WORKDIR, "results/TE_annotation/LTR_full_length", "TElib_LTR.fa.rexdb-plant.cls.tsv")
fai_file <- file.path(WORKDIR, "data/assemblies/ERR11437324_Altai-5.fa.fai")

# New output file: previous PDFs are preserved.
outdir <- file.path(WORKDIR, "plots/TE_density")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

out_pdf <- file.path(outdir, "05-TE_density_combined.pdf")

# Check that the input files are available.
stopifnot(file.exists(gff_file), file.exists(cls_file), file.exists(fai_file))


# Read the genomic TE annotations.
gff <- read.table(gff_file, header = FALSE, sep = "\t", comment.char = "#", quote = "", stringsAsFactors = FALSE)

# Exclude structural subfeatures and extract family names.
gff <- gff %>%
    filter(!V3 %in% c("long_terminal_repeat", "repeat_region", "target_site_duplication")) %>%
    mutate(Name = str_match(V9, "(?:^|;)Name=([^;]+)")[, 2])

# Read the TEsorter classification table.
cls <- as.data.frame(fread(cls_file))
names(cls)[1] <- "TE"

# Identify Athila and CRM families.
target_clades <- cls %>%
    filter(Clade %in% c("Athila", "CRM")) %>%
    mutate(Name = sub("#.*$", "", TE)) %>%
    select(Name, Clade) %>%
    distinct()

# Check that each family has only one clade assignment.
if (anyDuplicated(target_clades$Name)) {stop("Some TE families have multiple clade assignments.")}

# Match classified families to their genomic positions.
clade_annotations <- gff %>%
    inner_join(target_clades, by = "Name")

message("Library families per clade:")
print(table(target_clades$Clade))

message("Matched genomic annotations per clade:")
print(table(clade_annotations$Clade))



# Select the 20 longest scaffolds.
fai <- read.table(fai_file, header = FALSE, stringsAsFactors = FALSE)

custom_ideogram <- fai %>%
    transmute(chr = V1, start = 0, end = V2) %>%
    arrange(desc(end)) %>%
    slice_head(n = 20)

# Prepare positions for one TE group.
superfamily_track <- function(feature_name) 
    {gff %>%
        filter(V3 == feature_name, V1 %in% custom_ideogram$chr) %>%
        transmute(chrom = V1, start = V4, end = V5) %>%
        as.data.frame()
    }

# Prepare positions for one clade.
clade_track <- function(clade_name)
    {clade_annotations %>%
        filter(Clade == clade_name, V1 %in% custom_ideogram$chr) %>%
        transmute(chrom = V1, start = V4, end = V5) %>%
        as.data.frame()
    }

# Track order: outside to inside.
tracks <- list(
    Gypsy = superfamily_track("Gypsy_LTR_retrotransposon"),
    Athila = clade_track("Athila"),
    CRM = clade_track("CRM"),
    Copia = superfamily_track("Copia_LTR_retrotransposon"),
    Helitron = superfamily_track("helitron"),
    `5S SINE` = superfamily_track("5S_SINE_retrotransposon"),
    Mutator = superfamily_track("Mutator_TIR_transposon"),
    CACTA = superfamily_track("CACTA_TIR_transposon")
)

# Display the number of annotations on the selected scaffolds.
print(vapply(tracks, nrow, integer(1)))

# Stop if a track has no annotations.
empty_tracks <- names(tracks)[vapply(tracks, nrow, integer(1)) == 0]

if (length(empty_tracks) > 0) {stop(paste("Empty tracks:", paste(empty_tracks, collapse = ", ")))}


# Colors follow the track order, from outside to inside.
track_colors <- c(
    Gypsy = "#F02020",
    Athila = "#009640",
    CRM = "#FF7800",
    Copia = "#8200D6",
    Helitron = "#C99A00",
    `5S SINE` = "#0055F5",
    Mutator = "#F0008B",
    CACTA = "#00856A"
)

# Open the combined PDF without replacing the previous plots.
pdf(out_pdf, width = 12, height = 12)
circos.clear()
gaps <- c(rep(1.5, nrow(custom_ideogram) - 1), 6)
circos.par(start.degree = 90, gap.after = gaps, track.margin = c(0.002, 0.002))

# Display scaffold names and genomic coordinates.
circos.genomicInitialize(custom_ideogram, labels.cex = 0.65, axis.labels.cex = 0.3)

# Draw the eight density tracks, from outside to inside.
for (track_name in names(tracks)) {circos.genomicDensity(tracks[[track_name]], count_by = "number", window.size = 1e5, col = track_colors[[track_name]], track.height = 0.08)}

# Place the legend in the empty center of the circle.
lgd <- Legend(
    title = "Tracks: outside to inside", at = names(tracks), legend_gp = gpar(fill = unname(track_colors[names(tracks)])), labels_gp = gpar(fontsize = 11), title_gp = gpar(fontsize = 11, fontface = "bold"))

draw(lgd, x = unit(0.5, "npc"), y = unit(0.5, "npc"), just = c("center", "center"))

circos.clear()
dev.off()

message("PDF saved to: ", out_pdf)