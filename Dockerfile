FROM ubuntu:24.04

LABEL maintainer="xiahualiu"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Arguments for build-time configuration
ARG STEAM_USER="steam"
ARG STEAM_HOME="/home/steam"
ARG STEAM_USER_UID=1000
ARG STEAM_USER_GID=1000
ARG STEAMCMD_DIR="${STEAM_HOME}/steamcmd"
ARG STEAM_APP_DIR="${STEAM_HOME}/server"
ARG STEAM_COMPAT_DATA_PATH="${STEAM_HOME}/proton-compat"
ARG PROTON_VERSION="GE-Proton10-26"
ARG STEAM_COMPAT_CLIENT_INSTALL_PATH="${STEAM_HOME}/proton-steam"

# 1. Set Environment Variables
ENV STEAM_USER=${STEAM_USER}
ENV STEAM_HOME=${STEAM_HOME}
ENV STEAMCMD_DIR=${STEAMCMD_DIR}
ENV STEAM_APP_DIR=${STEAM_APP_DIR}
ENV STEAM_COMPAT_DATA_PATH=${STEAM_COMPAT_DATA_PATH}
ENV STEAM_COMPAT_CLIENT_INSTALL_PATH=${STEAM_COMPAT_CLIENT_INSTALL_PATH}
ENV PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz"
ENV PROTON_VERSION=${PROTON_VERSION}
ENV PROTON_EXECUTABLE_PATH="${STEAM_HOME}/proton/proton"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 2. Install Prerequisites
# SteamCMD requires 32-bit libraries (i386 architecture)
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y \
        wget \
        curl \
        tar \
        python3 \
        xvfb \
        lib32gcc-s1 \
        lib32stdc++6 \
        libgl1-mesa-glx:i386 \
        ca-certificates \
        locales \
    # Generate locale (prevents some character encoding issues in logs)
    && locale-gen en_US.UTF-8 \
    # Clean up to keep image size down
    && rm -rf /var/lib/apt/lists/*

# 3. Create the 'steam' user and group
RUN groupadd -g ${STEAM_USER_GID} ${STEAM_USER} \
    && useradd -m -d ${STEAM_HOME} -s /bin/bash -u ${STEAM_USER_UID} -g ${STEAM_USER_GID} ${STEAM_USER}

# 4. Switch to the user to perform downloads (Security Best Practice)
USER ${STEAM_USER}
WORKDIR ${STEAM_HOME}

# 5. Download and Install SteamCMD
RUN mkdir -p ${STEAMCMD_DIR} \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C ${STEAMCMD_DIR}

# 6. Download and Install GE-Proton
RUN mkdir -p ${STEAM_HOME}/proton \
    && wget -qO- ${PROTON_URL} | tar -xz --strip-components=1 -C ${STEAM_HOME}/proton

# 7. Create directory structure for server and save data
RUN mkdir -p ${STEAM_APP_DIR} \
    && mkdir -p ${STEAM_COMPAT_DATA_PATH} \
    && mkdir -p ${STEAM_COMPAT_CLIENT_INSTALL_PATH}/steamapps

# 8. Copy Entrypoint Script
COPY --chown=${STEAM_USER}:${STEAM_USER} entrypoint.sh ${STEAM_HOME}/entrypoint.sh
RUN chmod +x ${STEAM_HOME}/entrypoint.sh

# 9. Set the working directory to the server folder
WORKDIR ${STEAM_APP_DIR}

ENTRYPOINT ["/home/steam/entrypoint.sh"]