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
ARG PROTON_DIR="${STEAM_HOME}/proton"
ARG PROTON_VERSION="GE-Proton10-26"

# Set Environment Variables
ENV STEAM_USER=${STEAM_USER}
ENV STEAM_HOME=${STEAM_HOME}
ENV STEAMCMD_DIR=${STEAMCMD_DIR}
ENV STEAM_APP_DIR=${STEAM_APP_DIR}
ENV PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz"
ENV PROTON_VERSION=${PROTON_VERSION}
ENV PROTON_DIR=${PROTON_DIR}
ENV PROTON_EXECUTABLE_PATH="${PROTON_DIR}/proton"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Prerequisites
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
        libgl1:i386 \
        libgl1-mesa-dri:i386 \
        ca-certificates \
        locales \
        dbus \
    # Generate locale (prevents some character encoding issues in logs)
    && locale-gen en_US.UTF-8 \
    # Clean up to keep image size down
    && rm -rf /var/lib/apt/lists/*

# Create the 'steam' user and group (replace any conflicting UID/GID)
RUN set -eux; \
    if id -u "${STEAM_USER}" >/dev/null 2>&1; then userdel -r "${STEAM_USER}"; fi; \
    if getent passwd "${STEAM_USER_UID}" >/dev/null; then \
        old_user=$(getent passwd "${STEAM_USER_UID}" | cut -d: -f1); \
        userdel -r "${old_user}"; \
    fi; \
    if getent group "${STEAM_USER_GID}" >/dev/null; then \
        old_group=$(getent group "${STEAM_USER_GID}" | cut -d: -f1); \
        groupdel "${old_group}"; \
    fi; \
    groupadd -g ${STEAM_USER_GID} ${STEAM_USER}; \
    useradd -m -d ${STEAM_HOME} -s /bin/bash -u ${STEAM_USER_UID} -g ${STEAM_USER_GID} ${STEAM_USER}

# Set up Machine ID (required for Proton)
RUN rm -f /etc/machine-id \
    && dbus-uuidgen --ensure=/etc/machine-id

# Switch to the user to perform downloads (Security Best Practice)
USER ${STEAM_USER}
WORKDIR ${STEAM_HOME}

# Download and Install SteamCMD
RUN mkdir -p ${STEAMCMD_DIR} \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C ${STEAMCMD_DIR} \
    && ${STEAMCMD_DIR}/steamcmd.sh +quit

# Create Steam SDK symlinks (required for many game servers)
RUN mkdir -p ${STEAM_HOME}/.steam/sdk64 \
    && mkdir -p ${STEAM_HOME}/.steam/sdk32 \
    && ln -sf ${STEAMCMD_DIR}/linux64/steamclient.so ${STEAM_HOME}/.steam/sdk64/steamclient.so \
    && ln -sf ${STEAMCMD_DIR}/linux32/steamclient.so ${STEAM_HOME}/.steam/sdk32/steamclient.so \
    # Some games also look for steamservice.so
    && ln -sf ${STEAMCMD_DIR}/linux64/steamclient.so ${STEAM_HOME}/.steam/sdk64/steamservice.so \
    && ln -sf ${STEAMCMD_DIR}/linux32/steamclient.so ${STEAM_HOME}/.steam/sdk32/steamservice.so \
    # Create additional expected paths
    && ln -sf ${STEAMCMD_DIR}/linux64 ${STEAM_HOME}/.steam/bin64 \
    && ln -sf ${STEAMCMD_DIR}/linux32 ${STEAM_HOME}/.steam/bin32

# Download and Install GE-Proton
RUN mkdir -p ${PROTON_DIR} \
    && wget -qO- ${PROTON_URL} | tar -xz --strip-components=1 -C ${PROTON_DIR}

# Ensure Proton executable has execute permissions
RUN chmod +x ${PROTON_EXECUTABLE_PATH}

# Create directory structure for server and save data
RUN mkdir -p ${STEAM_APP_DIR} \
    && mkdir -p ${STEAM_HOME}/.config/protonfixes

# Copy Entrypoint Script
COPY --chown=${STEAM_USER}:${STEAM_USER} entrypoint.sh ${STEAM_HOME}/entrypoint.sh
RUN chmod +x ${STEAM_HOME}/entrypoint.sh

ENTRYPOINT ["/bin/bash", "-c", "${STEAM_HOME}/entrypoint.sh"]