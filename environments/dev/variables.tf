# environments/dev/variables.tf
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "default_branch" {
  type    = string
  default = "master"
}

variable "container_names" {
  type = map(string)
  default = {
    frontend = "frontend"
    backend  = "backend"
  }
}

variable "domain_name" {
  type = string
}
