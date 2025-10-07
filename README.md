# liftover

This R script converts BED files from the dm3 genome assembly (Drosophila melanogaster) to dm6 using UCSC's liftOver tool. It supports multiple BED files in a single run and automatically installs required dependencies and the UCSC dm3 to dm6 chain file.


## Requirements
R (version ≥ 4.0 recommended)
Internet connection (to download the dm3ToDm6 chain file)
BED files with 5 columns, no header: chr, start, end, name, score


## Installation
To clone this repository:
```bash
git clone https://github.com/ccarloscr/liftover.git
cd liftover
```


## Usage
Run the script from the terminal, passing one or more BED files as arguments:
```bash
Rscript liftover.R file1.bed file2.bed
```


## License
This project is licensed under the MIT License.
