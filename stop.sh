#!/bin/bash
WITH_DOCKER=false
for arg in "$@"; do
  shift
  case "$arg" in
    "--with-docker") WITH_DOCKER=true ;;
  esac
done

if [ $WITH_DOCKER = true ]
then
  docker stop $(docker ps -q --filter ancestor=tpportugal/tpp_valhalla)
else
    pkill -9 valhalla_service
fi
