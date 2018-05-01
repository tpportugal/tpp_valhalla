#!/bin/bash
WITH_DOCKER=false
for arg in "$@"; do
  shift
  case "$arg" in
    "--with-docker") WITH_DOCKER=true ;;
  esac
done

# Variables
CONFIG_FILE="configs/multimodal.json"
PORT=8002

if [ $WITH_DOCKER = true ] 
then
	CONFIG_FILE="_config.json"
fi

# Command list
run="docker run -d -p ${PORT}:${PORT}"
volume1="-v ${PWD}/configs/multimodal.json:/data/valhalla/_config.json "
docker_image="tpportugal/tpp_valhalla:latest "
cmd_start="valhalla_service ${CONFIG_FILE} 1 "

if [ $WITH_DOCKER = true ] 
then
	eval $run $volume1 $docker_image $cmd_start
else
    eval $cmd_start
fi
