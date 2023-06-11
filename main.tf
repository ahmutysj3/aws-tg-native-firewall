resource "aws_vpc" "egress" {
  cidr_block = "192.168.128.0/17"
}

resource "aws_subnet" "egress_nat_az1" {
  vpc_id            = aws_vpc.egress.id
  cidr_block        = "192.168.128.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "egress_nat_az1_subnet"
    purpose = "nat"
  }
}

resource "aws_subnet" "egress_tgw_az1" {
  vpc_id            = aws_vpc.egress.id
  cidr_block        = "192.168.255.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "egress_tgw_az1_subnet"
    purpose = "tgw"
  }
}

resource "aws_internet_gateway" "egress" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "egress_igw"
  }
}

resource "aws_nat_gateway" "egress" {
  connectivity_type = "public"
  subnet_id         = aws_subnet.egress_nat_az1.id
  allocation_id = aws_eip.egress_ngw.id
  tags = {
    Name = "egress_ngw"
  }

  depends_on = [ aws_internet_gateway.egress ]

}

resource "aws_eip" "egress_ngw" {
  vpc        = true
  tags = {
    Name = "egress_ngw_eip"
  }

  depends_on = [ aws_internet_gateway.egress ]
}
resource "aws_route_table" "egress_tgw" {
  vpc_id = aws_vpc.egress.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.egress.id
  }

  tags = {
    Name = "egress_tgw_rt_table"
  }
}

resource "aws_route_table" "egress_vpc" {
  vpc_id = aws_vpc.egress.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.egress.id
  }

  tags = {
    Name = "egress_vpc_rt_table"
  }
}

resource "aws_vpc" "security" {
  cidr_block = "192.168.0.0/17"
}

resource "aws_subnet" "security_firewall_az1" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "security_firewall_az1_subnet"
    purpose = "firewall"
  }
}

resource "aws_subnet" "security_tgw_az1" {
  vpc_id            = aws_vpc.security.id
  cidr_block        = "192.168.127.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "security_tgw_az1_subnet"
    purpose = "tgw"
  }
}


resource "aws_route_table" "security_firewall" {
  vpc_id = aws_vpc.egress.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "security_firewall_rt_table"
  }
}


resource "aws_route_table" "security_tgw" {
  vpc_id = aws_vpc.egress.id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.egress.id
  }

  tags = {
    Name = "security_tgw_rt_table"
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

resource "aws_subnet" "spoke_a_private_az1" {
  vpc_id            = aws_vpc.spoke_a.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_a_private_az1_subnet"
    purpose = "spoke"
  }
}

resource "aws_subnet" "spoke_a_private_az2" {
  vpc_id            = aws_vpc.spoke_a.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "spoke_a_private_az2_subnet"
    purpose = "spoke"
  }
}

resource "aws_subnet" "spoke_a_tgw_az1" {
  vpc_id            = aws_vpc.spoke_a.id
  cidr_block        = "10.1.255.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_a_tgw_az1_subnet"
    purpose = "tgw"
  }
}

resource "aws_subnet" "spoke_a_tgw_az2" {
  vpc_id            = aws_vpc.spoke_a.id
  cidr_block        = "10.1.254.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "spoke_a_tgw_az2_subnet"
    purpose = "tgw"
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

resource "aws_subnet" "spoke_b_private_az1" {
  vpc_id            = aws_vpc.spoke_b.id
  cidr_block        = "10.2.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_b_private_az1_subnet"
    purpose = "spoke"
  }
}

resource "aws_subnet" "spoke_b_private_az2" {
  vpc_id            = aws_vpc.spoke_b.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "spoke_b_private_az2_subnet"
    purpose = "spoke"
  }
}

resource "aws_subnet" "spoke_b_tgw_az1" {
  vpc_id            = aws_vpc.spoke_b.id
  cidr_block        = "10.2.255.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "spoke_b_tgw_az1_subnet"
    purpose = "tgw"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "tgw_subnets" {
  filter {
    name   = "tag:purpose"
    values = ["tgw"]
  }
}

data "aws_subnet" "tgw_subnets_details" {
  for_each = toset(data.aws_subnets.tgw_subnets.ids)
  id       = each.value
}


resource "aws_ec2_transit_gateway" "main" {
  description                     = "test transit gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  transit_gateway_cidr_blocks     = [for subk in data.aws_subnet.tgw_subnets_details : subk.cidr_block]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "security" {
  subnet_ids                                      = [aws_subnet.security_tgw_az1.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.security.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "egress" {
  subnet_ids                                      = [aws_subnet.egress_tgw_az1.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.egress.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_a" {
  subnet_ids                                      = [aws_subnet.spoke_a_tgw_az1.id, aws_subnet.spoke_a_tgw_az2.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.spoke_a.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_b" {
  subnet_ids                                      = [aws_subnet.spoke_b_tgw_az1.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = aws_vpc.spoke_b.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}
