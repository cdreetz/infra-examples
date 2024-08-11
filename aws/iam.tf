resource "aws_iam_policy" "terraform_executioon_policy" {
  name           = "TerraformExecutionPolicy"
  path           = "/"
  description    = "IAM policy for Terraform execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "sns:*",
          "cloudwatch:*",
          "logs:*",
          "iam:CreateServiceLinkdRole"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "terraform_user_policy" {
  user       = "YOUR_IAM_USERNAME"
  
  
  
}

