resource "aws_vpc" "security" {
  cidr_block = "192.168.0.0/16"
}

resource "aws_subnet" "security_firewall_az1" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.10.0/25"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "security_firewall_az1"
    purpose = "firewall"
  }
}

resource "aws_subnet" "security_firewall_az2" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.10.128/25"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "security_firewall_az2"
    purpose = "firewall"
  }
}

resource "aws_subnet" "security_nat_az1" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.20.0/25"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "security_nat_az1"
    purpose = "nat"
  }
}

resource "aws_subnet" "security_nat_az2" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.20.128/25"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "security_nat_az2"
    purpose = "nat"
  }
}

resource "aws_subnet" "security_tgw_az1" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.254.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "security_tgw_az1_subnet"
    purpose = "transit_gateway"
  }
}

resource "aws_subnet" "security_tgw_az2" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.255.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "security_tgw_az2_subnet"
    purpose = "transit_gateway"
  }
}


resource "aws_internet_gateway" "security" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "security_igw"
  }
}

resource "aws_nat_gateway" "security_nat_az1" {
  allocation_id = aws_eip.security_az1.id
  subnet_id     = aws_subnet.security_nat_az1.id

  tags = {
    Name = "security_nat_az1_gw"
  }
}

resource "aws_nat_gateway" "security_nat_az2" {
  allocation_id = aws_eip.security_az2.id
  subnet_id     = aws_subnet.security_nat_az2.id

  tags = {
    Name = "security_nat_az2_gw"
  }
}

resource "aws_eip" "security_az1" {
  vpc = true

  tags = {
    Name = "security_az1_eip"
  }
}

resource "aws_eip" "security_az2" {
  vpc = true

  tags = {
    Name = "security_az2_eip"
  }
}

resource "aws_route_table" "security_firewall_az1" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "aws_nat_gateway.security_nat_az1.id"
  }

  tags = {
    Name = "security_firewall_rt_table"
  }
}

resource "aws_route_table" "security_firewall_az2" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "aws_nat_gateway.security_nat_az2.id"
  }

  tags = {
    Name = "security_firewall_rt_table"
  }
}

resource "aws_route_table" "security_nat_az1" {
  vpc_id = aws_vpc.security.id

  route {
    cidr_block         = "10.0.0.0/8"
    gateway_id = aws_internet_gateway.security.id
  }

  tags = {
    Name = "security_nat_rt_table"
  }
}

resource "aws_route_table" "security_nat_az2" {
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
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "security_tgw_rt_table_az1"
  }
}

resource "aws_route_table" "security_tgw_az2" {
  vpc_id = aws_vpc.security.id

  tags = {
    Name = "security_tgw_rt_table_az2"
  }
}

resource "aws_vpc" "spoke_a" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_route_table" "spoke_a" {
  vpc_id = aws_vpc.spoke_a.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "spoke_a_main_rt_table"
  }
}

resource "aws_subnet" "spoke_a_prod_az1" {
  vpc_id            = aws_vpc.spoke_a.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_a_prod_az1"
    purpose = "production"
  }
}

resource "aws_subnet" "spoke_a_mgmt_az1" {
  vpc_id            = aws_vpc.spoke_a.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_a_mgmt_az1"
    purpose = "management"
  }
}

resource "aws_subnet" "spoke_a_tgw_az1" {
  vpc_id            = aws_vpc.spoke_a.id
  cidr_block        = "10.1.255.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_a_tgw_az1_subnet"
    purpose = "transit_gateway"
  }
}


resource "aws_vpc" "spoke_b" {
  cidr_block = "10.2.0.0/16"
}

resource "aws_route_table" "spoke_b" {
  vpc_id = aws_vpc.spoke_b.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "spoke_b_main_rt_table"
  }
}

resource "aws_subnet" "spoke_b_prod_az2" {
  vpc_id            = aws_vpc.spoke_b.id
  cidr_block        = "10.2.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "spoke_b_prod_az2"
    purpose = "production"
  }
}

resource "aws_subnet" "spoke_b_mgmt_az2" {
  vpc_id            = aws_vpc.spoke_b.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "spoke_b_mgmt_az2"
    purpose = "management"
  }
}

resource "aws_subnet" "spoke_b_tgw_az2" {
  vpc_id            = aws_vpc.spoke_b.id
  cidr_block        = "10.2.255.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "spoke_b_tgw_az2"
    purpose = "transit_gateway"
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


resource "aws_ec2_transit_gateway" "main" {
  description                     = "test transit gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = [for subk in data.aws_subnet.transit_gateway_details : subk.cidr_block]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "security" {
  subnet_ids                                      = [aws_subnet.security_tgw_az1.id, aws_subnet.security_tgw_az2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.security.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_a" {
  subnet_ids                                      = [aws_subnet.spoke_a_tgw_az1.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.spoke_a.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_b" {
  subnet_ids                                      = [aws_subnet.spoke_b_tgw_az2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.spoke_b.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}
