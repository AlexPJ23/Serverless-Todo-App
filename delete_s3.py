import os
import sys
PATH= os.environ.get('PATH', '')
sys.path.append(PATH)
import boto3


BUCKET_NAME = os.environ.get('BUCKET_LOGICAL_NAME', '')
BUCKET =  BUCKET_NAME

s3 = boto3.resource('s3')
bucket = s3.Bucket(BUCKET)
print(f"Deleting all objects in bucket: {BUCKET}")
bucket.object_versions.delete()

# if you want to delete the now-empty bucket as well, uncomment this line:
print(f"Deleting bucket: {BUCKET}")
bucket.delete()