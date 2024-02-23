resource "aws_vpc" "ProjectAVPC" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = "10.20.0.0/21"
  enable_dns_hostnames             = false
  enable_dns_support               = true
  instance_tenancy                 = "default"
  tags = {
    Name = "ProjectaVPC"
  }
}


data "aws_ami" "linux_ami" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_subnet" "websubnet1" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1a"
  cidr_block                      = "10.20.4.0/24"
  map_public_ip_on_launch         = true
  tags = {
    Name = "Public Subnet1"
  }
  vpc_id = aws_vpc.ProjectAVPC.id

}


resource "aws_subnet" "websubnet2" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1b"
  cidr_block                      = "10.20.5.0/24"
  map_public_ip_on_launch         = true
  tags = {
    Name = "Public subnet 2"
  }
  vpc_id = aws_vpc.ProjectAVPC.id

}

resource "aws_subnet" "appsubnet1" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1a"
  cidr_block                      = "10.20.6.0/24"
  map_public_ip_on_launch         = false
  tags = {
    Name = "Private Subnet 1"
  }
  vpc_id = aws_vpc.ProjectAVPC.id

}

resource "aws_subnet" "appsubnet2" {
  assign_ipv6_address_on_creation = false
  availability_zone               = "us-east-1b"
  cidr_block                      = "10.20.7.0/24"
  map_public_ip_on_launch         = false
  tags = {
    Name = "Private Subnet 2"
  }
  vpc_id = aws_vpc.ProjectAVPC.id

}

resource "aws_internet_gateway" "ProjectAigw" {
  tags = {
    Name = "ProjectA IGW"
  }
  vpc_id = aws_vpc.ProjectAVPC.id
}

resource "aws_eip" "ProjectAEIP" {
  public_ipv4_pool = "amazon"
  tags             = {}
  domain           = "vpc"

}

resource "aws_nat_gateway" "ProjectAnatgw" {
  allocation_id = aws_eip.ProjectAEIP.id
  subnet_id     = aws_subnet.websubnet1.id
  tags          = {}
}

resource "aws_route_table" "ProjectARTNAT" {
  propagating_vgws = []
  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      egress_only_gateway_id     = ""
      gateway_id                 = ""
      instance_id                = null
      ipv6_cidr_block            = null
      nat_gateway_id             = aws_nat_gateway.ProjectAnatgw.id
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_peering_connection_id  = ""
      local_gateway_id           = ""
      vpc_endpoint_id            = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      core_network_arn           = ""
    },
  ]
  tags   = {}
  vpc_id = aws_vpc.ProjectAVPC.id
}

resource "aws_route_table_association" "NatGWTableAssoc" {
  route_table_id = aws_route_table.ProjectARTNAT.id
  subnet_id      = aws_subnet.appsubnet1.id
}

resource "aws_route_table_association" "NatGWTableAssoc2" {
  route_table_id = aws_route_table.ProjectARTNAT.id
  subnet_id      = aws_subnet.appsubnet2.id
}

resource "aws_route_table" "ProjectARTIGW" {
  propagating_vgws = []
  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      egress_only_gateway_id     = ""
      gateway_id                 = aws_internet_gateway.ProjectAigw.id
      instance_id                = null
      ipv6_cidr_block            = null
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_peering_connection_id  = ""
      "local_gateway_id"         = ""
      "vpc_endpoint_id"          = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      core_network_arn           = ""
    },
  ]
  tags   = {}
  vpc_id = aws_vpc.ProjectAVPC.id
}

resource "aws_route_table_association" "IGWTableAssoc" {
  route_table_id = aws_route_table.ProjectARTIGW.id
  subnet_id      = aws_subnet.websubnet1.id
}

resource "aws_route_table_association" "IGWTableAssoc2" {
  route_table_id = aws_route_table.ProjectARTIGW.id
  subnet_id      = aws_subnet.websubnet2.id
}

resource "aws_network_acl" "PublicACL" {
  vpc_id = aws_vpc.ProjectAVPC.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 32768
    to_port    = 65535
  }

  tags = {
    Name = "PublicACL"
  }
}

resource "aws_network_acl_association" "PublicACLAssoc" {
  network_acl_id = aws_network_acl.PublicACL.id
  subnet_id      = aws_subnet.websubnet1.id
}

resource "aws_network_acl_association" "PublicACLAssoc2" {
  network_acl_id = aws_network_acl.PublicACL.id
  subnet_id      = aws_subnet.websubnet2.id
}

resource "aws_network_acl" "PrivateACL" {
  vpc_id = aws_vpc.ProjectAVPC.id

  egress {
    protocol   = "icmp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 32768
    to_port    = 65535
  }


  tags = {
    Name = "PrivateACL"
  }
}

resource "aws_network_acl_association" "PrivateACL" {
  network_acl_id = aws_network_acl.PrivateACL.id
  subnet_id      = aws_subnet.appsubnet1.id
}

resource "aws_network_acl_association" "PrivateACL2" {
  network_acl_id = aws_network_acl.PrivateACL.id
  subnet_id      = aws_subnet.appsubnet2.id
}

resource "aws_security_group" "WebServerSG" {
  name        = "WebServerPublic"
  description = "Allow  inbound traffic"
  vpc_id      = aws_vpc.ProjectAVPC.id
  tags = {
    Name = "PublicWebServer"
  }
}

resource "aws_security_group_rule" "WebServerSgRule1" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WebServerSG.id
}

resource "aws_security_group_rule" "WebServerSgRule2" {
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WebServerSG.id
}

resource "aws_security_group" "AppServerSG" {
  name        = "AppServerPrivate"
  description = "PrivateSG"
  vpc_id      = aws_vpc.ProjectAVPC.id
  tags = {
    Name = "PrivateWebServer"
  }
}

resource "aws_security_group_rule" "APPServerSGRule" {
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "-1"
  source_security_group_id = aws_security_group.WebServerSG.id
  security_group_id        = aws_security_group.AppServerSG.id
}

resource "aws_security_group_rule" "APPServerSGRule2" {
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.AppServerSG.id
}

resource "aws_iam_instance_profile" "AppServerProfile" {
  name = "AppServerProfile"
  role = aws_iam_role.AppServerRole.name
}

resource "aws_iam_role" "AppServerRole" {
  name = "AppServerRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "AppServerRoleAttach" {
  role       = aws_iam_role.AppServerRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "AppServerProfile2" {
  name = "AppServerProfile2"
  role = aws_iam_role.AppServerRole2.name
}

resource "aws_iam_role" "AppServerRole2" {
  name = "AppServerRole2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "AppServer2RoleAttach" {
  role       = aws_iam_role.AppServerRole2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}


