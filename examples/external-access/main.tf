module "aws_s3" {
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
