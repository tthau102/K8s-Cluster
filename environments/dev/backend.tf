terraform {
  backend "s3" {
    bucket         = "tth-k8s-pj-shared-be-tf-state-14192c75"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-5"
    dynamodb_table = "tth-k8s-pj-shared-be-tf-locks"
    encrypt        = true
  }
}