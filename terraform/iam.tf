###############################
# IAM ROLE PARA AWS LAMBDA
###############################

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_stats"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

###############################
# POLÍTICA: PERMISOS PARA LOGS
###############################

resource "aws_iam_role_policy" "lambda_logging" {
  name = "lambda_logging_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

###############################
# OUTPUT (OPCIONAL)
###############################

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}