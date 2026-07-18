locals {
  # tflint-ignore: terraform_unused_declarations # consumed once the planned modules below land
  project = "langler"
}

# Planned structure (see langler/tasks/01-foundations-infrastructure.md):
#
#   modules/frontend   private S3 + OAC, CloudFront + URL-rewrite function,
#                      DNS-validated ACM cert (us-east-1), Route 53 aliases
#   modules/auth       Cognito user pool, invite-only (AllowAdminCreateUserOnly)
#   modules/storage    DynamoDB single table, provisioned within Always Free tier
#   modules/api        API Gateway HTTP API + Go Lambdas (arm64, provided.al2023),
#                      Cognito JWT authorizer (+ Lambda authorizer for machine tokens later)
