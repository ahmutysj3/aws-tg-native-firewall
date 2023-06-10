resource "aws_vpc" "firewall" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "firewall" {
  vpc_id = aws_vpc.firewall.id

  tags = {
    Name = "firewall_igw"
  }
}

resource "aws_subnet" "firewall_main" {
  vpc_id     = aws_vpc.firewall.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "firewall_main_subnet"
  }
}

resource "aws_vpc" "spoke_a" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "spoke_a_public" {
  vpc_id     = aws_vpc.spoke_a.id
  cidr_block = "10.1.0.0/24"

  tags = {
    Name = "spoke_a_public_subnet"
  }
}

resource "aws_subnet" "spoke_a_private" {
  vpc_id     = aws_vpc.spoke_a.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "spoke_a_private_subnet"
  }
}

resource "aws_vpc" "spoke_b" {
  cidr_block = "10.2.0.0/16"
}

resource "aws_subnet" "spoke_b_public" {
  vpc_id     = aws_vpc.spoke_b.id
  cidr_block = "10.2.0.0/24"

  tags = {
    Name = "spoke_b_public_subnet"
  }
}

resource "aws_subnet" "spoke_b_private" {
  vpc_id     = aws_vpc.spoke_b.id
  cidr_block = "10.2.1.0/24"

  tags = {
    Name = "spoke_b_private_subnet"
  }
}

