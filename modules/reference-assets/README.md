# reference-assets

Serves immutable reference media (KanjiVG stroke-order SVGs, vocabulary embeddings, and the pruned Burmese myWord segmentation model) from a private, encrypted S3 bucket behind CloudFront Origin Access Control. The distribution uses the default `*.cloudfront.net` certificate, the managed `CachingOptimized` cache policy, allows only `GET`/`HEAD`, and exposes assets to the configured frontend origin. The offline ETL uploads objects with immutable cache-control headers; clients resolve `strokeDataRef` and Burmese model keys against the distribution domain.

## Inputs

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Resource name prefix |
| `allowed_origin` | `string` | HTTPS browser origin allowed to fetch assets |

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Reference assets bucket |
| `bucket_arn` | Reference assets bucket ARN |
| `distribution_domain_name` | CloudFront domain for asset URLs |
| `distribution_id` | CloudFront distribution ID |
