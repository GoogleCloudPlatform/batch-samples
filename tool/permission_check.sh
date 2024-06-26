#!/bin/bash
#
# Check the related permissions and roles granted to the user account and service account.
# This script can use flags, either -u or --user_email to set the user account, and -s or --service_account to set the service account.
# If the flags are not specified, the default values from the gcloud config will be used.
#
# Need to use "gcloud config set project <PROJECT_ID>" to set up the project_id.
#
# Examples:
#
# Use the default GCE service account of the project
#
# permission_check.sh
#
# Use customized user account and service account
#
# permission_check.sh -u my_user_account@example.com -s my_service_account

#######################################
# Check if the permissions are granted to the user.
# Globals:
#   None
# Arguments:
#   project_id
#   user
#   policy
#   permissions
#######################################
check_permissions() {
  local project_id user policy
  project_id=$1
  user=$2
  local -n permissions_ref=$3
  policy=$4

  # loop through each binding in the IAM policy
  while read -r binding; do
    #Checking if current role is granted to the user
    if echo "$binding" | jq --arg email "$user" '.members[] | select(. == $email)' | grep -q "$user"; then
      local role role_info included_permissions
      role=$(echo "$binding" | jq -r '.role')
      role_info=$(gcloud iam roles describe "$role" --format=json 2>/dev/null)
      if [[ $? -ne 0 ]]; then
        continue
      fi
      included_permissions=$(echo "$role_info" | jq -r '.includedPermissions[]')
      #Iterate all included permissions in current role
      while read -r included_permission; do
        if [[ -n "${permissions_ref[$included_permission]+_}" ]]; then
          #Permission $included_permission found in PERMISSIONS_TO_CHECK"
          if [[ ${permissions_ref[$included_permission]} == 1 ]]; then
            #Permission already checked, skipping
            continue
          else
            #Setting permission $included_permission to checked
            permissions_ref[$included_permission]=1
          fi
        #Permission not found in PERMISSIONS_TO_CHECK
        fi
      done <<<"$included_permissions"
    fi
  done <<<"$(echo "$policy" | jq -c '.bindings[]')"
}

#######################################
# Check if the input email is a service account.
# Globals:
#   None
# Arguments:
#   email
# Outputs:
#   Return 0 if it is a service account
#   Return 1 otherwise
#######################################
is_service_account() {
  local email
  email=$1
  if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.(iam\.gserviceaccount\.com)$ ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Check if the input email is a Google internal account.
# Globals:
#   None
# Arguments:
#   email
# Outputs:
#   Return 1 if it is a Google internal account
#   Return 0 otherwise
#######################################
is_not_internal_account() {
  local email
  email=$1
  if [[ "$email" =~ @google\.com$ ]]; then
    return 1
  else
    return 0
  fi
}

#######################################
# Get user related principles in the policy.
# Globals:
#   None
# Arguments:
#   project_id
#   user
#   policy
#   related_principles
#######################################
get_groups_for_user_in_project() {
  local project_id user policy
  project_id=$1
  user=$2
  policy=$3
  local -n related_principles_ref=$4

  # Fetch IAM policy and extract all groups and users with roles.
  GROUPS_IN_POLICY=($(echo "$policy" \
  | jq -r '.bindings[].members[]' \
  | grep -oE 'group:[^[:space:]]+@[[:graph:]]+' | sort | uniq))

  # Remove the "group:" prefix from each group email address.
  GROUPS_IN_POLICY=($(echo "${GROUPS_IN_POLICY[@]}" | sed -e 's/group://g'))

  # Check if the GROUPS_IN_POLICY variable is empty
  if [[ -z "${GROUPS_IN_POLICY[*]}" ]]; then
    return 1
  fi

  # Loop over each group and check if it contains the specified user.
  for GROUP in "${GROUPS_IN_POLICY[@]}"; do
    if gcloud identity groups memberships check-transitive-membership --group-email="$GROUP" --member-email="$user" --quiet >/dev/null 2>&1; then
      related_principles_ref+=("group:$GROUP")
    fi
  done

  if is_not_internal_account "$email"; then
    return
  fi

  # Fetch IAM policy and extract all groups and users with roles.
  MDB_IN_POLICY=($(echo "$policy" \
  | jq -r '.bindings[].members[]' \
  | grep -oE 'mdb:[[:graph:]]+' | sort | uniq))

  # Remove the "mdb:" prefix from each group name.
  MDB_IN_POLICY=($(echo "${MDB_IN_POLICY[@]}" | sed -e 's/mdb://g'))

  # Check if the MDB_IN_POLICY variable is empty
  if [[ -z "${MDB_IN_POLICY[*]}" ]]; then
    echo "No MDB groups found in policy."
    return 1
  fi

  IDAP=$(echo "$user" | awk -F "@" '{print $1}')

  # Loop over each group and check if it contains the specified user.
  for MDB in "${MDB_IN_POLICY[@]}"; do
    if /google/data/ro/projects/ganpati/aclcheck "mdb/${MDB}" "$IDAP" | grep -q "OK"; then
      related_principles_ref+=("mdb:$MDB")
    fi
  done
}

#######################################
# Check if the user and its related principles are granted well.
# Globals:
#   None
# Arguments:
#   project_id
#   user
#   policy
#   urg_permissions_ref
#######################################
user_related_group_check() {
  local project_id user policy
  project_id=$1
  user=$2
  policy=$3
  local -n urg_permissions_ref=$4

  related_principles=()
  if is_service_account "$user"; then
    related_principles+=(serviceAccount:$user)
  else
    related_principles+=(user:$user)
  fi

  get_groups_for_user_in_project "$project_id" "$user" "$policy" related_principles

  for principle in "${related_principles[@]}"; do
    check_permissions "$project_id" "$principle" urg_permissions_ref "$policy"
  done
}

#######################################
# Check if user's permissions to SA is granted well.
# Globals:
#   None
# Arguments:
#   project_id
#   sa
#   user
#   permissions
#   sa_permissions_ref
#######################################
sa_check_permissions() {
  local project_id sa member
  project_id=$1
  sa=$2
  user=$3
  local -n sa_permissions_ref=$4
  #sa permissions can be granted in different granular -- in sa or in project, so need to check both policies
  P_POLICY=$(gcloud projects get-iam-policy "$project_id" --format json)

  user_related_group_check "$project_id" "$user" "$P_POLICY" sa_permissions_ref

  if ! IAM_BINDINGS=$(gcloud iam service-accounts get-iam-policy "$sa" --format json | jq -c '.bindings[]' 2>/dev/null); then
    return
  fi

  S_POLICY=$(gcloud iam service-accounts get-iam-policy "$sa" --format json)

  user_related_group_check "$project_id" "$user" "$S_POLICY" sa_permissions_ref

  return 0
}

# Set the project name
PROJECT_NAME=$(gcloud config get-value project)
echo "Checking the project: $PROJECT_NAME"

# Set the default user email and service account
USER_EMAIL="$(gcloud config get-value account)"
SA="$(gcloud compute project-info describe --project "${PROJECT_NAME}" --format='value(defaultServiceAccount)')"

# Check for flags to set the values of user_email and service_account
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -u | --user_email)
    USER_EMAIL="$2"
    shift # past argument
    shift # past value
    ;;
  -s | --service_account)
    SA="$2"
    shift # past argument
    shift # past value
    ;;
  *)
    echo "Unknown option: $key"
    exit 1
    ;;
  esac
done

echo "Checking the account: $USER_EMAIL"
echo "Checking the service account: $SA"

# Get the project id of the service account
SA_PROJECT=$(gcloud iam service-accounts describe "$SA" --format='value(projectId)')
echo "Checking the service account project: $SA_PROJECT"

# Define an array of roles
USER_ROLES=("roles/batch.jobsEditor")
USER_SA_ROLES=("roles/iam.serviceAccountUser")
OP_USER_ROLES=("roles/storage.objectViewer" "roles/compute.viewer")
SA_ROLES=("roles/batch.agentReporter")
OP_SA_ROLES=("roles/storage.admin" "roles/logging.logWriter")

# Define arrays to store the related permissions
declare -A USER_PERMISSIONS_TO_CHECK
declare -A USER_SA_PERMISSIONS_TO_CHECK
declare -A OP_USER_PERMISSIONS_TO_CHECK
declare -A SA_PERMISSIONS_TO_CHECK
declare -A OP_SA_PERMISSIONS_TO_CHECK

declare -A PERMISSIONS_TO_ROLE

# Store the iam policy of the project
IAM_POLICY=$(gcloud projects get-iam-policy "$PROJECT_NAME" --format json)

# Loop through the users roles array
for role in "${USER_ROLES[@]}"; do
  # Get the permissions of the role
  role_permissions=$(gcloud iam roles describe "$role" --format=json | jq -r '.includedPermissions[]')

  while read -r p; do
    USER_PERMISSIONS_TO_CHECK["$p"]=0
    PERMISSIONS_TO_ROLE["$p"]="$role"
  done <<<"$role_permissions"
done

# Loop through the users/sa roles array
for role in "${USER_SA_ROLES[@]}"; do
  # Get the permissions of the role
  role_permissions=$(gcloud iam roles describe "$role" --format=json | jq -r '.includedPermissions[]')

  while read -r p; do
    USER_SA_PERMISSIONS_TO_CHECK["$p"]=0
    PERMISSIONS_TO_ROLE["$p"]="$role"
  done <<<"$role_permissions"
done

# Loop through the users optional roles array
for role in "${OP_USER_ROLES[@]}"; do
  role_permissions=$(gcloud iam roles describe "$role" --format=json | jq -r '.includedPermissions[]')

  while read -r p; do
    OP_USER_PERMISSIONS_TO_CHECK["$p"]=0
    PERMISSIONS_TO_ROLE["$p"]="$role"
  done <<<"$role_permissions"
done

# Loop through the service account roles array
for role in "${SA_ROLES[@]}"; do
  role_permissions=$(gcloud iam roles describe "$role" --format=json | jq -r '.includedPermissions[]')

  while read -r p; do
    SA_PERMISSIONS_TO_CHECK["$p"]=0
    PERMISSIONS_TO_ROLE["$p"]="$role"
  done <<<"$role_permissions"
done

# Loop through the service account optional roles array
for role in "${OP_SA_ROLES[@]}"; do
  role_permissions=$(gcloud iam roles describe "$role" --format=json | jq -r '.includedPermissions[]')

  while read -r p; do
    OP_SA_PERMISSIONS_TO_CHECK["$p"]=0
    PERMISSIONS_TO_ROLE["$p"]="$role"
  done <<<"$role_permissions"
done

echo "************************************* Checking the user:$USER_EMAIL permission *************************************"
echo ""
# Initialize an empty array to store the results
missing_permissions=()

user_related_group_check "$project_id" "$USER_EMAIL" "$IAM_POLICY" USER_PERMISSIONS_TO_CHECK

for permission in "${!USER_PERMISSIONS_TO_CHECK[@]}"; do
  if [[ ${USER_PERMISSIONS_TO_CHECK[$permission]} == 0 ]]; then
    missing_permissions+=("$permission")
  fi
done

# Print the missing permissions
if [[ ${#missing_permissions[@]} -eq 0 ]]; then
  echo "All required permissions are granted for user email"
  echo ""
else
  echo "The following permissions are missing for user email $USER_EMAIL:"
  echo ""
  for permission in "${missing_permissions[@]}"; do
    echo "- ""$permission"" (related role: ""${PERMISSIONS_TO_ROLE[$permission]}"" )"
  done
  echo ""
  echo "Please check the guidebook to make sure all required roles granted: https://cloud.google.com/batch/docs/get-started#user-prerequisites"
  echo ""
fi

missing_permissions=()

sa_check_permissions "$SA_PROJECT" "$SA" "$USER_EMAIL" USER_SA_PERMISSIONS_TO_CHECK

for permission in "${!USER_SA_PERMISSIONS_TO_CHECK[@]}"; do
  if [[ ${USER_SA_PERMISSIONS_TO_CHECK[$permission]} == 0 ]]; then
    missing_permissions+=("$permission")
  fi
done

# Print the missing permissions
if [[ ${#missing_permissions[@]} -eq 0 ]]; then
  echo "All required service account permissions are granted for user email"
  echo ""
else
  echo "These permissions are required for user email $USER_EMAIL to access the service account $SA:"
  echo ""
  for permission in "${missing_permissions[@]}"; do
    echo "- ""$permission"" (related role: ""${PERMISSIONS_TO_ROLE[$permission]}"" )"
  done
  echo ""
  echo "Please check the guidebook to make sure all required roles granted: https://cloud.google.com/batch/docs/create-run-job-custom-service-account#before-you-begin"
  echo ""
fi

missing_permissions=()

user_related_group_check "$project_id" "$USER_EMAIL" "$IAM_POLICY" OP_USER_PERMISSIONS_TO_CHECK

for permission in "${!OP_USER_PERMISSIONS_TO_CHECK[@]}"; do
  if [[ ${OP_USER_PERMISSIONS_TO_CHECK[$permission]} == 0 ]]; then
    missing_permissions+=("$permission")
  fi
done

# Print the missing permissions
if [[ ${#missing_permissions[@]} -eq 0 ]]; then
  echo "All optional permissions are granted for user email"
  echo ""
else
  echo "These permissions are required for user email $USER_EMAIL when accessing GCS or from Compute Engine:"
  echo ""
  for permission in "${missing_permissions[@]}"; do
    echo "- ""$permission"" (related role: ""${PERMISSIONS_TO_ROLE[$permission]}"" )"
  done
  echo "Please check the guidebook to make sure all required roles granted: https://cloud.google.com/batch/docs/create-run-job-storage#before-you-begin and https://cloud.google.com/batch/docs/create-run-job-vm-template#before-you-begin"
  echo ""
fi

echo "************************************* Checking the service account:$SA permission *************************************"
echo ""
# Initialize an empty array to store the results
missing_permissions=()

user_related_group_check "$project_id" "$SA" "$IAM_POLICY" SA_PERMISSIONS_TO_CHECK

for permission in "${!SA_PERMISSIONS_TO_CHECK[@]}"; do
  if [[ ${SA_PERMISSIONS_TO_CHECK[$permission]} == 0 ]]; then
    missing_permissions+=("$permission")
  fi
done

# Print the missing permissions
if [[ ${#missing_permissions[@]} -eq 0 ]]; then
  echo "All required permissions are granted for service account"
  echo ""
else
  echo "The following permissions are missing for service account $SA:"
  echo ""
  for permission in "${missing_permissions[@]}"; do
    echo "- ""$permission"" (related role: ""${PERMISSIONS_TO_ROLE[$permission]}"" )"
  done
  echo "Please check the guidebook to make sure all required roles granted: https://cloud.google.com/batch/docs/get-started#project-prerequisites"
  echo ""
fi

# Initialize an empty array to store the results
missing_permissions=()

user_related_group_check "$project_id" "$SA" "$IAM_POLICY" OP_SA_PERMISSIONS_TO_CHECK

for permission in "${!OP_SA_PERMISSIONS_TO_CHECK[@]}"; do
  if [[ ${OP_SA_PERMISSIONS_TO_CHECK[$permission]} == 0 ]]; then
    missing_permissions+=("$permission")
  fi
done

# Print the missing permissions
if [[ ${#missing_permissions[@]} -eq 0 ]]; then
  echo "All optional permissions are granted for service account"
  echo ""
else
  echo "These permissions are required for service account $SA when accessing GCS or write cloud logging:"
  echo ""
  for permission in "${missing_permissions[@]}"; do
    echo "- ""$permission"" (related role: ""${PERMISSIONS_TO_ROLE[$permission]}"" )"
  done
  echo "Please check the guidebook to make sure all required roles granted: https://cloud.google.com/batch/docs/get-started#project-prerequisites"
  echo ""
fi

