#!/bin/bash

# Set variables
STACK_NAME=$1
CHANGE_SET_NAME=$2
AWS_REGION=$3
ENVIRONMENT=$4
LAMBDA_ZIP_FILE=$5
POLLING_INTERVAL=30  # Poll every 30 seconds
TIMEOUT=600  # Set timeout for 10 minutes (600 seconds)

# Polling function to check stack status
poll_stack_status() {
    local ELAPSED_TIME=0

    while true; do
        # Get current stack status
        STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query 'Stacks[0].StackStatus' --output text)
        echo "Current status of $STACK_NAME: $STATUS"

        # Check if stack update is complete or failed
        if [[ "$STATUS" == "CREATE_COMPLETE" ]]; then
            echo "$STACK_NAME create complete."
            break
        elif [[ "$STATUS" == "UPDATE_COMPLETE" ]]; then
            echo "$STACK_NAME update complete."
            break
        elif [[ "$STATUS" == "UPDATE_FAILED" || "$STATUS" == "ROLLBACK_COMPLETE" ]]; then
            echo "Stack $STACK_NAME update failed or rolled back."
            exit 1
        fi

        # Check if the timeout has been reached
        if [[ $ELAPSED_TIME -ge $TIMEOUT ]]; then
            echo "Timeout reached while waiting for $STACK_NAME update."
            exit 1
        fi

        # Wait before polling again
        echo "Waiting for $STACK_NAME update to complete..."
        sleep $POLLING_INTERVAL

        # Increment elapsed time
        ELAPSED_TIME=$((ELAPSED_TIME + POLLING_INTERVAL))
    done
}

# Get the change set description
describe_change_set_output=$(aws cloudformation describe-change-set \
  --stack-name "${STACK_NAME}" \
  --change-set-name "${CHANGE_SET_NAME}" \
  --region "${AWS_REGION}" 2>&1)

# Check if the command succeeded
if [[ $? -eq 0 ]]; then
  echo "Change set ${CHANGE_SET_NAME} exists. Continuing with the script..."
  
else
  # Check if the error indicates the change set doesn't exist
  if echo "$describe_change_set_output" | grep -q "ChangeSetNotFound"; then
    echo "Change set ${CHANGE_SET_NAME} does not exist. No action taken. Exiting script."
    exit 0
  else
    echo "An error occurred: $describe_change_set_output"
    exit 1
  fi
fi

# Execute and wait for stack change set
echo "Executing the change set $CHANGE_SET_NAME of stack $STACK_NAME ..."
aws cloudformation execute-change-set --stack-name $STACK_NAME --change-set-name $CHANGE_SET_NAME --region $AWS_REGION

echo "Waiting for network stack update to complete..."
# Wait for the stack to update or poll manually
poll_stack_status $STACK_NAME

