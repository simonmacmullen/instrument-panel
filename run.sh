#!/bin/sh -e
DEVICE=$1
[ "$DEVICE" = "" ] && DEVICE=fenix3_sim

killall simulator || true
connectiq
./build.sh $DEVICE
monkeydo bin/instrument-panel.prg $DEVICE
