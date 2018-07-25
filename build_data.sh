#!/bin/bash

# Variables
BUILD_ALL=false
BUILD_ADMINS=false
BUILD_CONFIG=false
BUILD_TILES=false
BUILD_TILES_TAR=false
BUILD_TIMEZONES=false
BUILD_TRANSIT=false
CLEAN_DATA=false
CONFIG_FILE="config.json"
DATASTORE_URL="http://localhost:8004"
DATA_DIR="/data/valhalla"
OSM_FILE="portugal-latest.osm.pbf"
OSM_FILE_URL="http://download.geofabrik.de/europe/portugal-latest.osm.pbf"
TRANSIT_BBOX="-31.56,29.89,-6.18,42.23"
WITH_DOCKER=false

for arg in "$@"; do
  shift
  case "$arg" in
    --all) BUILD_ADMINS=true BUILD_CONFIG=true \
           BUILD_TILES=true BUILD_TILES_TAR=true \
           BUILD_TRANSIT=true BUILD_TIMEZONES=true ;;
    --build-admins) BUILD_ADMINS=true ;;
    --build-config) BUILD_CONFIG=true ;;
    --build-tiles) BUILD_TILES=true ;;
    --build-tiles-tar) BUILD_TILES_TAR=true ;;
    --build-timezones) BUILD_TIMEZONES=true ;;
    --build-transit) BUILD_TRANSIT=true ;;
    --clean-data) CLEAN_DATA=true ;;
    --config-file=*) CONFIG_FILE="${arg#*=}" ;;
    --datastore-url=*) DATASTORE_URL="${arg#*=}" ;;
    --data-dir=*) DATA_DIR="${arg#*=}" ;;
    --osm-file=*) OSM_FILE="${arg#*=}" ;;
    --osm-file-url=*) OSM_FILE_URL="${arg#*=}";;
    --transit-bbox=*) TRANSIT_BBOX="${arg#*=}" ;;
    --with-docker) WITH_DOCKER=true ;;
    --help|-h|*) echo "Usage: ./build_data.sh [OPTIONS]"
              echo "Available options:"
              echo "  --all                 All --build-* options true. False if ommited."
              echo "  --build-admins        Build admins DB. False if ommited."
              echo "  --build-config        Build config file. False if ommited."
              echo "  --build-tiles         Build routing tiles. False if ommited."
              echo "  --build-tiles-tar     Build tiles tar. False if ommited."
              echo "  --build-timezones     Build timezones DB. False if ommited."
              echo "  --build-transit       Fetch and build transit tiles. False if ommited."
              echo "  --clean-data          Cleanup files in data dir. False if ommited."
              echo "  --config-file=FILE    Path to config file. Default is config.json"
              echo "  --datastore-url=URL   URL of the Datastore API. Default is http://localhost:8004"
              echo "  --data-dir=DIR        Path to Valhalla data dir. Default is /data/valhalla."
              echo "                        Will be mounted as a volume if --with-docker."
              echo "  --osm-file=FILE       Path to OSM .pbf file. Default is portugal-latest.osm.pbf"
              echo "  --osm-file-url=URL    URL to OSM .pbf file. Default is"
              echo "                          http://download.geofabrik.de/europe/portugal-latest.osm.pbf"
              echo "  --transit-bbox=BBOX   Only get transit tiles for given bounding box. Default is"
              echo "                          -31.56,29.89,-6.18,42.23, which is Portugal."
              echo "  --with-docker         Build with docker. False if ommited."
              echo "  --help, -h            Show this message"
    exit ;;
  esac
done

# Custom Values for Valhalla Configuration
CONFIG_COMMON="--loki-service-defaults-minimum-reachability 50 \
--meili-default-breakage-distance 3000 \
--meili-default-interpolation-distance 15 \
--meili-default-max-route-distance-factor 50 \
--meili-default-max-route-time-factor 50 \
--meili-default-max-search-radius 1000 \
--meili-default-search-radius 500 \
--meili-mode multimodal \
--meili-multimodal-turn-penalty-factor 0 \
--meili-pedestrian-turn-penalty-factor 10 \
--meili-pedestrian-search-radius 500 \
--meili-verbose true \
--mjolnir-max-cache-size 10000000000 \
--service-limits-bus-max-locations 50000 \
--service-limits-bus-max-matrix-locations 5000 \
--service-limits-isochrone-max-distance 1500000.0 \
--service-limits-isochrone-max-time 6400 \
--service-limits-max-radius 10000 \
--service-limits-max-reachability 1000000 \
--service-limits-multimodal-max-distance 5000000.0 \
--service-limits-multimodal-max-locations 50000 \
--service-limits-pedestrian-max-locations 50000 \
--service-limits-pedestrian-max-matrix-locations 5000 \
--service-limits-skadi-min-resample 5.0 \
--service-limits-trace-max-best-paths-shape 1000 \
--service-limits-trace-max-shape 32000 \
--service-limits-trace-max-distance 500000.0 \
--service-limits-trace-max-search-radius 10000.0 \
--service-limits-transit-max-distance 5000000.0 \
--service-limits-transit-max-locations 50000 \
--service-limits-transit-max-matrix-locations 5000 \
--thor-logging-long-request 1100.0"

# Change data dir location in config depending on type of build
if [ $WITH_DOCKER = true ]
then
CONFIG_DIRS="--additional-data-elevation /data/valhalla/elevation/ \
--mjolnir-admin /data/valhalla/admin.sqlite \
--mjolnir-timezone /data/valhalla/tz_world.sqlite \
--mjolnir-tile-dir /data/valhalla/tiles \
--mjolnir-tile-extract /data/valhalla/tiles.tar \
--mjolnir-transit-dir /data/valhalla/transit"
else
CONFIG_DIRS="--additional-data-elevation ${DATA_DIR}/elevation/ \
--mjolnir-admin ${DATA_DIR}/admin.sqlite \
--mjolnir-timezone ${DATA_DIR}/tz_world.sqlite \
--mjolnir-tile-dir ${DATA_DIR}/tiles \
--mjolnir-tile-extract ${DATA_DIR}/tiles.tar \
--mjolnir-transit-dir ${DATA_DIR}/transit"
fi

# Command list
docker_run="docker run"
volume1="-v ${DATA_DIR}:/data/valhalla"
docker_image="tpportugal/tpp_valhalla:latest"
cmd_build_config="bash -c \"valhalla_build_config ${CONFIG_COMMON} ${CONFIG_DIRS} > ${CONFIG_FILE}\""
cmd_build_timezones="valhalla_build_timezones ${CONFIG_FILE} "
cmd_build_admins="valhalla_build_admins -c ${CONFIG_FILE} ${OSM_FILE}"
cmd_build_transit="valhalla_build_transit ${CONFIG_FILE} ${DATASTORE_URL} \
100 transit ${TRANSIT_BBOX} 4"
cmd_build_tiles="valhalla_build_tiles -c ${CONFIG_FILE} ${OSM_FILE}"
cmd_build_tiles_tar="bash -c \"find tiles | sort -n | tar cf tiles.tar --no-recursion -T -\""
cmd_chown_data="chown -R ${UID} /data/valhalla"

# Switch to data dir - Exit script if it fails
cd "${DATA_DIR}" || { echo "${DATA_DIR} not found. Please create it before" \
                         "running this script again" && exit 1; }

#Cleanup data dir before anything else runs, if requested
if [[ $CLEAN_DATA = true && "${PWD}" = "${DATA_DIR}" ]]
then
  rm -rf *
fi

# Download OSM file if it doesn't exist or was updated
echo "############################################"
echo "# Check OSM file and download it if needed #"
echo "############################################"
echo "wget --timestamping --backups=1 ${OSM_FILE_URL}"
wget --timestamping --backups=1 "${OSM_FILE_URL}"
echo "#####################"
echo "# OSM file is ready #"
echo "#####################"

if [ $WITH_DOCKER = true ]
then
  if [ $BUILD_CONFIG = true ]
  then
    echo "#########################"
    echo "# Building config file. #"
    echo "#########################"
    echo "$docker_run $volume1 $docker_image $cmd_build_config"
    eval $docker_run $volume1 $docker_image $cmd_build_config
    echo "##############################"
    echo "# Building config file done. #"
    echo "##############################"
  fi
  if [ $BUILD_TIMEZONES = true ]
  then
    echo "##########################"
    echo "# Building Timezones DB. #"
    echo "##########################"
    echo "$docker_run $volume1 $docker_image $cmd_build_timezones"
    eval $docker_run $volume1 $docker_image $cmd_build_timezones
    echo "###############################"
    echo "# Building Timezones DB done. #"
    echo "###############################"
  fi
  if [ $BUILD_ADMINS = true ]
  then
    echo "#######################"
    echo "# Building Admins DB. #"
    echo "#######################"
    echo "$docker_run $volume1 $docker_image $cmd_build_admins"
    eval $docker_run $volume1 $docker_image $cmd_build_admins
    echo "############################"
    echo "# Building Admins DB done. #"
    echo "############################"
  fi
  if [ $BUILD_TRANSIT = true ]
  then
    echo "#####################"
    echo "# Building Transit. #"
    echo "#####################"
    echo "$docker_run $volume1 $docker_image $cmd_build_transit"
    eval $docker_run $volume1 $docker_image $cmd_build_transit
    echo "##########################"
    echo "# Building Transit done. #"
    echo "##########################"
  fi
  if [ $BUILD_TILES = true ]
  then
    echo "###################"
    echo "# Building Tiles. #"
    echo "###################"
    echo "$docker_run $volume1 $docker_image $cmd_build_tiles"
    eval $docker_run $volume1 $docker_image $cmd_build_tiles
    echo "########################"
    echo "# Building Tiles done. #"
    echo "########################"
  fi
  if [ $BUILD_TILES_TAR = true ]
  then
    echo "############################"
    echo "# Building Tiles Tar file. #"
    echo "############################"
    echo "$docker_run $volume1 $docker_image $cmd_build_tiles_tar"
    eval $docker_run $volume1 $docker_image $cmd_build_tiles_tar
    echo "#################################"
    echo "# Building Tiles Tar file done. #"
    echo "#################################"
  fi
  eval $docker_run $volume1 $docker_image $cmd_chown_data
else
  if [ $BUILD_CONFIG = true ]
  then
    echo "#########################"
    echo "# Building config file. #"
    echo "#########################"
    echo "$cmd_build_config"
    eval $cmd_build_config
    echo "##############################"
    echo "# Building config file done. #"
    echo "##############################"
  fi
  if [ $BUILD_TIMEZONES = true ]
  then
    echo "##########################"
    echo "# Building Timezones DB. #"
    echo "##########################"
    echo "$cmd_build_timezones"
    eval $cmd_build_timezones
    echo "###############################"
    echo "# Building Timezones DB done. #"
    echo "###############################"
  fi
  if [ $BUILD_ADMINS = true ]
  then
    echo "#######################"
    echo "# Building Admins DB. #"
    echo "#######################"
    echo "$cmd_build_admins"
    eval $cmd_build_admins
    echo "############################"
    echo "# Building Admins DB done. #"
    echo "############################"
  fi
  if [ $BUILD_TRANSIT = true ]
  then
    echo "#####################"
    echo "# Building Transit. #"
    echo "#####################"
    echo "$cmd_build_transit"
    eval $cmd_build_transit
    echo "##########################"
    echo "# Building Transit done. #"
    echo "##########################"
  fi
  if [ $BUILD_TILES = true ]
  then
    echo "###################"
    echo "# Building Tiles. #"
    echo "###################"
    echo "$cmd_build_tiles"
    eval $cmd_build_tiles
    echo "########################"
    echo "# Building Tiles done. #"
    echo "########################"
  fi
  if [ $BUILD_TILES_TAR = true ]
  then
    echo "############################"
    echo "# Building Tiles Tar file. #"
    echo "############################"
    echo "$cmd_build_tiles_tar"
    eval $cmd_build_tiles_tar
    echo "#################################"
    echo "# Building Tiles Tar file done. #"
    echo "#################################"
  fi
fi
