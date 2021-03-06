#!/bin/bash

set -e -x -o pipefail

# $1: scala version  (e.g. "2.11")
# $2: hadoop version (e.g. "2.6")
function docker_version() {
    echo "${SPARK_BUILD_VERSION}-scala-$1-hadoop-$2"
}

function default_hadoop_version {
    jq -r ".default_spark_dist.hadoop_version" "${SPARK_BUILD_DIR}/manifest.json"
}

function default_scala_version {
    jq -r ".default_spark_dist.scala_version" "${SPARK_BUILD_DIR}/manifest.json"
}

function publish_docker_images() {
    local NUM_SPARK_DIST=$(jq ".spark_dist | length" manifest.json)
    local NUM_SPARK_DIST=$(expr ${NUM_SPARK_DIST} - 1)
    for i in $(seq 0 ${NUM_SPARK_DIST});
    do
        local SCALA_VERSION=$(jq -r ".spark_dist[${i}].scala_version" manifest.json)
        local HADOOP_VERSION=$(jq -r ".spark_dist[${i}].hadoop_version" manifest.json)
        make docker-dist \
            -e SPARK_DIST_URI=$(jq -r ".spark_dist[${i}].uri" manifest.json) \
            -e DOCKER_DIST_IMAGE="${DOCKER_DIST_IMAGE}:$(docker_version ${SCALA_VERSION} ${HADOOP_VERSION})"
        rm docker-dist # delete the docker-dist make target to clean
        make clean-dist
    done
}


function make_universe() {
    DOCKER_VERSION=$(docker_version $(default_scala_version) $(default_hadoop_version))

    make spark-dist-download # use default manifest spark dist
    make stub-universe-url -e DOCKER_DIST_IMAGE=${DOCKER_DIST_IMAGE}:${DOCKER_VERSION}
}

function write_properties() {
  cp "${WORKSPACE}/stub-universe.properties" ../build.properties
  echo "RELEASE_VERSION=${SPARK_BUILD_VERSION}" >> ../build.properties
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPARK_BUILD_DIR=${DIR}/..
SPARK_BUILD_VERSION=${SPARK_BUILD_VERSION:-${GIT_BRANCH#origin/tags/}}

pushd "${SPARK_BUILD_DIR}"
make docker-login
publish_docker_images
make_universe
write_properties
popd
