FROM rocker/r-ver:4.3.1

RUN apt-get update && apt-get install -y \
    littler \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages('Rserve', repos='https://cloud.r-project.org')"

EXPOSE 6311

CMD ["R", "-e", "Rserve::Rserve(args='--RS-enable-remote --no-save')"]



