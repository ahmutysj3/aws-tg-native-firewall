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

  depends_on = [aws_internet_gateway.security]
}

resource "aws_nat_gateway" "security" {
  for_each          = local.az_map
  connectivity_type = "public"
  allocation_id     = aws_eip.security[each.key].id
  subnet_id         = each.key == "az1" ? aws_subnet.security_az1["public"].id : aws_subnet.security_az2["public"].id
}

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
  for_each          = local.az_map
  vpc_id            = aws_vpc.spokes[each.key].id
  cidr_block        = cidrsubnet(aws_vpc.spokes[each.key].cidr_block, 8, 1)
  availability_zone = local.az_map[each.key]
  tags = {
    Name    = "spoke_${each.key}_private_subnet"
    purpose = "private"
    az      = each.key
  }
}

resource "aws_subnet" "spokes_tgw" {
  for_each          = local.az_map
  vpc_id            = aws_vpc.spokes[each.key].id
  cidr_block        = cidrsubnet(aws_vpc.spokes[each.key].cidr_block, 8, 255)
  availability_zone = local.az_map[each.key]
  tags = {
    Name    = "spoke_${each.key}_tgw_subnet"
    purpose = "transit_gateway"
    az      = each.key
  }
}

resource "aws_route_table" "spokes" {
  for_each = local.az_map
  vpc_id   = aws_vpc.spokes[each.key].id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "spoke_${each.key}_rt_table"
  }
}

resource "aws_route_table_association" "spokes" {
  for_each       = local.spokes_all_subnets
  subnet_id      = each.value.sub_id
  route_table_id = aws_route_table.spokes[each.value.az].id
}

resource "aws_route_table_association" "security_az1" {
  for_each       = aws_route_table.security_az1
  subnet_id      = aws_subnet.security_az1[each.key].id
  route_table_id = aws_route_table.security_az1[each.key].id
}

resource "aws_route_table" "security_az1" {
  for_each = { for subk, sub in aws_subnet.security_az1 : subk => sub }
  vpc_id   = aws_vpc.security.id

  tags = {
    Name = "security_az1_${each.key}_rt_table"
  }

  /* dynamic "route" {
    for_each = {for subk, sub in aws_subnet.security_az1 : subk => sub if sub.tags.purpose == "transit_gateway" && each.key == sub.tags.purpose}
    content {
      cidr_block = "0.0.0.0/0"
      vpc_endpoint_id = ""
  } */

  dynamic "route" {
    for_each = { for subk, sub in aws_subnet.security_az1 : subk => sub if sub.tags.purpose == "firewall" && each.key == sub.tags.purpose }
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.security["az1"].id
    }
  }

  dynamic "route" {
    for_each = { for subk, sub in aws_subnet.security_az1 : subk => sub if sub.tags.purpose == "firewall" && each.key == sub.tags.purpose }
    content {
      cidr_block         = "10.0.0.0/8"
      transit_gateway_id = aws_ec2_transit_gateway.main.id
    }
  }

  /* dynamic "route" {
    for_each = {for subk, sub in aws_subnet.security_az1 : subk => sub if sub.tags.purpose == "public" && each.key == sub.tags.purpose}
    content {
      cidr_block = "10.0.0.0/8"
      vpc_endpoint_id = ""
    }
  } */

  dynamic "route" {
    for_each = { for subk, sub in aws_subnet.security_az1 : subk => sub if sub.tags.purpose == "public" && each.key == sub.tags.purpose }
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.security.id
    }
  }
}

resource "aws_route_table_association" "security_az2" {
  for_each       = aws_route_table.security_az2
  subnet_id      = aws_subnet.security_az2[each.key].id
  route_table_id = aws_route_table.security_az2[each.key].id
}

resource "aws_route_table" "security_az2" {
  for_each = { for subk, sub in aws_subnet.security_az2 : subk => sub }
  vpc_id   = aws_vpc.security.id

  tags = {
    Name = "security_az2_${each.key}_rt_table"
  }
  /* dynamic "route" {
    for_each = {for subk, sub in aws_subnet.security_az2 : subk => sub if sub.tags.purpose == "transit_gateway" && each.key == sub.tags.purpose}
    content {
      cidr_block = "0.0.0.0/0"
      vpc_endpoint_id = ""
  } */

  dynamic "route" {
    for_each = { for subk, sub in aws_subnet.security_az2 : subk => sub if sub.tags.purpose == "firewall" && each.key == sub.tags.purpose }
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.security["az2"].id
    }
  }

  dynamic "route" {
    for_each = { for subk, sub in aws_subnet.security_az2 : subk => sub if sub.tags.purpose == "firewall" && each.key == sub.tags.purpose }
    content {
      cidr_block         = "10.0.0.0/8"
      transit_gateway_id = aws_ec2_transit_gateway.main.id
    }
  }

  /* dynamic "route" {
    for_each = {for subk, sub in aws_subnet.security_az2 : subk => sub if sub.tags.purpose == "public" && each.key == sub.tags.purpose}
    content {
      cidr_block = "10.0.0.0/8"
      vpc_endpoint_id = ""
    }
  } */

  dynamic "route" {
    for_each = { for subk, sub in aws_subnet.security_az2 : subk => sub if sub.tags.purpose == "public" && each.key == sub.tags.purpose }
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.security.id
    }
  }
}

resource "aws_ec2_transit_gateway" "main" {
  description                     = "Main transit gateway"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  transit_gateway_cidr_blocks     = [for subnet in data.aws_subnet.transit_gateway_details : subnet.cidr_block]
  tags = {
    Name = "main_transit_gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  for_each                                        = { for vpck, vpc in merge(aws_vpc.spokes, { security = aws_vpc.security }) : vpck => vpc.id }
  vpc_id                                          = each.value
  subnet_ids                                      = [for sub in local.transit_gateway_subnets : sub.id if sub.vpc_id == each.value]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  for_each           = toset(["security", "spokes"])
  transit_gateway_id = aws_ec2_transit_gateway.main.id
}

resource "aws_ec2_transit_gateway_route" "to_firewall" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main["security"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main["security"].id
}

resource "aws_ec2_transit_gateway_route" "null_routes" {
  for_each                       = local.az_map
  destination_cidr_block         = aws_vpc.spokes[each.key].cidr_block
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main["security"].id
  blackhole                      = true
}

resource "aws_ec2_transit_gateway_route" "to_spokes" {
  for_each                       = local.az_map
  destination_cidr_block         = aws_vpc.spokes[each.key].cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main["spokes"].id
}
