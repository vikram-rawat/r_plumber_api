FROM ixpantia/faucet:r4.5

# Some environment variables to tell `renv`
# to install packages in the correct location
# and without unnecessary symlinks
ENV RENV_CONFIG_CACHE_SYMLINKS=FALSE
ENV RENV_PATHS_LIBRARY=/srv/faucet/renv/library

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

# set working directory
WORKDIR /srv/faucet/

# Copy only renv files first
COPY renv.lock renv.lock
COPY renv/activate.R renv/activate.R

# Install renv first
RUN Rscript -e "install.packages('renv')"

# install the packages
RUN Rscript -e "renv::restore()"

# copy all the necessary files to bootstrap `renv`
COPY . .

# deactivate renv for the final image
RUN rm -f .Rprofile

# expose the port
EXPOSE 3838

# You can run the container as a non-root user
# for security reasons if we want to though
# this is not necessary. You could ignore this
RUN chown -R faucet:faucet /srv/faucet/
USER faucet

# run the faucet server
CMD ["router"]
