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
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="true"
# [Option] Use the OSS Moby CLI instead of the licensed Docker CLI
ARG USE_MOBY="true"

# Install needed packages and setup non-root user.
ARG USERNAME=automatic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Use Docker script from script library to set things up
    && /bin/bash /tmp/library-scripts/docker-debian.sh "${ENABLE_NONROOT_DOCKER}" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

RUN apt-get install jq unzip -y

#-----------------------------------------------------------
# Settings
#-----------------------------------------------------------

ENV debug="true"
ENV trace="true"
ENV dev_mode="true"
ENV private_key="demo"
ENV enable_graphql_token="true"

#-----------------------------------------------------------
# Entrypoint /w ARGs
#-----------------------------------------------------------

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]