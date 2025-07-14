# environments/dev/versions.tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "s3" {
    bucket         = "tth-k8s-pj-shared-be-tf-state-14192c75"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-5"
    dynamodb_table = "tth-k8s-pj-shared-be-tf-locks"
    encrypt        = true
  }
}
