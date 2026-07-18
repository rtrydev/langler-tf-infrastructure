# frontend

Hosts a trailing-slash Next.js static export in a private, encrypted S3 bucket behind CloudFront Origin Access Control. The module provisions the CloudFront rewrite function, security headers, a DNS-validated `us-east-1` ACM certificate, and Route 53 A/AAAA aliases.

## Inputs

| Name | Type | Description |
|---|---|---|
| `domain_name` | `string` | Fully qualified application domain |
| `hosted_zone_name` | `string` | Public Route 53 hosted zone |
| `connect_sources` | `set(string)` | Additional HTTPS origins allowed by CSP |

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Static export bucket |
| `distribution_id` | CloudFront distribution ID |
| `distribution_domain_name` | CloudFront debug hostname |
| `site_url` | Canonical frontend URL |
