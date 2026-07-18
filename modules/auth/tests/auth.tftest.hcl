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
}
