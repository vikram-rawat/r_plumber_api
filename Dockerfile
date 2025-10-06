FROM ixpantia/faucet:r4.5

# Install linux dependencies for R packages
RUN apt-get update && apt-get install -y \
  libssl-dev \
  libxml2-dev \
  libcurl4-openssl-dev \
  build-essential \
  cmake \
  pkg-config \
  libmbedtls-dev \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Some environment variables to tell `renv`
# to install packages in the correct location
# and without unnecessary symlinks
ENV RENV_CONFIG_CACHE_SYMLINKS FALSE
ENV RENV_PATHS_LIBRARY /srv/faucet/renv/library

# You copy the necessary files to bootstrap `renv`
COPY . .

# You install the packages
RUN Rscript -e "renv::restore()"

# expose the port
EXPOSE 3838

# You can run the container as a non-root user
# for security reasons if we want to though
# this is not necessary. You could ignore this
RUN chown -R faucet:faucet /srv/faucet/
USER faucet
