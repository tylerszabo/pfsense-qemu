FROM alpine:3.12

RUN apk add --no-cache qemu-system-x86_64 qemu-img expect dosfstools mtools parted

COPY install.tcl /builder/install.tcl

ENV INSTALLER_URL=https://nyifiles.pfsense.org/mirror/downloads/pfSense-CE-memstick-serial-2.4.5-RELEASE-p1-amd64.img.gz
ENV INSTALLER_PATH=/installer-images/pfSense-CE-memstick-serial-2.4.5-RELEASE-p1-amd64.img.gz
ENV CONFIG_XML_PATH=/conf/config.xml
ENV OUTPUT_PATH=/output/pfsense.qcow2

VOLUME /installer-images
VOLUME /output

WORKDIR /builder

CMD /builder/install.tcl