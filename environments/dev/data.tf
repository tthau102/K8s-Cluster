# environments/dev/data.tf

# =============================================================================
# DATA SOURCES
# Tập hợp các data sources cần thiết cho việc triển khai infrastructure
# =============================================================================

# Lấy danh sách availability zones khả dụng trong region hiện tại
# Mục đích: Đảm bảo high availability bằng cách phân bố resources across AZs
data "aws_availability_zones" "available" {
  state = "available"

  # Chỉ lấy AZs có đủ capacity cho EC2 instances
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Tìm Ubuntu 22.04 LTS AMI mới nhất
# Mục đích: Luôn sử dụng image Ubuntu mới nhất cho security updates
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical - official Ubuntu publisher

  # Lọc theo Ubuntu 22.04 LTS (Jammy)
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # Chỉ lấy AMI hỗ trợ virtualization HVM (hiện đại)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Đảm bảo AMI có root device là EBS
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
