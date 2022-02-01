module "aws_s3" {
  source = "../../"

  bucket_prefix = "usx-store"

  tags = {
    team    = "usx"
    purpose = "Save Some Documents from USX"
    owner   = "engineering"
  }
}
