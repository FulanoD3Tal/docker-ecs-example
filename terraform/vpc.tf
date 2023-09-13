data "aws_availability_zones" "available" {

}

resource "aws_vpc" "strapi_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    env = "strapi"
  }
}

resource "aws_internet_gateway" "strapi_vpc_igw" {
  vpc_id = aws_vpc.strapi_vpc.id
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.strapi_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.1.0/24"
  tags = {
    name = "public-subnet"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.strapi_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.2.0/24"
  tags = {
    name = "public-subnet"
  }
}

resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.strapi_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.strapi_vpc_igw.id
  }
}

resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_table.id
}
resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_table.id
}

resource "aws_alb" "vite_load_balancer" {
  name               = "vite-balancer-dev"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.lb_sg.id]
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.strapi_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.strapi_vpc.id
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_alb.vite_load_balancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
