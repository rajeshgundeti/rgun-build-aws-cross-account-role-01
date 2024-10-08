#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

STACK_NAME="$1"
CHANGE_SET_NAME="$2"
ENVIRONMENT="$3"
AWS_REGION="$4"

# Function to create change set 
create_change_set() {
    #STACK_STATUS=`aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query 'Stacks[0].StackStatus' --output text`
    # Check if the stack exists
    if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "Stack $STACK_NAME does not exist, creating a new stack."
        echo "The parameter file is $PARAMETERS_FILE"

        # Create the stack if it doesn't exist
        aws cloudformation create-change-set \
          --stack-name "$STACK_NAME"\
          --template-body file://cloudformation/"$STACK_NAME".yml \
          --parameters file://parameters/"${ENVIRONMENT}-${STACK_NAME}"-parameters.json \
          --change-set-name "$CHANGE_SET_NAME" \
          --capabilities CAPABILITY_NAMED_IAM \
          --region "$AWS_REGION" \
          --change-set-type CREATE

        return
    else
        # Stack exists
        STACK_STATUS=`aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query 'Stacks[0].StackStatus' --output text`
        if [ $STACK_STATUS == "REVIEW_IN_PROGRESS" ]; then
          echo "Stack $STACK_NAME exist, The status is $STACK_STATUS .  Complete the pending change set review of the stack."
          exit 1
        elif [ $STACK_STATUS == "ROLLBACK_COMPLETE" ]; then
          echo "Stack $STACK_NAME exist, The status is $STACK_STATUS .  Take necessary action to clean up the stack."
          exit 2
        else
          echo "Stack $STACK_NAME exist, Updating the existing change set."
          # Create the stack if it doesn't exist
          aws cloudformation create-change-set \
          --stack-name "$STACK_NAME"\
          --template-body file://cloudformation/"$STACK_NAME".yml \
          --parameters file://parameters/"${ENVIRONMENT}-${STACK_NAME}"-parameters.json \
          --change-set-name "$CHANGE_SET_NAME" \
          --capabilities CAPABILITY_NAMED_IAM \
          --region "$AWS_REGION" \
          --query 'Id'

          return
        fi
    fi
}

# Create change sets for stack
create_change_set "STACK_NAME" "CHANGE_SET_NAME"
