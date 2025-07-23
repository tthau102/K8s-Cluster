# shared-backend/backend.hcl.tpl



terraform {
  backend "s3" {
    bucket         = "${s3_bucket_name}"
    key            = "${environment}/terraform.tfstate"
    region         = "${region}"
    dynamodb_table = "${dynamodb_table_name}"
    encrypt        = true
  }
}