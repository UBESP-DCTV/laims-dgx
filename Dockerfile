FROM nvcr.io/nvidia/tensorflow:25.01-tf2-py3

LABEL maintainer="Corrado Lanera <corrado.lanera@unipd.it>"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       software-properties-common \
       dirmngr \
       gnupg \
       ca-certificates \
       wget \
       libcurl4-openssl-dev \
       libssl-dev \
       libxml2-dev \
       git \
       libpng-dev \
       pciutils \
       python3 \
       python3-pip \
       python3-venv \
       python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends wget gnupg2 \
    && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    && echo "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" > /etc/apt/sources.list.d/cran-r.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends r-base r-base-dev \
    && apt-get clean

ARG R_LIBS=/usr/local/lib/R/site-library
RUN chmod -R 777 ${R_LIBS}
RUN R -e "install.packages('pak', repos='https://packagemanager.posit.co/cran/__linux__/noble/2025-02-21'); \
          pak::pkg_install(c('tensorflow', 'keras3'), lib = '${R_LIBS}')"

RUN R -e "pak::pkg_install(c('tidyverse'), lib = '${R_LIBS}')"

WORKDIR /project

ENTRYPOINT ["Rscript"]
CMD ["--version"]

