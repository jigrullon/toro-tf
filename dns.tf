# Lookup the hosted zone
data "aws_route53_zone" "main" {
  name         = "torotech.dev"
  private_zone = false
}

# Create/replace the A record to point to CloudFront
resource "aws_route53_record" "root_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "torotech.dev"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
