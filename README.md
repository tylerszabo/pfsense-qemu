# Automated pfSense QEMU image creation

## Notes

Use a persistent volume or mounted directory to avoid redownloading install image.

## Usage

The following to outputs an installed image to `./output/pfsense.qcow2` and persists install images

```sh
docker build --tag pfsense-qemu:latest .
docker run --rm -it -v "$PWD/cache:/installer-images" -v "$PWD/output:/output" -v "$PWD/config.xml:/conf/config.xml" pfsense-qemu:latest
```

Alternatively, invoke directly without Docker

```sh
./install.tcl OUTPUT_FILE BASE_IMAGE [CONFIG_XML]
```
