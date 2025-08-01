# shared-backend/backend.hcl.tpl



terraform {
  backend "s3" {
    bucket         = "tth-dows-shared-be-tf-state-149d6674"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-3"
    dynamodb_table = "tth-dows-shared-be-tf-locks"
    encrypt        = true
  }
}
