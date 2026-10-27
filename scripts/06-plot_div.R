library(reshape2)
# library(hrbrthemes)
library(tidyverse)
library(data.table)


# get data from parameter

WORKDIR <- "/data/users/srais/genome_annotation_course"

data <- file.path(WORKDIR, "results/TE_annotation/parseRM_results", "ERR11437324_Altai-5.fa.mod.EDTA.RM.nonzero.out.landscape.Div.Rname.tab")

outdir <- file.path(WORKDIR, "plots/TE_divergence")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

rep_table <- fread(data, skip = 1, header = TRUE, sep = "\t")

# Check for three identifier columns and 50 divergence bins.
stopifnot(ncol(rep_table) == 53)

rep_table %>% head()
# How does the data look like?

colnames(rep_table) <- c("Rname", "Rclass", "Rfam", 1:50)
rep_table <- rep_table %>% filter(Rfam != "unknown")
rep_table$fam <- paste(rep_table$Rclass, rep_table$Rfam, sep = "/")

table(rep_table$fam)

# How many elements are there in each Superfamily?
rep_table.m <- reshape2::melt(as.data.frame(rep_table), id.vars = c("Rname", "Rclass", "Rfam", "fam"), variable.name = "variable", value.name = "value")


# Arrange the data so that they are in the following order:
# LTR/Copia, LTR/Gypsy, all types of DNA transposons (TIR transposons), DNA/Helitron, all types of MITES
preferred_order <- c(
    "LTR/Copia", "LTR/Gypsy",
    "DNA/CMC-EnSpm", "DNA/DTC", "DNA/DTH", "DNA/DTM", "DNA/DTT",
    "DNA/hAT-Ac", "DNA/hAT-Tip100", "DNA/MULE-MuDR",
    "DNA/PIF-Harbinger", "DNA/TcMar-Pogo",
    "LINE/I-Jockey", "LINE/L1",
    "SINE/5S", "SINE?/SINE?",
    "MITE/DTH", "MITE/DTM", "MITE/DTT"
)

present <- unique(rep_table.m$fam)

rep_table.m$fam <- factor(
    rep_table.m$fam,
    levels = unique(c(preferred_order, sort(setdiff(present, preferred_order))))
)

# NOTE: Check that all the superfamilies in your dataset are included above

rep_table.m$distance <- (
    as.numeric(as.character(rep_table.m$variable)) - 0.5
) / 100 # as it is percent divergence

# Question:
# rep_table.m$age <- ??? # Calculate using the substitution rate and the formula provided in the tutorial


# options(scipen = 999)

# remove helitrons as EDTA is not able to annotate them properly (https://github.com/oushujun/EDTA/wiki/Making-sense-of-EDTA-usage-and-outputs---Q&A)
rep_table.m <- rep_table.m %>%
    filter(!fam %in% c("DNA/Helitron", "RC/Helitron"))

ggplot(rep_table.m, aes(fill = fam, x = distance, weight = value / 1000000)) +
  geom_bar() +
  cowplot::theme_cowplot() +
  scale_fill_viridis_d(option = "turbo") +
  xlab("Sequence divergence (proportion)") +
  ylab("Sequence (Mbp)") +
  labs(fill = "TE group") +
  theme(axis.text.x = element_text(angle = 90, vjust = 1, size = 9, hjust = 1), plot.title = element_text(hjust = 0.5))

ggsave(filename = file.path(outdir, "01_TE_divergence.pdf"), width = 10, height = 5, useDingbats = FALSE)



# Why is it important to have this plot in Mbp instead of counts?
# Hint:
# Consider a scenario where there is a lot of small fragments of TEs due to nested insertions and deletions.
# How would that affect the plot if you used counts instead of Mbp?
#
