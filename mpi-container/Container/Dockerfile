FROM debian:sid

SHELL ["/bin/bash", "-c"]

# Run as root to install packages
USER root

COPY scripts /scripts

# Update and install dependencies
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
        mpich \
        openssh-server openssh-client && \
    rm -rf /var/lib/apt/lists/*
