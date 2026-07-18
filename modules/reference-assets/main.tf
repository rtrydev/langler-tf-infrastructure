resource "aws_s3_bucket" "assets" {
  #checkov:skip=CKV_AWS_18:CloudFront provides request visibility; a second logging bucket would add unnecessary cost and complexity
  #checkov:skip=CKV_AWS_144:Cross-region replication conflicts with the near-zero-cost goal; reference assets are reproducible from upstream sources
  #checkov:skip=CKV_AWS_145:SSE-S3 avoids KMS request charges for non-sensitive public reference media
  #checkov:skip=CKV_AWS_21:Versioning would only duplicate immutable reference assets that the ETL can regenerate from upstream sources
  #checkov:skip=CKV2_AWS_62:Reference assets are uploaded by the offline ETL and need no event notifications
  bucket = "${var.name}-reference-assets"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.name}-reference-assets-oac"
  description                       = "Origin access control for ${var.name} reference assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "assets" {
  #checkov:skip=CKV_AWS_86:CloudFront access logging requires another S3 bucket and is deferred until traffic warrants its cost
  #checkov:skip=CKV_AWS_68:AWS WAF has an always-on cost disproportionate to this invite-only personal application
  #checkov:skip=CKV2_AWS_47:A WAF ACL is intentionally omitted to preserve the near-zero idle-cost requirement
  #checkov:skip=CKV_AWS_310:A second origin would duplicate reproducible reference assets without improving this personal application's recovery objective
  #checkov:skip=CKV_AWS_374:Langler's invited users are not restricted to a fixed geographic allowlist
  #checkov:skip=CKV_AWS_174:The default CloudFront certificate cannot pin TLSv1.2; a custom domain is intentionally out of scope for reference media
  #checkov:skip=CKV_AWS_305:Assets are fetched by exact object key and the bare domain has no index document to serve as a root object
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Langler reference assets for ${var.name}"
  price_class     = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.assets.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.assets.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "assets" {
  statement {
    sid     = "AllowCloudFrontRead"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.assets.arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.assets.arn]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets.json
}
