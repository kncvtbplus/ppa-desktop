#!/bin/bash

set -e

###
### For local dev:
#export BEANSTALK_APP="PPA"
#export BEANSTALK_ENVIRONMENT="development"
#export BEANSTALK_BUCKET="linksbridge-ppa-development"
## date > application.zip
#echo "test-tag-id-6" > tag.id
#echo "This is a local development test version 5" > tag.txt
#ps -ef >> tag.txt
###

# aws sts get-caller-identity
# aws s3 ls "s3://${BEANSTALK_BUCKET}/"

echo "Configuration:"
env | grep  BEANSTALK

echo "Files:"
find .

tag_id=$(cat tag.id)
tag_txt=$(cat tag.txt)
version="$(date '+%Y-%m-%d %H:%M:%S')"
branch=$(cat branch.txt)
echo "Branch: ${branch}"
echo "Tag: id=${tag_id} version=${version}"
echo "---"
cat tag.txt
echo "---"

s3_prefix="product/${BEANSTALK_APP}/${BEANSTALK_ENVIRONMENT}/${version}/${tag_id}"

echo "Uploading application into s3://${BEANSTALK_BUCKET}/${s3_prefix}"
aws s3 cp tag.txt "s3://${BEANSTALK_BUCKET}/${s3_prefix}/"
aws s3 cp application.zip "s3://${BEANSTALK_BUCKET}/${s3_prefix}/"

echo "Creating application version for application=${BEANSTALK_APP} version=${version}"

export description="${branch}: ${tag_txt}"
# description cannot be too long
description=$(echo $description | head -c 195)
aws elasticbeanstalk create-application-version \
  --application-name "${BEANSTALK_APP}" \
  --version-label "${version}" \
  --source-bundle S3Bucket="${BEANSTALK_BUCKET}",S3Key="${s3_prefix}/application.zip" \
  --description "${description}" \
  --tags "Key=git_tag_id,Value=${tag_id}"

echo "Updating environment for application=${BEANSTALK_APP} environment=${BEANSTALK_ENVIRONMENT} version=${version}"
aws elasticbeanstalk update-environment \
  --application-name "${BEANSTALK_APP}" \
  --environment-name "${BEANSTALK_ENVIRONMENT}" \
  --version-label "${version}"
  
echo "Done."
exit 0
 
