# Calculate the proportion of proteins with Pfam domains,
# overall and within low- and high-AED groups.

library(tidyverse)

WORKDIR <- "/data/users/srais/genome_annotation_course"
FINALDIR <- file.path(WORKDIR, "output/MAKER/final")

# Protein FASTA: identifiers and AED values.
protein_file <- file.path(FINALDIR, "assembly.all.maker.proteins.fasta.renamed.filtered.fasta")

# InterProScan TSV: detected protein domains.
ipr_file <- file.path(FINALDIR, "output.iprscan")

# Directory for summary tables.
outdir <- file.path(FINALDIR, "Pfam_by_AED")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# Check that both input files exist.
stopifnot(file.exists(protein_file), file.exists(ipr_file))


# Read FASTA headers containing protein IDs and AED values.
protein_lines <- readLines(protein_file, warn = FALSE)
headers <- protein_lines[str_starts(protein_lines, ">")]

# Extract one protein identifier and one AED value per header.
proteins <- tibble(
    Protein = str_match(headers, "^>(\\S+)")[, 2],
    AED = as.numeric(
        str_match(headers, "\\bAED:([0-9.]+)")[, 2]
    )
)

# Check that IDs are unique and AED values are valid.
stopifnot(
    nrow(proteins) > 0,
    !anyNA(proteins$Protein),
    !anyNA(proteins$AED),
    anyDuplicated(proteins$Protein) == 0,
    all(proteins$AED >= 0 & proteins$AED <= 1)
)

message("Number of proteins read: ", nrow(proteins))
print(head(proteins))

# Read InterProScan results.
# In its TSV format, column 1 contains the protein ID
# and column 4 identifies the analysis, such as Pfam.
ipr_lines <- readLines(ipr_file, warn = FALSE)
ipr_lines <- ipr_lines[nzchar(ipr_lines)]

ipr_fields <- str_split_fixed(ipr_lines, "\t", n = 5)

ipr <- tibble(Protein = ipr_fields[, 1], Analysis = ipr_fields[, 4])

# Keep each protein with a Pfam match only once.
pfam_proteins <- ipr %>%
    filter(Analysis == "Pfam") %>%
    distinct(Protein)

# Stop if no Pfam matches were found.
if (nrow(pfam_proteins) == 0) {stop("No Pfam matches found. Check the InterProScan input.")}

# Record whether each protein has at least one Pfam domain.
proteins <- proteins %>%
    mutate(Has_Pfam = Protein %in% pfam_proteins$Protein)

message("Retained proteins with at least one Pfam domain:")
print(table(proteins$Has_Pfam))


# Define AED groups for this comparison.
proteins <- proteins %>%
    mutate(AED_group = if_else(AED <= 0.5, "Low AED (<= 0.5)", "High AED (> 0.5)"))

# Summarize all retained proteins.
overall <- proteins %>%
    summarise(Group = "All retained proteins", Total_proteins = n(), Proteins_with_Pfam = sum(Has_Pfam), Percent_with_Pfam = 100 * mean(Has_Pfam))

# Calculate the proportion separately within each AED group.
by_aed <- proteins %>%
    group_by(Group = AED_group) %>%
    summarise(Total_proteins = n(), Proteins_with_Pfam = sum(Has_Pfam), Percent_with_Pfam = 100 * mean(Has_Pfam), .groups = "drop")

summary_table <- bind_rows(overall, by_aed)

print(summary_table)

# Save the summary and the per-protein results.
write_tsv(summary_table, file.path(outdir, "Pfam_by_AED_summary.tsv"))

write_tsv(proteins, file.path(outdir, "Pfam_by_AED_per_protein.tsv"))


# Create a PDF table using the grid package supplied with R.
pdf_table <- summary_table %>%
    mutate(Percent_with_Pfam = sprintf("%.2f%%", Percent_with_Pfam))

names(pdf_table) <- c("Protein group", "Total proteins", "With Pfam", "With Pfam (%)")

pdf(file.path(outdir, "Pfam_by_AED_summary.pdf"), width = 11, height = 3.5)

grid::grid.newpage()

grid::grid.text("Pfam domains by AED group", x = 0.5, y = 0.88, gp = grid::gpar(fontsize = 15, fontface = "bold"))

# Column positions.
column_x <- c(0.04, 0.49, 0.68, 0.86)

# Table headings.
for (j in seq_along(column_x)) {
    grid::grid.text(
        names(pdf_table)[j],
        x = column_x[j], y = 0.69,
        just = "left",
        gp = grid::gpar(fontsize = 11, fontface = "bold")
    )
}

grid::grid.lines( x = c(0.04, 0.97), y = c(0.63, 0.63), gp = grid::gpar(col = "grey60"))

# Table values.
for (i in seq_len(nrow(pdf_table))) {
    for (j in seq_along(column_x)) {
        grid::grid.text(
            as.character(pdf_table[[j]][i]),
            x = column_x[j],
            y = 0.54 - (i - 1) * 0.14,
            just = "left",
            gp = grid::gpar(fontsize = 11)
        )
    }
}

dev.off()

# Copy the PDF table to the project's plots directory.
plotdir <- file.path(WORKDIR, "plots/MAKER_quality")
dir.create(plotdir, recursive = TRUE, showWarnings = FALSE)

file.copy(
    from = file.path(outdir, "Pfam_by_AED_summary.pdf"),
    to = file.path(plotdir, "Pfam_by_AED_summary.pdf"),
    overwrite = TRUE
)