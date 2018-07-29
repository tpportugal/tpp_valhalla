#!/bin/bash
WITH_DOCKER=false
for arg in "$@"; do
  shift
  case "$arg" in
    --with-docker) WITH_DOCKER=true ;;
    --help|-h|*) echo "Usage: ./stop.sh [OPTIONS]"
              echo "Available options:"
              echo "  --with-docker       Build with docker. False if ommited."
              echo "  --help, -h          Show this message"
    exit ;;
  esac
done

if [ $WITH_DOCKER = true ]; then
  docker stop $(docker ps -q --filter ancestor=tpportugal/tpp_valhalla)
else
    pkill -9 valhalla_service
fi
