#!/bin/bash

VOLUME=keystore
BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOSTIP=127.0.0.1

docker volume inspect $VOLUME 2>&1 >/dev/null
rc=$?
  if [ $rc -eq 0 ]
  then
    docker volume rm ${VOLUME}
    rc=$?
      if [ $rc -eq 0 ]
      then
        echo "${VOLUME} deleted."
      fi
  else
    echo "${VOLUME} not deleted."
  fi