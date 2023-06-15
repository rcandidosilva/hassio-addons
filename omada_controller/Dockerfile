# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------

ARG BASE=mbentley/ubuntu:20.04
FROM ${BASE}

HEALTHCHECK CMD wget --quiet --tries=1 --no-check-certificate http://127.0.0.1:8088 || exit 1

COPY healthcheck.sh install.sh entrypoint.sh log4j_patch.sh /

# valid values: amd64 (default) | arm64 | armv7l
ARG ARCH=arm64

# install version (major.minor only); OMADA_URL set in install.sh
ARG INSTALL_VER="5.9"

RUN chmod +x /*.sh

# install omada controller (instructions taken from install.sh) & patch log4j, if applicable
RUN /install.sh &&\
  /log4j_patch.sh &&\
  rm /install.sh /log4j_patch.sh

# Copy configuration properties
COPY omada.properties log4j2.properties /data/omada_controller/properties/

EXPOSE 8043/tcp 8088/tcp 27001/udp 27002/tcp 29810/udp 29811/tcp 29812/tcp 29813/tcp 29814/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-XX:HeapDumpPath=/data/omada_controller/logs/java_heapdump.hprof","-Djava.awt.headless=true","-cp","/data/omada_controller/lib/*::/data/omada_controller/properties:","com.tplink.smb.omada.starter.OmadaLinuxMain"]
