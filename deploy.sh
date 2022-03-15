#!/bin/bash

# script exit on error
set -e

#########################################################################
#                       AWS environment setup                           #
#########################################################################
export AWS_DEFAULT_REGION='REPLACE_ME'
export AWS_PROFILE='REPLACE_ME'

#########################################################################
#                          Paramater Values                             #
#########################################################################
# Existing S3 Bucket where deployment assets for CloudFormation will be uploaded to
DeploymentBucket='REPLACE_ME'

# CloudFormation stack name
StackName='PrivateWebApp'

# Prefix of S3 buckets name generated (static and access log)
BucketNamePrefix=$(echo -n "$StackName" | tr '[:upper:]' '[:lower:]' | sed 's|[^0-9a-z-]||g')

# Domain name for application (without https://)
DomainName='REPLACE_ME'

# Amazon Route 53 private hosted zone ID
HostedZoneID='REPLACE_ME'

# The ARN of the SSL certificate to be used
SSLCertID='REPLACE_ME'

# VPC ID of the VPC where you are accessing the application
VpcID='REPLACE_ME'

# Two or more subnet IDs where you want to access the application from
SubnetIDs='REPLACE_ME'

# CIDR address range allowed to access the application
IngressCidr='REPLACE_ME'

######################### Deployment commands ###########################
#                     DO NOT EDIT BELOW THIS LINE                       #
#########################################################################
DeploymentBucketPrefix="privatewebapp-$(date +%m%d%y%H%M)"

#########################################################################
#                   Create all the deployment packages                  #
#########################################################################
# Takes local resources and uploads them to a specified s3 bucket.      #
# Creates master template and nested templates with references to       #
# those resources                                                       #
#########################################################################
aws cloudformation package \
    --template-file template.yml \
    --s3-bucket ${DeploymentBucket} \
    --s3-prefix ${DeploymentBucketPrefix} \
    --output-template-file template.packaged.yml

#########################################################################
# Deploy packaged stack                                                 #
#########################################################################
aws cloudformation deploy \
    --template-file template.packaged.yml \
    --stack-name ${StackName} \
    --parameter-overrides \
        "Environment=${StackName}" \
        "BucketNamePrefix=${BucketNamePrefix}" \
        "DomainName=${DomainName}" \
        "HostedZoneID=${HostedZoneID}" \
        "SSLCertID=${SSLCertID}" \
        "VpcID=${VpcID}" \
        "SubnetIDs=${SubnetIDs}" \
        "IngressCidr=${IngressCidr}" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND

#########################################################################
# Upload static website to S3 bucket                                    #
#########################################################################
StaticWebsiteBucket=$(aws cloudformation describe-stacks --stack-name ${StackName} | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="StaticWebsiteBucket") | .OutputValue')
aws s3 cp --sse --recursive ./static/ s3://${StaticWebsiteBucket}
