terraform {
}
}
}


# Attach policy (basic + DynamoDB query)
resource "aws_iam_role_policy" "lambda_policy" {
name = "mod3-stats-policy-${var.environment}"
role = aws_iam_role.lambda_role.id
policy = data.aws_iam_policy_document.lambda_policy.json
}


data "aws_iam_policy_document" "lambda_policy" {
statement {
actions = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
resources = ["arn:aws:logs:*:*:*"]
}
statement {
actions = ["dynamodb:Query","dynamodb:GetItem","dynamodb:Scan"]
resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.ddb_table}"]
}
}


data "aws_caller_identity" "current" {}


# Package Lambda (zip must be present in repo root or use local-exec to zip)
data "archive_file" "lambda_zip" {
type = "zip"
source_dir = "${path.module}/../src"
output_path = "${path.module}/lambda_payload.zip"
}


resource "aws_lambda_function" "stats" {
function_name = "mod3-stats-${var.environment}"
role = aws_iam_role.lambda_role.arn
handler = "index.handler"
runtime = "nodejs18.x"
filename = data.archive_file.lambda_zip.output_path
source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
environment {
variables = {
DDB_TABLE_STATS = var.ddb_table
}
}
}


# API Gateway (HTTP API v2)
resource "aws_apigatewayv2_api" "http_api" {
name = "mod3-stats-api-${var.environment}"
protocol_type = "HTTP"
}


resource "aws_apigatewayv2_integration" "lambda_integration" {
api_id = aws_apigatewayv2_api.http_api.id
integration_type = "AWS_PROXY"
integration_uri = aws_lambda_function.stats.invoke_arn
payload_format_version = "2.0"
}


resource "aws_apigatewayv2_route" "stats_route" {
api_id = aws_apigatewayv2_api.http_api.id
route_key = "GET /stats/{codigo}"
target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


resource "aws_apigatewayv2_stage" "default" {
api_id = aws_apigatewayv2_api.http_api.id
name = "$default"
auto_deploy = true
}


# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_invoke" {
statement_id = "AllowAPIGatewayInvoke"
action = "lambda:InvokeFunction"
function_name = aws_lambda_function.stats.function_name
principal = "apigateway.amazonaws.com"
source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.http_api.id}/*/GET/stats/*"
}