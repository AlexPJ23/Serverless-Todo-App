#!/bin/bash
set -e
ENV=$1
if [[ -z "$ENV" ]]; then
  echo "Usage: ./destroy.sh [dev|staging|prod]"
  exit 1
fi

templates=(
  "S3"
  "Lambda"
  "DynamoDB"
  "APIGateway"
)

# Delete Lambda code from S3
CODE="my-lambda-code.zip"
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name "S3-${ENV}" --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)
if [[ -z "$BUCKET_NAME" ]]; then
  echo "❌ S3 bucket not found for environment: $ENV"
  exit 1
fi
echo "Deleting Lambda code from S3 bucket: $BUCKET_NAME"
aws s3 rm "s3://$BUCKET_NAME/$CODE" || echo "❌ Failed to delete Lambda code from S3 bucket: $BUCKET_NAME"

aws s3api list-object-versions --bucket $BUCKET_NAME \
| jq -r '.Versions[] | [.Key, .VersionId] | @tsv' \
| while IFS=$'\t' read -r key version; do
  aws s3api delete-object --bucket $BUCKET_NAME --key "$key" --version-id "$version"
done

echo "✅ Deleted all versions of objects in S3 bucket: $BUCKET_NAME"

for STACK in "${templates[@]}"
do
  echo "Destroying stack: $STACK"

  TEMPLATE_FILE="./templates/${STACK}/${STACK}.yaml"
  STACK_NAME="${STACK}-${ENV}"

  # Check if stack exists
  if aws cloudformation describe-stacks --stack-name "$STACK_NAME" &> /dev/null; then
    aws cloudformation delete-stack --stack-name "$STACK_NAME"
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
    echo "✅ Stack $STACK_NAME deleted."
  else
    echo "❌ Stack $STACK_NAME does not exist."
  fi
done