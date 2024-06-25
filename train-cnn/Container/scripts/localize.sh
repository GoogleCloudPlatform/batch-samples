#!/bin/bash

# Pull the partial archives from the Filestore
echo "-- Localizing training data... --"
for i in $(seq 0 99); do
    cp $DATA_ROOT/bin$i.zip /tmp
done

# Inflate the partial archives into train/{cats,dogs}/{index}.jpg
for i in in $(seq 0 99); do
    unzip /tmp/bin$i.zip -d /tmp
done
echo "-- Localization done. --"
