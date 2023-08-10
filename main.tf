provider "aws"{
  
}
#Creating VPC
resource "aws_vpc" "capstonevpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name: "capstonevpc"
  }
}

#Creating public subnet1
resource "aws_subnet" "cappub1" {
    vpc_id = aws_vpc.capstonevpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-north-1a"

    map_public_ip_on_launch = true

    tags = {
      Name: "cappub1"
    }
  
}

#Creating public subnet2
resource "aws_subnet" "cappub2" {
    vpc_id = aws_vpc.capstonevpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-north-1b"

    tags = {
      Name: "cappub2"
    }
  
}

#Creating private subnet1
resource "aws_subnet" "capprv1" {
    vpc_id = aws_vpc.capstonevpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "eu-north-1a"

    tags = {
      Name: "capprv1"
    }
  
}
#Creating private subnet2
resource "aws_subnet" "capprv2" {
    vpc_id = aws_vpc.capstonevpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "eu-north-1b"

    tags = {
      Name: "capprv1"
    }
  
}

#Creating Internet gateway
resource "aws_internet_gateway" "cap-IGW" {
    vpc_id = aws_vpc.capstonevpc.id

    tags = {
        Name: "cap-IGW"
    }
}

#Creating Elastic IP
resource "aws_eip" "cap-EIP" {
    domain = "vpc"
    depends_on = [ aws_internet_gateway.cap-IGW ]

}

#Creating NAT gateway
resource "aws_nat_gateway" "cap-NAT" {
    allocation_id = aws_eip.cap-EIP.id
    subnet_id = aws_subnet.cappub1.id
    connectivity_type = "public"
    tags = {
      Name: "cap-NAT"
    }
    depends_on = [ aws_internet_gateway.cap-IGW ]
  
}
#Creating Public Route table and route table association
resource "aws_route_table" "cappub-rt" {
    vpc_id = aws_vpc.capstonevpc.id

    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.cap-IGW.id
    }
    tags = {
      Name: "cappub-rt"
    }
}
#Creating public route table association to pub subnet 1
resource "aws_route_table_association" "public-rt-sn1" {
    subnet_id = aws_subnet.cappub1.id
    route_table_id = aws_route_table.cappub-rt.id
}
#Creating public route table association to pub subnet 2
resource "aws_route_table_association" "public-rt-sn2" {
    subnet_id = aws_subnet.cappub2.id
    route_table_id = aws_route_table.cappub-rt.id
}
#Creating private Route table and route table association
#Creating private Route table and route table association
resource "aws_route_table" "capprv-rt" {
    vpc_id = aws_vpc.capstonevpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.cap-NAT.id
    }
    tags = {
      Name: "capprv-rt"
    }
}
#Creating private route table association prv subnet 1
resource "aws_route_table_association" "private-rt-sn1" {
    subnet_id = aws_subnet.capprv1.id
    route_table_id = aws_route_table.capprv-rt.id
}
#Creating private route table association to prv subnet 2
resource "aws_route_table_association" "private-rt-sn2" {
    subnet_id = aws_subnet.capprv2.id
    route_table_id = aws_route_table.capprv-rt.id
}
#Creating Public Security group
resource "aws_security_group" "capfrontend-SG" {
    name = "frontend-SG"
    description = "frontend SG"
    vpc_id = aws_vpc.capstonevpc.id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }


  
}
#Creating Private Security group
resource "aws_security_group" "capbackend-SG" {
    name = "backend-SG"
    description = "backend SG"
    vpc_id = aws_vpc.capstonevpc.id

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [aws_security_group.capfrontend-SG.id]

    }
    ingress {
        description = "MYSQL/Aurora"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = [aws_security_group.capfrontend-SG.id]

    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
}

#Creating Multi AZ RDS
#Creating RDS subnet group

#Creating Database

#Creating S3 Bucket
#Creating S3 media bucket
resource "aws_s3_bucket" "capmedia" {
    bucket = "capmedia"
    tags = {
        Name = "cap-media"
    }
  
}
resource "aws_s3_bucket_ownership_controls" "capmedia-ct" {
    bucket = aws_s3_bucket.capmedia.id
    rule {
      object_ownership = "BucketOwnerPreferred"
    }
    depends_on = [ aws_s3_bucket_public_access_block.capmedia-pab ]
  
}
resource "aws_s3_bucket_public_access_block" "capmedia-pab" {
    bucket = aws_s3_bucket.capmedia.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
    
}
resource "aws_s3_bucket_acl" "cap-media-acl" {
    bucket = aws_s3_bucket.capmedia.id
    depends_on = [ aws_s3_bucket_ownership_controls.capmedia-ct]
    acl = "public-read"
  
}
#Creating Bucket policy
resource "aws_s3_bucket_policy" "cap-media-policy" {
    bucket = aws_s3_bucket.capmedia.id
    policy = data.aws_iam_policy_document.cap-media.json
}
data "aws_iam_policy_document" "cap-media"{   
    
    statement   {
        principals {
            type = "*"
            identifiers = ["*"]

        }
        actions = [
            "s3:GetObject"
        ]
    

        resources = [
            aws_s3_bucket.capmedia.arn,
            "${aws_s3_bucket.capmedia.arn}/*",
        ]
    }
    depends_on = [ aws_s3_bucket_public_access_block.capmedia-pab ]
}

#Creating S3 code bucket

#Creating bucket policy

#Creating log Bucket

#Creating log bucket policy

#Creating IAM role and IAM instnace profile

#Wordpress configuration and spinning up instance