# shared-backed/1.1.providers.tf 

provider "aws" {
  region = var.region
  default_tags {
    tags = merge(local.tags)
  }
}
