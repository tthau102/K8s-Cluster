# dev/security-groups.tf 



module "public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name_prefix}-public-sg"
  description = "Public SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    # {
    #   from_port   = 22
    #   to_port     = 22
    #   protocol    = "tcp"
    #   description = "User-service ports"
    #   cidr_blocks = "0.0.0.0/0"
    # },
    # {
    #   from_port   = 0
    #   to_port     = 0
    #   protocol    = "-1"
    #   description = "Allow all from VPC CIDR"
    #   cidr_blocks = "10.25.0.0/16"
    # },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = ["all-all"]
}


module "master_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name_prefix}-master-sg"
  description = "Master SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all from VPC CIDR"
      cidr_blocks = "10.25.0.0/16"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = ["all-all"]
}


module "worker_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${local.name_prefix}-worker-sg"
  description = "Worker SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all from VPC CIDR"
      cidr_blocks = "10.25.0.0/16"
    },

    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "User-service ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = ["all-all"]
}
