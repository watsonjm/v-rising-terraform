###########################
# VPC
###########################
resource "aws_key_pair" "terraform" {
  key_name   = "${local.name_tag}-terraform"
  public_key = file("vrising.pub")

  tags = { Name = "${local.name_tag}-terraform" }
}

module "vpc" {
  source               = "github.com/watsonjm/tf-aws-vpc?ref=v1.0.3"
  name                 = "${local.name_tag}-main-vpc"
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_classiclink   = false
  flow_logs            = false
}

###########################
# ROUTING
###########################
resource "aws_internet_gateway" "default" {
  vpc_id = module.vpc.vpc_id

  tags = { Name = "${local.name_tag}-default-igw" }
}

resource "aws_route_table" "public_default" {
  vpc_id = module.vpc.vpc_id

  tags = { Name = "${local.name_tag}-public-rt" }
}

resource "aws_route" "public_default" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_default.id
  gateway_id             = aws_internet_gateway.default.id
}

###########################
# SUBNETS
###########################
module "subnets" {
  for_each                = var.subnets
  source                  = "github.com/watsonjm/tf-aws-subnet?ref=v1.0.3"
  name                    = "${local.name_tag}-${each.value.name}"
  vpc_id                  = module.vpc.vpc_id
  cidr                    = each.value.cidr
  az_ids                  = data.aws_availability_zones.all.zone_ids
  rt_id                   = lookup(local.route_table, each.value.rt, try(aws_route_table.public_default.id, null))
  map_public_ip_on_launch = each.value.auto_ip
}
###########################
# EC2
###########################
resource "aws_spot_instance_request" "vrising" {
  ami                         = data.aws_ami.ubuntu.id
  spot_price                  = "0.03"
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.terraform.id
  associate_public_ip_address = true
  subnet_id                   = module.subnets["public"].subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.vrising.id]
  user_data                   = file("cloudinit.conf")
  wait_for_fulfillment = true

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }


  tags = { Name = "V Rising" }
}

resource "aws_security_group" "vrising" {
  name        = "${local.name_tag}-vrising-sg"
  description = "Allow required traffic for V Rising"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  ingress {
    description = "V Rising from home"
    from_port   = 27015
    to_port     = 27016
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
  request_headers = {
    Accept = "text/html"
  }
}

###########################
# CloudWatch Alarm
###########################
# Alarm to stop when idle
# terraform import aws_cloudwatch_metric_alarm.idle_stop awsec2-i-0f22bb4e46c2a3d7c-GreaterThanOrEqualToThreshold-CPUUtilization
data "aws_instance" "vrising_spot" {
  filter {
    name   = "spot-instance-request-id"
    values = [aws_spot_instance_request.vrising.id]
  }
}

resource "aws_cloudwatch_metric_alarm" "idle_stop" {
  actions_enabled = true
  alarm_actions = [
    "arn:aws:automate:us-east-2:ec2:stop",
  ]
  alarm_description   = "Auto stop instance when idle."
  alarm_name          = "${data.aws_instance.vrising_spot.id}-GreaterThanOrEqualToThreshold-CPUUtilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  datapoints_to_alarm = 1
  dimensions = {
    "InstanceId" = data.aws_instance.vrising_spot.id
  }
  evaluation_periods        = 1
  insufficient_data_actions = []
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  ok_actions                = []
  period                    = 900
  statistic                 = "Maximum"
  tags                      = {}
  threshold                 = 0.13
  treat_missing_data        = "missing"
}