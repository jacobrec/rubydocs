#!/bin/sh
APPNAME=rubydocs
PORT=4567
docker build -t $APPNAME .
docker run -p $PORT:80 -it $APPNAME
