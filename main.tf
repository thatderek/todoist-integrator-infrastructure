variable "environment" {
  default = ""
  # "" == production
}

resource "aws_ecr_repository" "app" {
  name = local.function_name
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "lambda" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

locals {
  environment_prefix = var.environment == "" ? "" : "${var.environment}/"
  function_name      = "${local.environment_prefix}todoist_integrator"
}
/*
resource "aws_lambda_function" "app" {
  package_type = "Image"
  image_uri    = "public.ecr.aws/lambda/python:latest"
  #image_uri     = "${aws_ecr_repository.app.repository_url}:latest"
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn

  environment {
    variables = {
      foo = "bar"
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.app,
  ]
}
*/
resource "null_resource" "example1" {
  provisioner "local-exec" {
    command = "docker version"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
}



# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_ecr" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
