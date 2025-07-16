import os
import sys
PATH= os.environ.get('PATH', '')
BUCKET_NAME = os.environ.get('BUCKET_LOGICAL_NAME', '')

sys.path.append(PATH)
import boto3



s3 = boto3.resource('s3')
bucket = s3.Bucket(BUCKET_NAME)
print(f"Deleting all objects in bucket: {BUCKET_NAME}")
bucket.object_versions.delete()

# if you want to delete the now-empty bucket as well, uncomment this line:
print(f"Deleting bucket: {BUCKET_NAME}")
bucket.delete()