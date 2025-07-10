import boto3
from botocore.exceptions import ClientError
import json
# Initialize the DynamoDB resource
dynamodb = boto3.resource('dynamodb')
endpoint_url = 'http://localhost:8000'  # Local DynamoDB endpoint for testing


def lambda_handler(event, _):
    # Initialize the DynamoDB client
    dynamodb = boto3.resource('dynamodb')
    
    # Get the table name from the environment variable
    table_name = 'MessagesTable'
    try:
        # Get the table
        table = dynamodb.Table(table_name)
        
        # Parse the incoming event data
        message = json.loads(event['body'])
        
        # Insert the message into the DynamoDB table
        response = table.put_item(Item=message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Message posted successfully!', 'response': response})
        }
        
    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }