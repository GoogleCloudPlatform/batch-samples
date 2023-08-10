# Batch - tools

This folder contains several shell scripts:

-   `permission_check.sh`: A script that checks if the related permissions and
    the roles are granted well to the user account and service account.
-   `gcloud_event.sh`: A script that fetches the job description related to the
    job name.
-   `cloud_logging.sh`: A script that fetches a specified number of error cloud
    logs related to a search value from Google Cloud Logging.

## Requirements

To run these scripts to diagnose the job, please follow:

-   Open your terminal and navigate to the directory containing the script. And
    make sure they have right permission to run.
-   Ensure that you have set the correct Google Cloud project ID by running the
    command `gcloud config set project <PROJECT_ID>`, where `<PROJECT_ID>` is
    the ID of your intended Google Cloud project.
-   Google Cloud SDK is installed
-   Install jq before running the command. For Ubuntu and Debian user, please
    use `sudo apt-get update` and `sudo apt-get install jq`.

## Usage

### permission_check.sh

To run `permission_check.sh`, use the following command:

`permission_check.sh [-u <USER_EMAIL>] [-s <SERVICE_ACCOUNT>]`

where:

-   `[-u <USER_EMAIL>]` specifies the user account to check (defaults to the
    currently authenticated account if not specified).
-   `[-s <SERVICE_ACCOUNT>]` specifies the service account to check (defaults to
    the Compute Engine default service account for the project if not
    specified).

The script checks that the specified accounts have the necessary permissions and
roles for running GCP batch jobs.

#### Usage Example:

Use the default gce servce account of the project

`permission_check.sh`

Use customized user account and service account

`permission_check.sh -u my_user_account@example.com -s my_service_account`

### gcloud_event.sh

To run `gcloud_event.sh`, use the following command:

`gcloud_event.sh --job-name <JOB_NAME> --location <LOCATION> [--all]`

where:

-   `<JOB_NAME>` is the name of the job you want to search.
-   `[LOCATION]` is the location where the job was run.
-   `[--all]` is an optional flag to get all job descriptions.

#### Usage Example:

Use the job_name and location to extract and highlight the information

`gcloud_event.sh --job-name my-job-name --location us-central1`

Use the flag `--all` to get all job description

`gcloud_event.sh --job-name my-job-name --location us-central1 --all`

### cloud_logging.sh

1.  Make sure your job is writing logs to the cloud logging.
2.  Run the script by typing the following command: `./cloud_logging.sh
    <SEARCH_VALUE> [LOG_NAME] [NUMBER_OF_LOGS]` where:

-   `<SEARCH_VALUE>` is the value you want to search for in the logs.
-   `[LOG_NAME]` is the name of the log (defaults to all logs if not specified).
-   `[NUMBER_OF_LOGS]` is the number of logs to return (defaults to 10 if not.
    specified).

1.  Debug the job with error message provided.

#### Usage Example:

Use `my_job_uid` to search 10 recent related error logs:

`cloud_logging.sh my-job-uid`

#### Additional Resource:

You can also check the
[guidebook](https://cloud.google.com/logging/docs/view/logs-explorer-interface)
guidebook to use command line or the Logs Explorer.

## Future Work

-   `permission_check.sh` can only check individual user account, service
    account and Google group. The permission through Gaia IDs and domain cannot
    be checked.
-   `cloud_logging.sh` the display of the output is in raw format. Improving the
    separation and the display among different logs.
-   As for the maintenance, we should be very careful to control the
    readability and bloated features in the future and may consider using
    other languages.