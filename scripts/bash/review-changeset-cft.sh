#!/bin/bash

# Variables
STACK_NAME=$1
CHANGE_SET_NAME=$2
AWS_REGION=$3

echo "Reviewing the ${STACK_NAME} stack change set ${CHANGE_SET_NAME} ..."

# Get the change set description
describe_change_set_output=$(aws cloudformation describe-change-set \
  --stack-name "${STACK_NAME}" \
  --change-set-name "${CHANGE_SET_NAME}" \
  --region "${AWS_REGION}" 2>&1)

# Check if the command succeeded
if [[ $? -eq 0 ]]; then
  echo "Change set exists. Continuing with the the review process..."
  
else
  # Check if the error indicates the change set doesn't exist
  if echo "$describe_change_set_output" | grep -q "ChangeSetNotFound"; then
    echo "Change set does not exist. Exiting script."
    exit 1
  else
    echo "An error occurred: $describe_change_set_output"
    exit 1
  fi
fi

# Parse the status and status reason from the output
status=$(echo "$describe_change_set_output" | jq -r '.Status')
status_reason=$(echo "$describe_change_set_output" | jq -r '.StatusReason')

echo "The current status is status with $status reason $status_reason"

# Check if the status is "FAILED" and the reason matches
if [[ "$status" == "FAILED" && "$status_reason" == "The submitted information didn't contain changes. Submit different information to create a change set." ]]; then
  echo "The change set ${CHANGE_SET_NAME} status is FAILED since $status_reason"
  echo "Hence, Deleting the stack set..."

  # Delete the change set
  aws cloudformation delete-change-set \
    --stack-name "${STACK_NAME}" \
    --change-set-name "${CHANGE_SET_NAME}" \
    --region "${AWS_REGION}"

  if [ $? -eq 0 ]; then
    echo "Stack set deleted successfully."
  else
    echo "Failed to delete the stack set."
  fi
else
  echo "There is a valid change set ${CHANGE_SET_NAME}. Hence continuing..."
fi
