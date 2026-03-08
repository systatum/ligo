#!/bin/bash

wait-for-it localhost:4566 -t 30 -- awslocal s3 mb s3://ligo-uploaded-files
wait-for-it localhost:4566 -t 30 -- awslocal s3api put-bucket-acl --bucket ligo-uploaded-files --acl public-read

# for testing purpose

wait-for-it localhost:4566 -t 30 -- awslocal s3 mb s3://ligo-uploaded-files-test
wait-for-it localhost:4566 -t 30 -- awslocal s3api put-bucket-acl --bucket ligo-uploaded-files-test --acl public-read