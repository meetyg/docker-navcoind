#!/bin/sh

set -ex

# Generate navcoin.conf
gosu navcoin nav_init

# Run navcoin daemon
gosu navcoin navcoind -conf=/navcoin/.navcoin4/navcoin.conf -ntpminmeasures=0

#gosu navcoin tail -F /navcoin/.navcoin4/debug.log

apache2-foreground
