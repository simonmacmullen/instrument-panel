#!/bin/sh -e
DEVICE=$1
[ "$DEVICE" = "" ] && DEVICE=fenix3

RESOURCE_PATH=$(find . -path './resources*.xml' | xargs | tr ' ' ':')
monkeyc -o bin/instrument-panel.prg -d $DEVICE -m manifest.xml -z $RESOURCE_PATH src/*.mc
