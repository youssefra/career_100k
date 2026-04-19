#!/bin/bash
echo "--- AWS INFRASTRUCTURE AUDIT ---"
echo "Checking for running EC2 Instances..."
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
echo "Checking S3 Buckets..."
aws s3 ls
