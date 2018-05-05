#!/bin/bash

# Variables
WITH_DOCKER=false
DATA_DIR="/data/valhalla/"
BUILD_CONFIG=false
BUILD_TRANSIT=false
BUILD_ADMINS=false
BUILD_TIMEZONES=false
DATASTORE_URL="http://localhost:8004"
CONFIG_FILE="config.json"
OSM_FILE="portugal-latest.osm.pbf"

for arg in "$@"; do
  shift
  case "$arg" in
    --datastore-url=*) DATASTORE_URL="${arg#*=}" ;;
    --build-admins) BUILD_ADMINS=true ;;
    --build-config) BUILD_CONFIG=true ;;
    --build-transit) BUILD_TRANSIT=true ;;
    --build-timezones) BUILD_TIMEZONES=true ;;
    --config-file=*) CONFIG_FILE="${arg#*=}" ;;
    --data-dir=*) DATA_DIR="${arg#*=}" ;;
    --osm-file=*) OSM_FILE="${arg#*=}" ;;
    --with-docker) WITH_DOCKER=true ;;
    --help|*) echo "Usage: ./build_tiles.sh [OPTIONS]"
              echo "Available options:"
              echo "  --build-admins      Build admins DB. False if ommited."
              echo "  --build-config      Build config file. False if ommited."
              echo "  --build-transit     Build transit tiles. False if ommited."
              echo "  --build-timezones   Build timezones DB. False if ommited."
              echo "  --config-file=FILE  Path to config file. Default is config.json"
              echo "  --datastore-url=URL URL of the Datastore API. Default is http://localhost:8004"
              echo "  --data-dir=DIR      Path to Valhalla data dir. Default is /data/valhalla/."
              echo "                      Will be mounted as a volume if --with-docker."
              echo "  --osm-file=FILE     Path to OSM .pbf file. Default is portugal-latest.osm.pbf"
              echo "  --with-docker       Build with docker. False if ommited."
              echo "  --help              Show this message"
    exit ;;
  esac
done

if [ $WITH_DOCKER = true ]
then
  CONFIG_FILE="_config.json"
fi

# Command list
docker_run="docker run "
volume1="-v ${DATA_DIR}:/data/valhalla/ "
volume2="-v ${PWD}/configs/multimodal.json:/data/valhalla/${CONFIG_FILE} "
docker_image="tpportugal/tpp_valhalla:latest "
cmd_build_timezones="valhalla_build_timezones ${CONFIG_FILE} "
cmd_build_admins="valhalla_build_admins -c ${CONFIG_FILE} ${OSM_FILE} "
cmd_build_transit="valhalla_build_transit ${CONFIG_FILE} ${DATASTORE_URL} 1000 transit -31.56,29.89,-6.18,42.23 valhalla-NJ9dUr7Rt 4"
cmd_build_tiles="valhalla_build_tiles -c ${CONFIG_FILE} ${OSM_FILE} "
cmd_create_tar="find tiles | sort -n | tar cf tiles.tar --no-recursion -T -"

# Switch to data dir - Exit script if it fails
cd $DATA_DIR || { echo "$DATA_DIR not found" && exit 1; }

# Download OSM file if it doesn't exist or was updated
wget --timestamping --backups=1 http://download.geofabrik.de/europe/portugal-latest.osm.pbf

if [ $WITH_DOCKER = true ]
then
  if [ $BUILD_TIMEZONES = true ]
  then
    eval $docker_run $volume1 $volume2 $docker_image $cmd_build_timezones
  fi
  if [ $BUILD_ADMINS = true ]
  then
    eval $docker_run $volume1 $volume2 $docker_image $cmd_build_admins
  fi
  if [ $BUILD_TRANSIT = true ]
  then
    eval $docker_run $volume1 $volume2 $docker_image $cmd_build_transit
  fi
  eval $docker_run $volume1 $volume2 $docker_image $cmd_build_tiles
  eval $docker_run $volume1 $volume2 $docker_image $cmd_create_tar
else
  if [ $BUILD_TIMEZONES = true ]
  then
    eval $cmd_build_timezones
  fi
  if [ $BUILD_ADMINS = true ]
  then
    eval $cmd_build_admins
  fi
  if [ $BUILD_TRANSIT = true ]
  then
    eval $cmd_build_transit
  fi
  eval $cmd_build_tiles
  eval $cmd_create_tar
fi
