#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-enable-bucket-logging
module "aws_s3" {
  #checkov:skip=CKV_AWS_300:Example bucket
  source = "../../"

  bucket_prefix = "usx-store"
  external_accounts = [
    "854762601885",
    "648462982672"
  ]

  tags = {
    team    = "usx"
    purpose = "Save Some Documents from USX"
    owner   = "engineering"
  }
}
