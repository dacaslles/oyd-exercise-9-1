variable "alb_arn_suffix" {
  description = "ARN suffix of your ALB (from the AWS console, e.g. app/my-alb/abc123def456)"
  type        = string
}

variable "notification_email" {
  description = "Email address that receives CloudWatch alarm notifications"
  type        = string
}

variable "log_retention_days" {
  description = "Days to retain log group entries"
  type        = number
}

variable "monthly_budget_usd" {
  description = "Monthly budget ceiling in USD"
  type        = number
  default     = 25
}

variable "estimated_charges_threshold" {
  description = "USD amount that triggers the EstimatedCharges alarm. Set to a value your account has already exceeded before class so the alarm fires and you can see it in the console."
  type        = number
  default     = 10
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-2"
}
