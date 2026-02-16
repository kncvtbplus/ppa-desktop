FROM rocker/r-ver:4.3.1

# System dependencies for R packages used by Auto.PPA.UI.R
# Use --no-install-recommends to keep the image smaller and installs faster.
RUN apt-get update && apt-get install -y --no-install-recommends \
    littler \
    default-jdk \
    libpq-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Core R packages required by the Auto.PPA.UI.R script and Java glue code.
# Use multiple CPUs when available to speed up compilation.
# Note: we use 'openxlsx' (no Java dependency) instead of 'xlsx' to avoid
# rJava/Java toolchain issues inside the container while still writing .xlsx files.
# Additionally install 'haven' and 'readstata13' so we can read modern Stata
# .dta files (v13+) without hitting the legacy foreign::read.dta limitations.
RUN R -q -e "options(Ncpus = max(1L, parallel::detectCores() - 1L)); install.packages(c('Rserve','plyr','foreign','dplyr','openxlsx','ggplot2','tidyr','cowplot','scales','RPostgreSQL','DBI','haven','readstata13'), repos='https://cloud.r-project.org')"

EXPOSE 6311

## IMPORTANT:
## Rserve::Rserve() starts Rserve in daemon mode and normally returns,
## which would let the R process exit. We explicitly keep the R session
## alive afterwards so that the Docker container does not stop.
CMD ["R", "-q", "-e", "Rserve::Rserve(args='--RS-enable-remote --no-save'); while(TRUE) Sys.sleep(3600)"]