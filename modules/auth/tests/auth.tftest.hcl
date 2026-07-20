mock_provider "aws" {}

run "plans_invite_only_pool" {
  command = plan

  variables {
    name = "langler-prod"
  }

  assert {
    condition     = aws_cognito_user_pool.users.admin_create_user_config[0].allow_admin_create_user_only
    error_message = "The user pool must be invite-only."
  }

  assert {
    condition     = !aws_cognito_user_pool_client.browser.generate_secret
    error_message = "The static browser client cannot hold a client secret."
  }

  assert {
    condition     = one(aws_cognito_user_pool_client.browser.refresh_token_rotation).feature == "ENABLED"
    error_message = "The browser client must rotate refresh tokens."
  }

  assert {
    condition     = !contains(aws_cognito_user_pool_client.browser.explicit_auth_flows, "ALLOW_REFRESH_TOKEN_AUTH")
    error_message = "Refresh-token auth must remain disabled when rotation is enabled."
  }

  assert {
    condition     = length(aws_cognito_user.e2e) == 0
    error_message = "No E2E user must exist unless e2e_user_email is set."
  }
}

run "provisions_confirmed_e2e_user_when_email_set" {
  command = plan

  variables {
    name           = "langler-prod"
    e2e_user_email = "e2e@example.com"
  }

  assert {
    condition     = length(aws_cognito_user.e2e) == 1
    error_message = "Setting e2e_user_email must provision exactly one Cognito user."
  }

  assert {
    condition     = aws_cognito_user.e2e[0].message_action == "SUPPRESS"
    error_message = "The E2E user must not trigger an invite email."
  }

  assert {
    condition     = aws_cognito_user.e2e[0].attributes["email_verified"] == "true"
    error_message = "The E2E user must be email-verified so sign-in works immediately."
  }

  assert {
    condition     = random_password.e2e[0].length == 24
    error_message = "The E2E password must be 24 characters."
  }
}
