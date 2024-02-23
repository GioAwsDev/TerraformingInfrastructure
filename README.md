# Terraforming Infrastructure

We will be utilizing Terraform to launch the following infrastructure on AWS:


VPC :
    Size: Small (2,046 Ip's) - 10.20.0.0/21
Subnets:
    2 Public Subnets in two different AZ's
        (1) 10.20.4.0/24
        (2) 10.20.5.0/24
    2 Private Subnets in two different AZ's
        (1) 10.20.6.0/24
        (2) 10.20.7.0/24
Internet Gateway
Nat Gateway:
    EIP
Route Table 1:
    Route 1 - to NAT
Route Table 2
    Route 2 - to IGW
NACL 1:
    Public Subnets
NACL 2:
    Private Subnets

You will need to update the default profile under providers.tf