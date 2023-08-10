#!/bin/bash
#
# Fetch [NUMBER_OF_LOGS] of the error cloud logging related to the search value.
#
# cloud_logging.sh <SEARCH_VALUE> [NUMBER_OF_LOGS]
#
# Need to use "gcloud config set project <PROJECT_ID>" to set up the project_id.
#
# If need to search less severe logs or specify the log name, please check the guidebook below and use the Logs Explorer
# https://cloud.google.com/logging/docs/view/logs-explorer-interface
#
# Examples:
#
# Use the my_job_uid to search 10 recent related error logs
#
# cloud_logging.sh my-job-uid

# Check if a value was passed as an argument
if [[ -z "$1" ]]; then
  echo "Missing required argument: search value"
  echo "Usage: $0 search_value [log_name] [number_of_logs]"
  exit 1
fi

# Define the value to search for
value="$1"
log_name="my-log"
if [[ -n "$2" ]]; then
  log_name="$2"
fi

# Define the number of logs to return
log_num="10"
if [[ -n "$2" ]]; then
  log_num="$2"
fi

# Run the gcloud logging read command to query logs
output=$(gcloud logging read "$value AND severity=(ERROR OR CRITICAL OR ALERT OR EMERGENCY)" --limit="$log_num" --format='json')

# Check the exit code of the gcloud command
if [[ "$?" -ne 0 ]]; then
  echo "Error running gcloud command"
  exit 1
fi

# Print the output
echo "$output"