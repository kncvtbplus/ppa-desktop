FROM rocker/r-ver:4.3.1

# System dependencies for R packages used by Auto.PPA.UI.R
RUN apt-get update && apt-get install -y \
    littler \
    default-jdk \
    && rm -rf /var/lib/apt/lists/*

# Core R packages required by the Auto.PPA.UI.R script
RUN R -e "install.packages(c('Rserve','plyr','foreign','dplyr','xlsx'), repos='https://cloud.r-project.org')"

EXPOSE 6311

## IMPORTANT:
## When you call Rserve::Rserve() from R with -e, it starts Rserve in
## daemon mode and then the R process exits. In a Docker container that
## means PID 1 exits and the container stops, even though Rserve briefly
## starts. To keep the container alive we start Rserve and then block
## the R session forever.
CMD ["R", "-q", "-e", "Rserve::Rserve(args='--RS-enable-remote --no-save'); Sys.sleep(Inf)"]




