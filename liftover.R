# Script to liftOver from dm3 to dm6 for one or more BED files

# Carlos Camilleri-Robles, 7-10-2025
# Current version uses no headed 5-column bed files


## Install packages from CRAN and Bioconductor
cran_packages <- c("dplyr", "R.utils")
bioc_packages <- c("rtracklayer", "GenomicRanges")

## Install CRAN packages
for (pkg in cran_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Installing package:", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

## Install Bioconductor packages
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}
for (pkg in bioc_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Installing package:", pkg))
    BiocManager::install(pkg, ask = FALSE, update = FALSE)
  }
}


## Load libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(rtracklayer)
  library(GenomicRanges)
  library(R.utils)
})


## Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("Please provide at least one BED file.\nUsage: Rscript liftover.R file1.bed file2.bed")
}


## Prepare the chain file
chain_url <- "http://hgdownload.soe.ucsc.edu/goldenPath/dm3/liftOver/dm3ToDm6.over.chain.gz"
chain_gz <- file.path(tempdir(), basename(chain_url))
chain_file <- sub("\\.gz$", "", chain_gz)

if (!file.exists(chain_gz)) {
  download.file(chain_url, chain_gz, mode = "wb")
}
if (!file.exists(chain_file)) {
  gunzip(chain_gz, destname = chain_file, overwrite = TRUE)
}
chain <- import.chain(chain_file)


## Create output directory
output_dir <- "Output"
if (!dir.exists(output_dir)) dir.create(output_dir)


## Process each BED file
for (input_path in args) {
  if (!file.exists(input_path)) {
    warning(paste("File not found:", input_path))
    next
  }
  
  message(paste("Processing file:", input_path))
  
  ## Load bed file
  bed_df <- read.delim(input_path, header = FALSE, stringsAsFactors = FALSE)
  if (ncol(bed_df) < 5) {
    warning(paste("File format incorrect for:", input_path, "- 5-column format is required."))
    next
  }
  
  ## Add header
  colnames(bed_df) <- c("chr", "start", "end", "name", "score")
  bed_df$chr <- ifelse(grepl("^chr", bed_df$chr), bed_df$chr, paste0("chr", bed_df$chr))
  
  ## Convert to GRanges
  gr_dm3 <- GRanges(
    seqnames = bed_df$chr,
    ranges   = IRanges(start = bed_df$start, end = bed_df$end),
    name     = bed_df$name,
    score    = bed_df$score
  )
  
  ## Run liftOver
  gr_dm6 <- liftOver(gr_dm3, chain)
  mapped_idx <- elementNROWS(gr_dm6) > 0
  if (sum(mapped_idx) == 0) {
    warning(paste("No ranges could be mapped for:", input_path))
    next
  }
  
  gr_dm6_flat <- unlist(gr_dm6[mapped_idx], use.names = FALSE)
  
  ## Export as dataframe
  dm6_df <- data.frame(
    chr   = as.character(seqnames(gr_dm6_flat)),
    start = start(gr_dm6_flat),
    end   = end(gr_dm6_flat),
    name  = mcols(gr_dm6_flat)$name,
    score = mcols(gr_dm6_flat)$score,
    stringsAsFactors = FALSE
  )
  
  ## Save output
  output_file <- file.path(output_dir, sub("\\.bed$", ".dm6.bed", basename(input_path)))
  write.table(dm6_df, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
  
  message(paste("Converted file saved in:", output_file))
}

message("All files processed.")
