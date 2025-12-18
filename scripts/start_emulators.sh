#!/bin/bash

DATA_DIR="emulators_data"

echo "Starting Emulators"

firebase emulators:start --import $DATA_DIR --export-on-exit $DATA_DIR