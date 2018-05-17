#!/bin/bash

# Variables
CONFIG_FILE="config.json"
DATA_DIR="/data/valhalla"
PORT=8002
WITH_DOCKER=false

for arg in "$@"; do
  shift
  case "$arg" in
    --config-file=*) CONFIG_FILE="${arg#*=}" ;;
    --data-dir=*) DATA_DIR="${arg#*=}" ;;
    --with-docker) WITH_DOCKER=true ;;
    --help|-h|*) echo "Usage: ./run.sh [OPTIONS]"
              echo "Available options:"
              echo "  --config-file=FILE  Path to config file. Default is config.json"
              echo "  --data-dir=DIR      Path to Valhalla data dir. Default is /data/valhalla."
              echo "  --with-docker       Build with docker. False if ommited."
              echo "  --help, -h          Show this message"
    exit ;;
  esac
done

# Command list
run="docker run --shm-size 512M -d -p ${PORT}:${PORT}"
volume1="-v ${DATA_DIR}:/data/valhalla"
docker_image="tpportugal/tpp_valhalla:latest"
cmd_start="bash -c \"valhalla_service ${CONFIG_FILE} 1 >> valhalla_service.log 2>&1\""

if [ $WITH_DOCKER = true ]
then
  eval $run $volume1 $docker_image $cmd_start
else
  cd "${DATA_DIR}"
  eval $cmd_start
fi
