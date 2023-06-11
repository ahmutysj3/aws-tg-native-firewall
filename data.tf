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

locals {
  transit_gateway_subnets = merge(local.tgw_sec_subnets, local.tgw_az1_subnets, local.tgw_az2_subnets)
  tgw_sec_subnets = {for subk, sub in aws_subnet.spokes_tgw : sub.tags.Name  => sub }
  tgw_az1_subnets = {for subk, sub in aws_subnet.security_az1 : sub.tags.Name => sub if sub.tags.purpose == "transit_gateway"}
  tgw_az2_subnets = {for subk, sub in aws_subnet.security_az2 : sub.tags.Name => sub if sub.tags.purpose == "transit_gateway"}
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

data "aws_vpcs" "all" {
}

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
  

