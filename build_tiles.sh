#!/bin/bash

# Variables
WITH_DOCKER=false
DATA_DIR="/data/valhalla/"
WEB_PROTOCOL="http"
HOST_BANCO_DE_DADOS="localhost"
PORT_BANCO_DE_DADOS=8004
CONFIG_FILE="configs/multimodal.json"
OSM_FILE="portugal-latest.osm.pbf"

for arg in "$@"; do
  shift
  case "$arg" in
    -d|--with-docker) WITH_DOCKER=true ;;
    -o=*|--data-dir=*) DATA_DIR="${arg#*=}" ;;
    -h|?|--help) echo "Usage: build.sh [OPTIONS]"
                 echo "Available options:"
                 echo "  -h, ?,    --help|           Show this message"
                 echo "  -d,       --with-docker     Build in a docker container." \
                                                    "False if ommited."
                 echo "  -o=/dir/, --data-dir=/dir/  Path to Valhalla data dir. " \
                                                    "Default is /data/valhalla/."
                 echo "                              Mounted as a volume if --with-docker." ;;
  esac
done

if [ $WITH_DOCKER = true ]
then
  HOST_BANCO_DE_DADOS="tpp.pt"
  CONFIG_FILE="_config.json"
fi

# Command list
docker_run="docker run "
volume1="-v ${DATA_DIR}:/data/valhalla/ "
volume2="-v ${PWD}/configs/multimodal.json:/data/valhalla/${CONFIG_FILE} "
docker_image="tpportugal/tpp_valhalla:latest "
cmd_build_timezones="valhalla_build_timezones ${CONFIG_FILE} "
cmd_build_admins="valhalla_build_admins -c ${CONFIG_FILE} ${OSM_FILE} "
cmd_build_transit="valhalla_build_transit ${CONFIG_FILE} ${WEB_PROTOCOL}://${HOST_BANCO_DE_DADOS}:${PORT_BANCO_DE_DADOS} 1000 /data/valhalla/transit -31.56,29.89,-6.18,42.23 XXXXXXX 4"
cmd_build_tiles="valhalla_build_tiles -c ${CONFIG_FILE} ${OSM_FILE} "
cmd_create_tar="find tiles | sort -n | tar cf tiles.tar --no-recursion -T -"

# Switch to data dir
cd $DATA_DIR

# Download OSM file if it doesn't exist or was updated
wget --timestamping --backups=1 http://download.geofabrik.de/europe/portugal-latest.osm.pbf

if [ $WITH_DOCKER = true ]
then
  eval $docker_run $volume1 $volume2 $docker_image $cmd_build_timezones
  eval $docker_run $volume1 $volume2 $docker_image $cmd_build_admins
  eval $docker_run $volume1 $volume2 $docker_image $cmd_build_transit
  eval $docker_run $volume1 $volume2 $docker_image $cmd_build_tiles
  eval $docker_run $volume1 $volume2 $docker_image $cmd_create_tar
else
  eval $cmd_build_timezones
  eval $cmd_build_admins
  eval $cmd_build_transit
  eval $cmd_build_tiles
  eval $cmd_create_tar
fi
