# Create S3 Full Access Policy
resource "aws_iam_policy" "s3_policy" {
  name = "s3-policy"
  description = "Policy for allowing all S3 Actions"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

# Create API Gateway Role
resource "aws_iam_role" "s3_api_gateway_role" {
  name = "s3-api-gateway-role"

  # Create Trust Policy for API Gateway
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  EOF
}

# Attach S3 Access Policy to the API Gateway Role
resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role = aws_iam_role.s3_api_gateway_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_api_gateway_rest_api" "rest_api" {
  name = var.rest_api_name
  binary_media_types = ["application/octet-stream", "image/jpeg"]
}

resource "aws_api_gateway_resource" "rest_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part = "s3"
}

resource "aws_api_gateway_method" "rest_api_get_method" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.key": true,
  }
}

resource "aws_api_gateway_method_response" "response200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Timestamp" = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "response400" {
  depends_on = [
    aws_api_gateway_integration.s3_integration]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = "400"
}

resource "aws_api_gateway_method_response" "response500" {
  depends_on = [
    aws_api_gateway_integration.s3_integration]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "integrationResponse200" {
  depends_on = [
    aws_api_gateway_integration.s3_integration]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = aws_api_gateway_method_response.response200.status_code

  response_parameters = {
    "method.response.header.Timestamp" = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "integrationResponse400" {
  depends_on = [
    aws_api_gateway_integration.s3_integration]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = aws_api_gateway_method_response.response400.status_code

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "integrationResponse500" {
  depends_on = [
    aws_api_gateway_integration.s3_integration]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  status_code = aws_api_gateway_method_response.response500.status_code

  selection_pattern = "5\\d{2}"
}

resource "aws_api_gateway_deployment" "S3APIDeployment" {
  depends_on = [
    aws_api_gateway_integration.s3_integration]
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name = "v1"
}

resource "aws_api_gateway_integration" "s3_integration" {
  depends_on = [aws_api_gateway_method.rest_api_get_method]
  http_method = aws_api_gateway_method.rest_api_get_method.http_method
  resource_id = aws_api_gateway_resource.rest_api_resource.id
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  type = "AWS"
  uri = "arn:aws:apigateway:${var.region}:s3:path/{key}"
  credentials = aws_iam_role.s3_api_gateway_role.arn
  integration_http_method = "GET"
  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling = "CONVERT_TO_BINARY"

  request_parameters = {
    "integration.request.path.key": "method.request.querystring.key"
  }
}