# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#

ARG BASE=mbentley/omada-controller:4.3
FROM ${BASE}
EXPOSE 8088 8043 8843 27001/udp 27002 29810/udp 29811 29812 29813
CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-cp","/opt/tplink/EAPController/lib/*:","com.tplink.omada.start.OmadaLinuxMain"]
