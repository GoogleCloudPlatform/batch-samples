#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# Turn OFF the allexport option
set +o allexport

gcloud builds submit --project="${ProjectID}" --config=batch_debian_image.yaml .
