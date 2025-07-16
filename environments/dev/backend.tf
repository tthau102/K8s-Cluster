terraform {
  backend "s3" {
    bucket         = "tth-k8s-pj-shared-be-tf-state-d738ac16"
    key            = "dev/terraform.tfstate"
    region         = "ap-east-1"
    dynamodb_table = "tth-k8s-pj-shared-be-tf-locks"
    encrypt        = true
  }
}
