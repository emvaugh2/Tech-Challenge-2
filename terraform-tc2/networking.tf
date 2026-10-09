
# Creates the overall VPC
resource "aws_vpc" "supernet" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Project = "Tech-Challenge-2"
  }
}

# Creates public subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.supernet.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Project                                 = "Tech-Challenge-2"
    Name                                    = "tc2-public-subnet-1"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/tc2-eks-cluster" = "shared"
  }

}

# Creates public subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.supernet.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Project                                 = "Tech-Challenge-2"
    Name                                    = "tc2-public-subnet-2"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/tc2-eks-cluster" = "shared"
  }
}

# Creates private subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.supernet.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Project                                 = "Tech-Challenge-2"
    Name                                    = "tc2-private-subnet-1"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/tc2-eks-cluster" = "shared"
  }
}

# Creates private subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.supernet.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"

  tags = {
    Project                                 = "Tech-Challenge-2"
    Name                                    = "tc2-private-subnet-2"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/tc2-eks-cluster" = "shared"
  }
}

# Creates Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Project = "Tech-Challenge-2"
  }
}

# Creates the Internet Gateway (IGW)
resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.supernet.id

  tags = {
    Project = "Tech-Challenge-2"
  }
}

# Creates the NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  depends_on = [aws_internet_gateway.public_igw]

  tags = {
    Project = "Tech-Challenge-2"
  }
}


# Creates the public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.supernet.id

  tags = {
    Project = "Tech-Challenge-2"
  }
}

# Creates the default route for the public route table
resource "aws_route" "default_route_public" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_igw.id


}

# Associates the public route table to public subnet 1
resource "aws_route_table_association" "rta_public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id


}

# Associates the public route table to public subnet 2
resource "aws_route_table_association" "rta_public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id


}

# Creates the private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.supernet.id

  tags = {
    Project = "Tech-Challenge-2"
  }
}

# Creates the default route for the private route table
resource "aws_route" "default_route_private" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id


}

# Associates the private route table to private subnet 1
resource "aws_route_table_association" "rta_private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id


}

# Associates the private route table to private subnet 2
resource "aws_route_table_association" "rta_private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id


}
