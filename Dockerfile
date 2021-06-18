FROM mcr.microsoft.com/vscode/devcontainers/base:0-buster

#-----------------------------------------------------------
# Project Details
#-----------------------------------------------------------

LABEL project="swarm-manager"
LABEL github="https://github.com/CryptoKasm/9c-swarm-manager"
LABEL maintainer="CryptoKasm"
LABEL discord="https://discord.gg/CYaSzs4CSk"

#-----------------------------------------------------------
# Base Setup
#-----------------------------------------------------------

# [Option] Install zsh
ARG INSTALL_ZSH="false"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# [Option] Use the OSS Moby CLI instead of the licensed Docker CLI
ARG USE_MOBY="false"
# Set WORKDIR *Also determines generated container name*
ARG WORKDIRP="/9c-swarm"
WORKDIR ${WORKDIRP}
# Copy project to docker-image
COPY . .

# Install needed packages and setup non-root user. Use a separate RUN statement to add your
# own dependencies. A user of "automatic" attempts to reuse an user ID if one already exists.
ARG USERNAME=automatic
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update \
    && /bin/bash ${WORKDIRP}/.devcontainer/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Use Docker script from script library to set things up
    && /bin/bash ${WORKDIRP}/.devcontainer/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" "${USE_MOBY}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* ${WORKDIRP}/.devcontainer/library-scripts/

RUN apt-get update && apt-get install jq -y

#-----------------------------------------------------------
# Settings
#-----------------------------------------------------------

ENV private_key="PUT_YOUR_PRIVATE_KEY_HERE"

#-----------------------------------------------------------
# Healthcheck & Entrypoint /w ARGs [--wait]
#-----------------------------------------------------------

HEALTHCHECK --interval=1m30s --timeout=30s --start-period=30s --retries=3 CMD ["./scripts/healthcheck.sh", "--check-ping"]

ENTRYPOINT ["./swarm-manager.sh"]
CMD ["--start", "--keep-alive"]
