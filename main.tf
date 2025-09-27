provider "aws" {
  region  = "us-east-1"
  profile = "personal"
}

# ACM certificate
resource "aws_acm_certificate" "toro_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route 53 zone lookup
data "aws_route53_zone" "zone" {
  name         = var.domain_name
  private_zone = false
}

# Validation record
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.toro_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.toro_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "S3-Toro-OAC"
  description                       = "Access control for S3 static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "toro_site" {
  origin {
    domain_name = "${var.s3_bucket}.s3.amazonaws.com"
    origin_id   = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "MyToroSiteCDN"
  }
}

