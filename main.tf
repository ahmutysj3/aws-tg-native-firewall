resource "aws_vpc" "security" {
  cidr_block = "192.168.0.0/16"
}

# {for k, v in data.aws_subnet.security_subnets_details : v.tags.Name => v.tags.purpose }
# ^ gets the name and purpose of the subnets


resource "aws_subnet" "security_firewall" {
  for_each = local.az_map
  vpc_id            = aws_vpc.security.id
  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.security.cidr_block,8,10),1,-1 + element(split("az",each.key),1))
  availability_zone = each.value
  tags = {
    Name    = "security_firewall_${each.key}_subnet"
    purpose = "firewall"
  }
}

resource "aws_subnet" "security_nat" {
  for_each = local.az_map
  vpc_id            = aws_vpc.security.id
  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.security.cidr_block,8,20),1,-1 + element(split("az",each.key),1))
  availability_zone = each.value
  tags = {
    Name    = "security_nat_${each.key}_subnet"
    purpose = "nat"
  }
}

resource "aws_subnet" "security_tgw" {
   for_each = local.az_map
  vpc_id            = aws_vpc.security.id
  cidr_block        = cidrsubnet(aws_vpc.security.cidr_block,8,253 + element(split("az",each.key),1))
  availability_zone = each.value
  tags = {
    Name    = "security_tgw_${each.key}_subnet"
    purpose = "transit_gateway"
  }
}


resource "aws_internet_gateway" "security" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "security_igw"
  }
}

resource "aws_nat_gateway" "security" {
  for_each = local.az_map
  allocation_id = aws_eip.security[each.key].id
  subnet_id     = aws_subnet.security_nat[each.key].id

  tags = {
    Name = "security_nat_${each.key}_gw"
  }
}

resource "aws_eip" "security" {
  for_each = local.az_map
  vpc = true
  tags = {
    Name = "security_eip_${each.key}"
  }
}

resource "aws_route_table" "security_firewall" {
  for_each = local.az_map
  vpc_id = aws_vpc.security.id

/*   route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  } */

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.security[each.key].id
  }

  tags = {
    Name = "security_firewall_${each.key}_rt_table"
    }
}


resource "aws_route_table" "security_nat" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block         = "10.0.0.0/8"
    gateway_id = aws_internet_gateway.security.id
  }

  tags = {
    Name = "security_nat_rt_table"
  }
}

resource "aws_route_table" "security_tgw_az1" {
  for_each = local.az_map
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "security_tgw_rt_table_${each.key}"
  }
}


resource "aws_vpc" "spokes" {
  for_each = local.az_map
  cidr_block = cidrsubnet("10.0.0.0/8",8, element(split("az",each.key),1))
}


# need to make 3 subnets in each AZ for each spoke VPC
locals {
  subnets = ["prod", "mgmt", "tgw"]
  az_map = {
    az1 = data.aws_availability_zones.available.names[0]
    az2 = data.aws_availability_zones.available.names[1]  }
}

resource "aws_subnet" "spokes_az1" {
  for_each = zipmap(keys({for k, v in toset(local.subnets) : k => v }),range(length(local.subnets)))
  vpc_id            = aws_vpc.spokes["az1"].id
  cidr_block        = each.key != "tgw" ? cidrsubnet(cidrsubnet(aws_vpc.spokes["az1"].cidr_block,1,0),7,each.value) : cidrsubnet(cidrsubnet(aws_vpc.spokes["az1"].cidr_block,1,0),8,255)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_a_${each.key}_az1"
    purpose = each.key
  }
}

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