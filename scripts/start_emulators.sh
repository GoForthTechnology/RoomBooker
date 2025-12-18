#!/bin/bash

DATA_DIR="emulators_data"

echo "Starting Emulators"

fireabase emulators:start --import $DATA_DIR --export-on-exit $DATA_DIR