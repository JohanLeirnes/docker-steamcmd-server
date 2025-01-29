FROM ich777/winehq-baseimage

LABEL maintainer="yeitso"
LABEL org.opencontainers.image.source="https://github.com/yeitso/docker-steamcmd-server"

RUN apt-get update && apt-get install -y \
    lib32gcc-s1 \
    winbind \
    xvfb \
    screen \
    libvulkan1 \
    libvulkan1:i386 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386 \
    winetricks \
    cabextract \
    unzip \
    xorg \
    x11-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV DATA_DIR="/serverdata"
ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd"
ENV SERVER_DIR="${DATA_DIR}/serverfiles"
ENV GAME_ID="3246670"
ENV GAME_NAME="aska"
ENV GAME_PARAMS=""
ENV VALIDATE=""
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV USER="steam"
ENV DATA_PERM=770

RUN mkdir $DATA_DIR && \
    mkdir $STEAMCMD_DIR && \
    mkdir $SERVER_DIR && \
    useradd -d $DATA_DIR -s /bin/bash $USER && \
    chown -R $USER $DATA_DIR && \
    ulimit -n 2048

# Expose the Steam game port and query port
EXPOSE 27015/udp
EXPOSE 27016/udp

ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
