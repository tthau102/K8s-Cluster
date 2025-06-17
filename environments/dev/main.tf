terraform {
  backend "s3" {
    bucket         = "tthau-mvs-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "tthau-mvs-tf-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Managed_by  = "terraform"
    }
  }
}

module "resource_groups" {
  source      = "../../modules/resource-groups"
  project     = var.project
  environment = var.environment
}

module "network" {
  source      = "../../modules/network"
  project     = var.project
  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"
}

module "security" {
  source          = "../../modules/security"
  project         = var.project
  environment     = var.environment
  vpc_id          = module.network.vpc_id
  container_ports = [80, 3000]
}

module "ecr" {
  source       = "../../modules/ecr"
  project      = var.project
  environment  = var.environment
  repositories = ["frontend", "backend"]
}

module "repositories" {
  source      = "../../modules/repositories"
  project     = var.project
  environment = var.environment
  repositories = {
    frontend = {
      name        = "frontend"
      description = "Frontend React application"
      branch      = "master"
    }
    backend = {
      name        = "backend"
      description = "Backend Node.js API"
      branch      = "master"
    }
  }
}

module "mongodb" {
  source          = "../../modules/mongodb"
  project         = var.project
  environment     = var.environment
  vpc_id          = module.network.vpc_id
  subnet_id       = module.network.private_subnet_ids[0]
  mongodb_sg_id   = module.security.mongodb_sg_id
  ecs_tasks_sg_id = module.security.ecs_tasks_sg_id
}

module "ecs" {
  source = "../../modules/ecs"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  alb_sg_id       = module.security.alb_sg_id
  ecs_tasks_sg_id = module.security.ecs_tasks_sg_id

  services = {
    frontend = {
      container_name    = "${var.project}-frontend"
      container_image   = "${module.ecr.repository_urls["frontend"]}:latest"
      container_port    = 80
      health_check_port = 80
      health_check_path = "/health"
      desired_count     = 3

      environment = [
        {
          name  = "REACT_APP_API_URL"
          value = "/api"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "80"
        },
        {
          name  = "NGINX_PORT"
          value = "80"
        }
      ]
      secrets = []
    }

    backend = {
      container_name    = "${var.project}-backend"
      container_image   = "${module.ecr.repository_urls["backend"]}:latest"
      container_port    = 3000
      health_check_port = 3000
      health_check_path = "/health"
      desired_count     = 3

      environment = [
        {
          name  = "NODE_ENV"
          value = "dev" # Giữ nguyên vì đang chỉ có môi trường dev
        },
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "HOST"
          value = "0.0.0.0"
        },
        # CORS Config - Quan trọng
        {
          name  = "ALLOWED_ORIGINS"
          value = "http://${module.ecs.alb_dns_name}, http://${var.domain_name}"
        },
        {
          name  = "FRONTEND_URL"
          value = "http://${module.ecs.alb_dns_name}, http://${var.domain_name}" # ALB DNS
        },
        # Storage Config
        {
          name  = "USE_S3_STORAGE"
          value = "true" # Switch sang S3
        },
        {
          name  = "USE_LOCAL_STORAGE"
          value = "false"
        },
        {
          name  = "S3_BUCKET_NAME"
          value = "${var.project}-${var.environment}-videos"
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        }
      ],
      secrets = [
        {
          name      = "MONGODB_URI"
          valueFrom = module.mongodb.connection_string_arn
        }
      ]
    }
  }

  depends_on = [module.mongodb]
}


module "pipeline" {
  source           = "../../modules/pipeline"
  project          = var.project
  environment      = var.environment
  ecs_cluster_name = module.ecs.cluster_name
  repository_configs = {
    frontend = {
      repository_name = module.repositories.repository_names["frontend"]
      branch_name     = "master"
      service_name    = module.ecs.service_names["frontend"]
      container_name  = "${var.project}-${var.container_names["frontend"]}"
      ecr_repo_url    = module.ecr.repository_urls["frontend"]
      build_specfile  = "buildspec.yml"
    }
    backend = {
      repository_name = module.repositories.repository_names["backend"]
      branch_name     = "master"
      service_name    = module.ecs.service_names["backend"]
      container_name  = "${var.project}-${var.container_names["backend"]}"
      ecr_repo_url    = module.ecr.repository_urls["backend"]
      build_specfile  = "buildspec.yml"
    }
  }
}
