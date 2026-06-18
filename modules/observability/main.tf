terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

resource "aws_cloudwatch_log_group" "finapi_dev" {
  name              = "/finapi/dev"
  retention_in_days = var.log_retention_days
}


resource "aws_sns_topic" "finapi_alerts" {
  name = "finapi-alerts"
}


resource "aws_sns_topic_subscription" "email_notifications" {
  topic_arn = aws_sns_topic.finapi_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}


resource "aws_cloudwatch_metric_alarm" "http_5xx_errors" {
  alarm_name          = "finapi-alb-5xx-errors"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.finapi_alerts.arn]
  ok_actions    = [aws_sns_topic.finapi_alerts.arn]
}

resource "aws_iam_role" "budget_notification_role" {
  name = "finapi-budget-notification-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "budgets.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "budget_notification_policy" {
  name = "finapi-budget-notification-policy"
  role = aws_iam_role.budget_notification_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.finapi_alerts.arn
      }
    ]
  })
}

resource "aws_budgets_budget" "monthly_finapi" {
  name         = "finapi-monthly-cost"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }
}

resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  provider            = aws.us_east_1
  alarm_name          = "finapi-estimated-charges"
  namespace           = "AWS/Billing"
  metric_name         = "EstimatedCharges"
  statistic           = "Maximum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = var.estimated_charges_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.finapi_alerts.arn]
  ok_actions    = [aws_sns_topic.finapi_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "finapi-alb-target-response-time"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.finapi_alerts.arn]
  ok_actions    = [aws_sns_topic.finapi_alerts.arn]
}