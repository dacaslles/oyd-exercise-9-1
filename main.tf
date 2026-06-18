module "observability" {
  source = "./modules/observability"


  alb_arn_suffix              = var.alb_arn_suffix
  notification_email          = var.notification_email
  log_retention_days          = var.log_retention_days
  monthly_budget_usd          = var.monthly_budget_usd
  estimated_charges_threshold = var.estimated_charges_threshold
  aws_region                  = var.aws_region


  providers = {
    aws          = aws
    aws.us_east_1 = aws.us_east_1
  }
}
