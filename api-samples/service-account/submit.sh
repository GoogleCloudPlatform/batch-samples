#!/bin/bash

# Export all variables.
set -o allexport

# Common variables.
source ../env.sh

# UPDATE TO MATCH YOUR SETTINGS.
# Variables for this sample.
# -----------------------------------------
# Service account with valid permissions.
ServiceAccountEmail=SERVICE_ACCOUNT_EMAIL
# Instance template with valid service account.
InstanceTemplateWithSA=INSTANCE_TEMPLATE_NAME

# Turn OFF the allexport option
set +o allexport

gcloud batch jobs submit --job-prefix=service-account --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$ServiceAccountEmail','$InstanceTemplateWithSA' < ./template_with_a_sa.json)
EOF

gcloud batch jobs submit --job-prefix=service-account --location=${Location} --project=${ProjectID} --config - <<EOF
$(envsubst '$ServiceAccountEmail' < ./job_with_a_sa.json)
EOF