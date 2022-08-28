# S3 Bucket Integration for API Gateway

This example demonstrates how to create an S3 Proxy using AWS API Gateway to download an image from an S3 bucket

## Usage
After deploying, visit `{rest_api_url}{stage}/s3?key={bucket}/{object}`

## TODO
1. Add custom authorizer lambda to do any authorization using JWT or API keys