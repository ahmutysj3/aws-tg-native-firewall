resource "aws_vpc" "security" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "security_vpc"
  }
}

resource "aws_vpc" "spokes" {
  for_each   = local.az_map
  cidr_block = cidrsubnet("10.0.0.0/8", 8, element(split("az", each.key), 1))
  # spoke az1 10.1.0.0/16 and spoke az2 10.2.0.0/16
  tags = {
    Name = "spoke_${each.key}_vpc"
  }
}

resource "aws_internet_gateway" "security" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "security_inet_gw"
  }
}

resource "aws_eip" "security" {
  for_each = local.az_map
  vpc      = true

  tags = {
    Name = "security_${each.key}_eip"
  }
}
/* resource "aws_nat_gateway" "security" {
  for_each = local.az_map
  allocation_id = aws_eip.security[each.key].id
  subnet_id     = 

  tags = {
    Name = "security_${each.key}_nat_gw"
  }
} */

locals {
  security_subnets  = ["transit_gateway", "firewall", "public"]
  security_az1_cidr = cidrsubnet(aws_vpc.security.cidr_block, 1, 0)
  security_az2_cidr = cidrsubnet(aws_vpc.security.cidr_block, 1, 1)
}


resource "aws_subnet" "security_az1" {
  for_each          = zipmap(local.security_subnets, range(length(local.security_subnets)))
  vpc_id            = aws_vpc.security.id
  cidr_block        = each.key == "transit_gateway" ? cidrsubnet(local.security_az1_cidr, 7, 127) : cidrsubnet(local.security_az1_cidr, 7, each.value)
  availability_zone = local.az_map.az1
  tags = {
    Name    = "security_az1_${each.key}_subnet"
    purpose = each.key
  }
}

resource "aws_subnet" "security_az2" {
  for_each          = zipmap(local.security_subnets, range(length(local.security_subnets)))
  vpc_id            = aws_vpc.security.id
  cidr_block        = each.key == "transit_gateway" ? cidrsubnet(local.security_az2_cidr, 7, 127) : cidrsubnet(local.security_az2_cidr, 7, each.value)
  availability_zone = local.az_map.az2

  tags = {
    Name    = "security_az2_${each.key}_subnet"
    purpose = each.key
  }
}

resource "aws_subnet" "spokes_private" {
  for_each   = local.az_map
  vpc_id     = aws_vpc.spokes[each.key].id
  cidr_block = cidrsubnet(aws_vpc.spokes[each.key].cidr_block, 8, 1)

  tags = {
    Name    = "spoke_${each.key}_private_subnet"
    purpose = "private"
  }
}

resource "aws_subnet" "spokes_tgw" {
  for_each   = local.az_map
  vpc_id     = aws_vpc.spokes[each.key].id
  cidr_block = cidrsubnet(aws_vpc.spokes[each.key].cidr_block, 8, 255)

  tags = {
    Name    = "spoke_${each.key}_tgw_subnet"
    purpose = "transit_gateway"
  }
}

resource "aws_ec2_transit_gateway" "main" {
  description                     = "Main transit gateway"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  transit_gateway_cidr_blocks     = local.transit_gateway_cidr_blocks
  tags = {
    Name = "main_transit_gateway"
  }
}
  
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  for_each = {for vpck, vpc in data.aws_vpc.details : vpc.tags.Name => vpc.id }
  vpc_id = each.value
  subnet_ids = data.aws_subnets.all[each.value].ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}