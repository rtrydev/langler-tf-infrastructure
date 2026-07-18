# reference-assets

Serves immutable reference media (KanjiVG stroke-order SVGs today) from a private, encrypted S3 bucket behind CloudFront Origin Access Control. The distribution uses the default `*.cloudfront.net` certificate, the managed `CachingOptimized` cache policy, and allows only `GET`/`HEAD`. The offline ETL uploads objects with immutable cache-control headers; clients resolve `strokeDataRef` keys against the distribution domain.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Reference assets bucket |
| `bucket_arn` | Reference assets bucket ARN |
| `distribution_domain_name` | CloudFront domain for asset URLs |
| `distribution_id` | CloudFront distribution ID |
