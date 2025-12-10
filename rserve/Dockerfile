FROM rocker/r-ver:4.3.1

# System dependencies for R packages used by Auto.PPA.UI.R
RUN apt-get update && apt-get install -y \
    littler \
    default-jdk \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Core R packages required by the Auto.PPA.UI.R script and Java glue code
RUN R -e "install.packages(c('Rserve','plyr','foreign','dplyr','xlsx','ggplot2','tidyr','cowplot','scales','RPostgreSQL','DBI'), repos='https://cloud.r-project.org')"

EXPOSE 6311

## IMPORTANT:
## Rserve::Rserve() starts Rserve in daemon mode and normally returns,
## which would let the R process exit. We explicitly keep the R session
## alive afterwards so that the Docker container does not stop.
CMD ["R", "-q", "-e", "Rserve::Rserve(args='--RS-enable-remote --no-save'); while(TRUE) Sys.sleep(3600)"]




