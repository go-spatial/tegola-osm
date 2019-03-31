##
# tegola/osm
#
# This creates an Ubuntu derived base image and installs the necessary
# dependencies for running osm import and updates for tegola.

FROM ubuntu:bionic

# Set the session to noninteractive. Only applies for life of dockerfile.
ARG DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update -y && \
	apt-get install -y \
	apt-utils \
	software-properties-common \
	unzip \
	curl \
	wget

# Install Java runtime
RUN apt-get update -y && \
	apt-get install -y default-jre

# Install osmosis
RUN mkdir -p /usr/local/bin/osmosis-src && \
	wget --quiet -O - https://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz | tar -xz -C /usr/local/bin/osmosis-src && \
	ln -s /usr/local/bin/osmosis-src/bin/osmosis /usr/local/bin/osmosis

# Install imposm
RUN mkdir -p /usr/local/bin/imposm-src && \
	wget --quiet -O - https://github.com/omniscale/imposm3/releases/download/v0.6.0-alpha.4/imposm-0.6.0-alpha.4-linux-x86-64.tar.gz | tar -xz -C /usr/local/bin/imposm-src && \
	ln -s /usr/local/bin/imposm-src/imposm-0.6.0-alpha.4-linux-x86-64/imposm /usr/local/bin/imposm && \
	ln -s /usr/local/bin/imposm-src/imposm-0.6.0-alpha.4-linux-x86-64/lib/* /usr/lib/

# Install the local scripts
COPY scripts/osm_import.sh /usr/local/bin/osm_import.sh
COPY scripts/osm_update.sh /usr/local/bin/osm_update.sh