data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_map = {
    az1 = data.aws_availability_zones.available.names[0]
    az2 = data.aws_availability_zones.available.names[1]
  }

  transit_gateway_cidr_blocks = [for subnet in data.aws_subnet.transit_gateway_details : subnet.cidr_block]
}

data "aws_subnets" "transit_gateway" {
  filter {
    name   = "tag:purpose"
    values = ["transit_gateway"]
  }
}

data "aws_subnet" "transit_gateway_details" {
  for_each = toset(data.aws_subnets.transit_gateway.ids)
  id       = each.value
}

data "aws_vpcs" "all" {}

data "aws_vpc" "details" {
  for_each = toset(data.aws_vpcs.all.ids)
  id = each.key
}

data "aws_subnets" "all" {
  for_each = toset(data.aws_vpcs.all.ids)

  filter {
    name = "tag:purpose"
    values = ["transit_gateway"]
  }

  filter {
    name = "vpc-id"
    values = [each.key]
  }
}
  

