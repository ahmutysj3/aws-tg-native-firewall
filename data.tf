data "aws_availability_zones" "available" {
  state = "available"
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

locals {
  # Availability Zone Map
  az_map = {
    az1 = data.aws_availability_zones.available.names[0]
    az2 = data.aws_availability_zones.available.names[1]
  }

  # Transit Gateway Subnets
  transit_gateway_subnets = merge(local.tgw_sec_subnets, local.tgw_az1_subnets, local.tgw_az2_subnets)
  tgw_sec_subnets         = { for subk, sub in aws_subnet.spokes_tgw : sub.tags.Name => sub }
  tgw_az1_subnets         = { for subk, sub in aws_subnet.security_az1 : sub.tags.Name => sub if sub.tags.purpose == "transit_gateway" }
  tgw_az2_subnets         = { for subk, sub in aws_subnet.security_az2 : sub.tags.Name => sub if sub.tags.purpose == "transit_gateway" }

  # Spoke Subnets
  spokes_tgw_subnets     = { for k, v in aws_subnet.spokes_tgw : v.tags.Name => { purpose = v.tags.purpose, sub_id = v.id, az = v.tags.az } }
  spokes_private_subnets = { for k, v in aws_subnet.spokes_private : v.tags.Name => { purpose = v.tags.purpose, sub_id = v.id, az = v.tags.az } }
  spokes_all_subnets     = merge(local.spokes_tgw_subnets, local.spokes_private_subnets)
}
