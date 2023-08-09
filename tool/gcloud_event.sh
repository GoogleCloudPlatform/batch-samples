#!/bin/bash
#
# Fetch the job description, extract and highlight the OPERATIONAL_INFO.
#
# gcloud_event.sh --job-name <JOB_NAME> --location <LOCATION>
#
# Need to use "gcloud config set project <PROJECT_ID>" to set up the project_id.
#
# Examples:
#
# Use the job_name and location to extract and highlight the information
#
# gcloud_event.sh --job-name my-job-name --location us-central1
#
# Use the flag --all to get all job description
#
# gcloud_event.sh --job-name my-job-name --location us-central1 --all

# Parse the flags
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  --job-name)
    job_name="$2"
    shift # past argument
    shift # past value
    ;;
  --location)
    location="$2"
    shift # past argument
    shift # past value
    ;;
  *)      # unknown option
    shift # past argument
    ;;
  esac
done

# Check if the required flags were passed
if [[ -z "$job_name" ]] || [[ -z "$location" ]]; then
  echo "Missing required flag(s)"
  echo "Usage: $0 --job-name JOB_NAME --location LOCATION [--all]"
  exit 1
fi

if [[ "$all" = true ]]; then
  gcloud batch jobs describe "$job_name" --location "$location" --format=json
  exit 0
fi

# Run the gcloud command and save the output to a variable
output=$(gcloud batch jobs describe "$job_name" --location "$location" --format=json)

# Check the exit code of the gcloud command
if [[ "$?" -ne 0 ]]; then
  echo "Error running gcloud command"
  exit 1
fi

# Use jq to parse the JSON output and extract the statusEvents field
status_events=$(echo "$output" | jq -r '.status.statusEvents')

# highlight the error keyword
echo "$status_events" | grep --color='\033[1;31m' -i 'OPERATIONAL_INFO'

echo "Done"