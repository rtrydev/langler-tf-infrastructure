resource "aws_cognito_user_pool" "users" {
  name                = "${var.name}-users"
  deletion_protection = "ACTIVE"
  username_attributes = ["email"]
  auto_verified_attributes = [
    "email",
  ]

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = var.temporary_password_validity_days
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
}

resource "aws_cognito_user_pool_client" "browser" {
  name         = "${var.name}-browser"
  user_pool_id = aws_cognito_user_pool.users.id

  generate_secret               = false
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  refresh_token_rotation {
    feature                    = "ENABLED"
    retry_grace_period_seconds = 10
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "random_password" "e2e" {
  count = var.e2e_user_email == "" ? 0 : 1

  length           = 24
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "@#%*-_=+.,"
}

resource "aws_cognito_user" "e2e" {
  count = var.e2e_user_email == "" ? 0 : 1

  user_pool_id   = aws_cognito_user_pool.users.id
  username       = var.e2e_user_email
  password       = random_password.e2e[0].result
  message_action = "SUPPRESS"

  attributes = {
    email          = var.e2e_user_email
    email_verified = "true"
  }
}
