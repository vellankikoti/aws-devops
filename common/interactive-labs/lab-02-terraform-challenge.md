# Lab 02: Terraform Challenge

## Objective
Given requirements, write Terraform code from scratch (no copy-paste!).

## Challenge
Create Terraform code that provisions:
1. An S3 bucket with versioning enabled
2. A DynamoDB table with a partition key "id" (String)
3. An IAM role with read-only access to the S3 bucket

## Rules
- Must use variables for bucket name and table name
- Must output the bucket ARN and table ARN
- Must use proper tagging

## Hints
- `aws_s3_bucket`, `aws_s3_bucket_versioning`
- `aws_dynamodb_table`
- `aws_iam_role`, `aws_iam_role_policy`

## Time Limit: 30 minutes
