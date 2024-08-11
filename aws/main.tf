#terraform {
#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = "~> 4.16"
#    }
#  }
#}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "us-west-2"
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region # Change this to your preferred region
  #access_key = var.aws_access_key 
  #secret_key = var.aws_secret_key
}


# Create an S3 bucket for website hosting
resource "aws_s3_bucket" "website_bucket" {
  bucket = "cdreetz-infra-test-bucket" # Change this to a globally unique name
}

# Configure the bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Upload the index.html file to the bucket
resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>My Terraform-deployed Website</title>
</head>
<body>
    <h1>Hello, Terraform and AWS!</h1>
    <p>This website was deployed using Terraform on Amazon Web Services.</p>
</body>
</html>
EOF
  content_type = "text/html"
}

# Make the bucket publicly accessible
resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      },
    ]
  })
}

# Create a CloudWatch metric alarm for monitoring S3 bucket operations
resource "aws_cloudwatch_metric_alarm" "s3_operations_alarm" {
  alarm_name          = "S3BucketOperationsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "1000"
  alarm_description   = "This alarm monitors the number of objects in the S3 bucket"
  alarm_actions       = [aws_sns_topic.website_alerts.arn]

  dimensions = {
    BucketName = aws_s3_bucket.website_bucket.id
  }
}

# Create an SNS topic for alerts
resource "aws_sns_topic" "website_alerts" {
  name = "website-alerts"
}

# Create an SNS topic subscription (email)
resource "aws_sns_topic_subscription" "website_alerts_email" {
  topic_arn = aws_sns_topic.website_alerts.arn
  protocol  = "email"
  endpoint  = "cdreetz.aws@gmail.com" # Change this to your email
}

# Create a CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "website_dashboard" {
  dashboard_name = "WebsiteDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", aws_s3_bucket.website_bucket.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-west-2"
          title   = "S3 Bucket Object Count"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", aws_s3_bucket.website_bucket.id, "StorageType", "StandardStorage"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-west-2"
          title   = "S3 Bucket Size"
        }
      }
    ]
  })
}

# Output the website URL
output "website_url" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "URL of the website"
}

# Output the CloudWatch dashboard URL
output "dashboard_url" {
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.website_dashboard.dashboard_name}"
  description = "URL of the CloudWatch dashboard"
}
