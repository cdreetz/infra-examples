# Configure the Google Cloud provider
provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

# Create a Google Cloud Storage bucket
resource "google_storage_bucket" "website_bucket" {
  name     = "your-unique-bucket-name"
  location = "US"

  # Enable website hosting
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # Make bucket publicly readable
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"
}

# Upload the index.html file to the bucket
resource "google_storage_bucket_object" "website_index" {
  name    = "index.html"
  bucket  = google_storage_bucket.website_bucket.name
  content = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>My Terraform-deployed Website</title>
</head>
<body>
    <h1>Hello, Terraform and GCP!</h1>
    <p>This website was deployed using Terraform on Google Cloud Platform.</p>
</body>
</html>
EOF
}

# Make the bucket publicly accessible
resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.website_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Output the website URL
output "website_url" {
  value       = "https://storage.googleapis.com/${google_storage_bucket.website_bucket.name}/index.html"
  description = "URL of the website"
}



#####################################
#####################################


resource "google_monitoring_uptime_check_config" "website_uptime_check" {
  display_name = "Website Uptime Check"
  timeout = "10s"
  period = "60s"

  http_check {
    path          = "/index.html"
    port          = "443"
    use_ssl       = true
    validate_ssl  = true
  }

  monitored_resource {
    type   = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = google_storage_bucket.website_bucket.name
    }
  }
}


# Create an alerting policy
resource "google_monitoring_alert_policy" "website_alert_policy" {
  display_name = "Website Down Alert Policy"
  combiner     = "OR"
  conditions {
    display_name = "Uptime Check Failed"
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.\"check_id\"=\"${google_monitoring_uptime_check_config.website_uptime_check.uptime_check_id}\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Create a notification channel (email)
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = "your-email@example.com"
  }
}

# Create a log-based metric to track bucket creation/deletion
resource "google_logging_metric" "bucket_operations" {
  name   = "bucket_operations"
  filter = "resource.type=gcs_bucket AND (protoPayload.methodName=\"storage.buckets.create\" OR protoPayload.methodName=\"storage.buckets.delete\")"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}


# Create a dashboard
resource "google_monitoring_dashboard" "website_dashboard" {
  dashboard_json = <<EOF
{
  "displayName": "Website Monitoring Dashboard",
  "gridLayout": {
    "widgets": [
      {
        "title": "Uptime Check",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.\"check_id\"=\"${google_monitoring_uptime_check_config.website_uptime_check.uptime_check_id}\""
              },
              "unitOverride": "1"
            },
            "plotType": "LINE"
          }],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      },
      {
        "title": "Bucket Operations",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"logging.googleapis.com/user/${google_logging_metric.bucket_operations.name}\" resource.type=\"gcs_bucket\""
              },
              "unitOverride": "1"
            },
            "plotType": "LINE"
          }],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "y1Axis",
            "scale": "LINEAR"
          }
        }
      }
    ]
  }
}
EOF
}

# Output the dashboard URL
output "dashboard_url" {
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.website_dashboard.dashboard_id}?project=${var.project_id}"
  description = "URL of the monitoring dashboard"
}






