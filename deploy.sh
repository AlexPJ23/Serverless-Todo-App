#!/bin/bash

set -e 

ENV=$1  
if [[ -z "$ENV" ]]; then
  echo "Usage: ./deploy.sh [dev|staging|prod]"
  exit 1
fi

templates=(
  "S3"
  "Lambda"
  "DynamoDB"
  "APIGateway"
)

# Zip the Lambda code
echo "Zipping the Lambda code..."
zip -j ./templates/Lambda/my-lambda-code.zip ./templates/Lambda/src/*

for STACK in "${templates[@]}"
do
  echo "Deploying stack: $STACK"

  TEMPLATE_FILE="./templates/${STACK}/${STACK}.yaml"
  STACK_NAME="${STACK}-${ENV}"

  if [[ "$STACK" == "IAM" || "$STACK" == "APIGateway" ]]; then
    # IAM stack does not have a parameters file
    PARAMS_OPTION=""
  else
    PARAMS_FILE="./templates/${STACK}/parameters.json"
    PARAMS_OPTION="--parameters file://$PARAMS_FILE"
  fi


  # Check if stack exists
  if aws cloudformation describe-stacks --stack-name "$STACK_NAME" &> /dev/null; then
    echo "Updating stack: $STACK_NAME"
    aws cloudformation update-stack \
      --stack-name "$STACK_NAME" \
      --template-body file://$TEMPLATE_FILE \
      $PARAMS_OPTION

    aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME"
  else
    if [[ "$STACK" == "APIGateway" ]]; then
      # APIGateway stack requires a special parameter for the stage name
      PARAMS_OPTION="--parameters ParameterKey=LambdaFunctionArn,ParameterValue=$(aws cloudformation list-exports --query \"Exports[?Name=='LambdaFunctionArn'].Value\" --output text)"
    else
      PARAMS_OPTION="--parameters file://$PARAMS_FILE"
    fi

    echo "Creating stack: $STACK_NAME"
    aws cloudformation create-stack \
      --stack-name "$STACK_NAME" \
      --template-body file://$TEMPLATE_FILE \
      --capabilities CAPABILITY_NAMED_IAM \
      $PARAMS_OPTION
    


    aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME"

    echo "✅ Stack $STACK_NAME created."


    if [[ "$STACK" == "S3" ]]; then
      # Upload Lambda code to S3 bucket after S3 stack is created
      BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)
      echo "Uploading Lambda code to S3 bucket: $BUCKET_NAME"
      aws s3 cp ./templates/Lambda/my-lambda-code.zip s3://$BUCKET_NAME/my-lambda-code.zip
    fi
  fi
done

echo "✅ Deployment complete."
