# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------

ARG BASE=mbentley/omada-controller:4.3-armv7l
FROM ${BASE}
HEALTHCHECK CMD wget --quiet --tries=1 --no-check-certificate http://127.0.0.1:8088 || exit 1


RUN mkdir -p /data/omada_controller/logs /data/omada_controller/work \
  && cp -R /opt/tplink/EAPController/data /data/omada_controller \
	&& chown -R omada:omada /data/omada_controller \
  && rm -rf /opt/tplink/EAPController/data /opt/tplink/EAPController/logs /opt/tplink/EAPController/work \
  && ln -sf /data/omada_controller/data /opt/tplink/EAPController/data \
  && ln -sf /data/omada_controller/logs /opt/tplink/EAPController/logs \
  && ln -sf /data/omada_controller/work /opt/tplink/EAPController/work

EXPOSE 8043/tcp 8088/tcp 27001/udp 27002/tcp 29810/udp 29811/tcp 29812/tcp 29813/tcp

CMD ["/usr/bin/java","-server","-Xms128m","-Xmx1024m","-XX:MaxHeapFreeRatio=60","-XX:MinHeapFreeRatio=30","-XX:+HeapDumpOnOutOfMemoryError","-cp","/opt/tplink/EAPController/lib/*:","com.tplink.omada.start.OmadaLinuxMain"]
