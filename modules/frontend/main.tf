data "aws_route53_zone" "application" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_s3_bucket" "frontend" {
  #checkov:skip=CKV_AWS_18:CloudFront provides request visibility; a second logging bucket would add unnecessary cost and complexity
  #checkov:skip=CKV_AWS_144:Cross-region replication conflicts with the near-zero-cost goal; the static export is reproducible from source
  #checkov:skip=CKV_AWS_145:SSE-S3 avoids KMS request charges for non-sensitive static assets
  #checkov:skip=CKV2_AWS_62:Static frontend changes are deployed directly and need no event notifications
  bucket = var.domain_name
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${replace(var.domain_name, ".", "-")}-oac"
  description                       = "Origin access control for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_acm_certificate" "frontend" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  for_each = toset([var.domain_name])

  zone_id = data.aws_route53_zone.application.zone_id
  name    = one(aws_acm_certificate.frontend.domain_validation_options).resource_record_name
  type    = one(aws_acm_certificate.frontend.domain_validation_options).resource_record_type
  ttl     = 60
  records = [one(aws_acm_certificate.frontend.domain_validation_options).resource_record_value]
}

resource "aws_acm_certificate_validation" "frontend" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_validation : record.fqdn]
}

resource "aws_cloudfront_function" "rewrite_uri" {
  name    = "${replace(var.domain_name, ".", "-")}-rewrite-uri"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite trailing-slash paths for the Next.js static export"
  publish = true
  code    = file("${path.module}/cloudfront-functions/rewrite-uri.js")
}

resource "aws_cloudfront_response_headers_policy" "frontend" {
  name = "${replace(var.domain_name, ".", "-")}-security-headers"

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }

    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_security_policy {
      content_security_policy = join("; ", [
        "default-src 'self'",
        "script-src 'self' 'unsafe-inline'",
        "script-src-attr 'none'",
        "style-src 'self' 'unsafe-inline'",
        "img-src 'self' data:",
        "font-src 'self' data:",
        "connect-src 'self' ${join(" ", sort(tolist(var.connect_sources)))}",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "frame-ancestors 'none'",
        "upgrade-insecure-requests",
      ])
      override = true
    }
  }

  custom_headers_config {
    items {
      header   = "Cross-Origin-Opener-Policy"
      override = true
      value    = "same-origin"
    }

    items {
      header   = "Cross-Origin-Resource-Policy"
      override = true
      value    = "same-origin"
    }

    items {
      header   = "Permissions-Policy"
      override = true
      value    = "camera=(), geolocation=(), microphone=()"
    }
  }
}

resource "aws_cloudfront_distribution" "frontend" {
  #checkov:skip=CKV_AWS_86:CloudFront access logging requires another S3 bucket and is deferred until traffic warrants its cost
  #checkov:skip=CKV_AWS_68:AWS WAF has an always-on cost disproportionate to this invite-only personal application
  #checkov:skip=CKV2_AWS_47:A WAF ACL is intentionally omitted to preserve the near-zero idle-cost requirement
  #checkov:skip=CKV_AWS_310:A second origin would duplicate a reproducible static export without improving this personal application's recovery objective
  #checkov:skip=CKV_AWS_374:Langler's invited users are not restricted to a fixed geographic allowlist
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Langler frontend at ${var.domain_name}"
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id           = "s3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.frontend.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_uri.arn
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.frontend.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_iam_policy_document" "frontend" {
  statement {
    sid     = "AllowCloudFrontRead"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.frontend.arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.frontend.arn,
      "${aws_s3_bucket.frontend.arn}/*",
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

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend.json
}

resource "aws_route53_record" "frontend_ipv4" {
  zone_id = data.aws_route53_zone.application.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "frontend_ipv6" {
  zone_id = data.aws_route53_zone.application.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
