#!/usr/bin/env bash

set -e

# omada controller dependency and package installer script for versions 4.x and 5.x

# set default variables
OMADA_DIR="/data/omada_controller"
ARCH="${ARCH:-}"
INSTALL_VER="${INSTALL_VER:-}"

# install wget
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install --no-install-recommends -y ca-certificates wget

# get URL to package based on major.minor version; for information on this url API, see https://github.com/mbentley/docker-omada-controller-url
OMADA_URL="$(wget -q -O - "https://omada-controller-url.mbentley.net/hooks/omada_ver_to_url?omada-ver=${INSTALL_VER}")"

# make sure OMADA_URL isn't empty
if [ -z "${OMADA_URL}" ]
then
  echo "ERROR: ${OMADA_URL} did not return a valid URL"
  exit 1
fi

# extract required data from the OMADA_URL
OMADA_TAR="$(echo "${OMADA_URL}" | awk -F '/' '{print $NF}')"
OMADA_VER="$(echo "${OMADA_TAR}" | awk -F '_v' '{print $2}' | awk -F '_' '{print $1}')"
OMADA_MAJOR_VER="${OMADA_VER%.*.*}"
OMADA_MAJOR_MINOR_VER="${OMADA_VER%.*}"

# function to exit on error w/message
die() { echo -e "$@" 2>&1; exit 1; }

echo "**** Selecting packages based on the architecture and version ****"
# common package dependencies
PKGS=(
  gosu
  net-tools
  tzdata
  wget
)

# add specific package for mongodb
case "${ARCH}" in
  amd64|arm64|"")
    PKGS+=( mongodb-server-core )
    ;;
  armv7l)
    PKGS+=( mongodb )
    ;;
  *)
    die "${ARCH}: unsupported ARCH"
    ;;
esac

# add specific package for openjdk
case "${ARCH}" in
  amd64|arm64|"")
    # use openjdk-17 for v5.4 and above; all others us openjdk-8
    case "${OMADA_MAJOR_VER}" in
      5)
        # pick specific package based on the major.minor version
        case "${OMADA_MAJOR_MINOR_VER}" in
          5.0|5.1|5.3)
            # 5.0 to 5.3 all use openjdk-8
            PKGS+=( openjdk-8-jre-headless )
            ;;
          *)
            # starting with 5.4, openjdk-17 is supported
            PKGS+=( openjdk-17-jre-headless )
            ;;
        esac
        ;;
      *)
        # all other versions, use openjdk-8
        PKGS+=( openjdk-8-jre-headless )
        ;;
    esac
    ;;
  armv7l)
    # always use openjdk-8 for armv7l
    PKGS+=( openjdk-8-jre-headless )
    ;;
  *)
    die "${ARCH}: unsupported ARCH"
    ;;
esac

# output variables/selections
echo "ARCH=${ARCH}"
echo "OMADA_VER=${OMADA_VER}"
echo "OMADA_TAR=${OMADA_TAR}"
echo "OMADA_URL=${OMADA_URL}"
echo "PKGS=( ${PKGS[*]} )"

echo "**** Install Dependencies ****"
apt-get install --no-install-recommends -y "${PKGS[@]}"

echo "**** Download Omada Controller ****"
cd /tmp
wget -nv "${OMADA_URL}"

echo "**** Extract and Install Omada Controller ****"

# in the 4.4.3, 4.4.6, and 4.4.8 builds, they removed the directory. this case statement will handle variations in the build
case "${OMADA_VER}" in
  4.4.3|4.4.6|4.4.8)
    echo "version ${OMADA_VER}"
    mkdir "Omada_SDN_Controller_${OMADA_VER}"
    cd "Omada_SDN_Controller_${OMADA_VER}"
    tar zxvf "../${OMADA_TAR}"
    rm -f "../${OMADA_TAR}"
    ;;
  *)
    echo "not version 4.4.3/4.4.6/4.4.8"
    tar zxvf "${OMADA_TAR}"
    rm -f "${OMADA_TAR}"
    cd Omada_SDN_Controller_*
    ;;
esac

# make sure tha the install directory exists
mkdir "${OMADA_DIR}" -vp

# starting with 5.0.x, the installation has no webapps directory; these values are pulled from the install.sh
case "${OMADA_MAJOR_VER}" in
  5)
    # see if we are running 5.3.x or greater by checking the minor version
    if [ "${OMADA_MAJOR_MINOR_VER#*.}" -ge 3 ]
    then
      # 5.3.1 and above moved the keystore directory to be a subdir of data
      NAMES=( bin data properties lib install.sh uninstall.sh )
    else
      # is less than 5.3
      NAMES=( bin data properties keystore lib install.sh uninstall.sh )
    fi
    ;;
  *)
    # isn't v5.x
    NAMES=( bin data properties keystore lib webapps install.sh uninstall.sh )
    ;;
esac

# copy over the files to the destination
for NAME in "${NAMES[@]}"
do
  cp "${NAME}" "${OMADA_DIR}" -r
done

# copy omada default properties for can be used when properties is mounted as volume
mkdir "${OMADA_DIR}/properties.defaults"
cp -r properties/ "${OMADA_DIR}/properties.defaults"

# symlink for mongod
ln -sf "$(command -v mongod)" "${OMADA_DIR}/bin/mongod"
chmod 755 "${OMADA_DIR}"/bin/*

# starting with 5.0.x, the work directory is no longer needed
case "${OMADA_MAJOR_VER}" in
  5)
    # create logs directory
    mkdir "${OMADA_DIR}/logs"
    ;;
  *)
    # create logs and work directories
    mkdir "${OMADA_DIR}/logs" "${OMADA_DIR}/work"
    ;;
esac

# for v5.1 & above, create backup of data/html directory in case it is missing (to be extracted at runtime)
if [ -d /data/omada_controller/data/html ]
then
  # create backup
  cd /data/omada_controller/data
  tar zcvf ../data-html.tar.gz html
fi

echo "**** Cleanup ****"
rm -rf /tmp/* /var/lib/apt/lists/*

# write installed version to a file
echo "${OMADA_VER}" > "${OMADA_DIR}/IMAGE_OMADA_VER.txt"