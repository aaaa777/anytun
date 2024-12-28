#!/bin/zsh

SCRIPT_DIR=$(dirname "$0")
cd $SCRIPT_DIR

pkill -f anytund.sh
./anytund.sh &
