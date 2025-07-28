# dev/1.1.backend.tf



terraform {
  backend "s3" {
    bucket         = "tth-dows-shared-be-tf-state-11f7abf3"
    key            = "dev/terraform.tfstate"
    region         = "ap-east-1"
    dynamodb_table = "tth-dows-shared-be-tf-locks"
    encrypt        = true
  }
}
