#!/bin/bash

VOLUME=keystore
BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOSTIP=127.0.0.1

docker volume inspect $VOLUME 2>&1 >/dev/null
rc=$?
  if [ $rc -ne 0 ]
  then
    docker volume create --name ${VOLUME}
    # Generate keystore
    docker run \
      -v ${VOLUME}:/tmp/keystore \
      -v ${BIN_DIR}/gen-keystore.sh:/tmp/gen-keystore.sh \
      -w /tmp --rm ibmjava bash ./gen-keystore.sh ${HOSTIP}
    echo "${VOLUME} created."
  else
    echo "${VOLUME} already created."
  fi