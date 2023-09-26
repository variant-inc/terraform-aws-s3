#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-enable-bucket-logging
module "aws_s3" {
  #checkov:skip=CKV_AWS_300:Example bucket
  #checkov:skip=CKV_AWS_145:Example bucket
  source = "../../"

  bucket_prefix = "usx-store"

  tags = {
    team    = "usx"
    purpose = "Save Some Documents from USX"
    owner   = "engineering"
  }
}
