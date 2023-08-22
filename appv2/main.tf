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
        cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
        #cidr_blocks = [aws_security_group.capfrontend-SG.id]
    }

    ingress {
        description = "MYSQL/Aurora"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
        #cidr_blocks = [aws_security_group.capfrontend-SG.id]
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
resource "aws_db_subnet_group" "cap-db-sn" {
    name = "cap-db-sn"
    subnet_ids = [aws_subnet.capprv1.id, aws_subnet.capprv2.id]
    tags = {
      Name = "cap-db-subnet"
    }
}

#Creating Database
resource "aws_db_instance" "capdb" {
    identifier = "capdb"
    allocated_storage = 10
    db_name = "capdb"
    engine = "mysql"
    engine_version = "8.0.33"
    instance_class = "db.t3.micro"
    publicly_accessible = false
    username = "Admin"
    password = "Admin123"
    parameter_group_name = "default.mysql8.0"
    db_subnet_group_name = "cap-db-sn"
    vpc_security_group_ids = [aws_security_group.capbackend-SG.id]
    skip_final_snapshot = true
    port = 3306
    max_allocated_storage = 1000
    apply_immediately = true
    multi_az = true
}

#Creating S3 Bucket
#Creating S3 media bucket
resource "aws_s3_bucket" "capmedia" {
    bucket = "capmedia"
    force_destroy = true
    tags = {
        Name = "cap-media"
    }
}

#
resource "aws_s3_bucket_ownership_controls" "capmedia-ct" {
    bucket = aws_s3_bucket.capmedia.id
    rule {
      object_ownership = "BucketOwnerEnforced"
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
    policy = jsonencode({
        id = cap-media-policy
        statement = [
            {
                Action = ["s3:GetObject", "s3:GetObjectVersion"]
                effect = "allow"
                principal = {
                    AWS = "*"
                }
                resource = "arn:aws:s3:::capmedia/*"
                sid = "PublicReadGetObject"
            }
        ]
        Version = "2012-10-17"
    })
    depends_on = [ aws_s3_bucket_public_access_block.capmedia-pab ]
}


#Creating S3 code bucket
resource "aws_s3_bucket" "capcode" {
    bucket = "capcode"
    force_destroy = true
    tags = {
        Name = "cap-code"
    }
}

#Creating log Bucket
resource "aws_s3_bucket" "cap-log" {
    bucket = "my-cap-log"
    force_destroy = true
}
resource "aws_s3_bucket_acl" "cap-log-acl" {
    bucket = aws_s3_bucket.cap-log.id
    depends_on = [ aws_s3_bucket_ownership_controls.cap-log-ct ]
    acl = "log-delivery-write"
}
resource "aws_s3_bucket_ownership_controls" "cap-log-ct" {
    bucket = aws_s3_bucket.cap-log.id
    rule {
      object_ownership = "BucketOwnerEnforced"
    }
    #depends_on = [ aws_s3_bucket_acl.cap-log-acl ] 
}

#Creating log bucket policy

resource "aws_s3_bucket_policy" "log-policy" {
    bucket = aws_s3_bucket.cap-log.id
    policy = jsonencode({
    id = cap-log-policy
        statement = [
            {
                Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
                effect = "allow"
                principal = {
                    AWS = "*"
                }
                resource = "arn:aws:s3:::cap-log/*"
                sid = "PublicReadGetObject"
            }
        ]
        Version = "2012-10-17"
    })  
}

#Creating IAM role and IAM instnace profile

resource "aws_iam_role" "cap-S3IAM" {
    name = "cap-S3IAM"
    assume_role_policy = data.aws_iam_policy_document.cap-S3IAM-rol.json
}
data "aws_iam_policy_document" "cap-S3IAM-rol" {
    statement {
      effect = "Allow"

      principals {
        type = "Service"
        identifiers = ["ec2.amazonaws.com"]

      }
      actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_policy" "S3IAM-policy" {
    name = "S3IAM-policy"
    description = "Access to Ec2 instnace and S3 bucket"
    policy = data.aws_iam_policy_document.cap-S3IAM-pol.json
}

data "aws_iam_policy_document" "cap-S3IAM-pol" {
    statement {
      effect = "Allow"
      actions = ["s3:*"]
      resources = ["*"]
    }
}

resource "aws_iam_role_policy_attachment" "cap-S3IAM" {
    role = aws_iam_role.cap-S3IAM.name
    policy_arn = aws_iam_policy.S3IAM-policy.arn
}

resource "aws_iam_instance_profile" "cap-S3IAM" {
  name = "cap-S3IAM"
  role = aws_iam_role.cap-S3IAM.name 
}   

#Wordpress configuration and spinning up instance
## Creating keypair
resource "aws_key_pair" "keypair" {
    key_name = "capstone-keypair"
    #public_key = file("~/devops/ssh_key_pair")
    public_key = file("~/devops/set-16-keypair.pem")
}

#Creating webserver
resource "aws_instance" "webserver" {
    ami = "ami-0ca5ef73451e16dc1"
    instance_type = "t2.micro"
    key_name = "keypair"
    subnet_id = aws_subnet.cappub1.id
    vpc_security_group_ids = [aws_security_group.capfrontend-SG.id]
    iam_instance_profile = "aws_iam_instance_profile.cap-S3IAM.id"
    associate_public_ip_address = true
    user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo yum upgrade -y
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        sudo yum install httpd php php-mysqlnd -y
        cd /var/www/html
        echo "This is a test file" > indextest.html
        sudo yum install wget -y
        wget https://wordpress.org/wordpress-6.1.1.tar.gz
        tar -xzf wordpress-6.1.1.tar.gz
        cp -r wordpress/* /var/www/html/
        rm -rf wordpress
        rm -rf wordpress-6.1.1.tar.gz
        chmod -R 755 wp-content
        chown -R apache:apache wp-content
        cd /var/www/html && mv wp-config-sample.php wp-config.php
        sed -i "s@define( 'DB_NAME', 'database_name_here' )@define( 'DB_NAME', 'capdb' )@g" /var/www/html/wp-config.php
        sed -i "s@define( 'DB_USER', 'username_here' )@define( 'DB_USER', 'Admin' )@g" /var/www/html/wp-config.php
        sed -i "s@define( 'DB_PASSWORD', 'password_here' )@define( 'DB_PASSWORD', 'Admin123' )@g" /var/www/html/wp-config.php
        sed -i "s@define( 'DB_HOST', 'localhost' )@define( 'DB_HOST', '${element(split(":", aws_db_instance.capdb.endpoint), 0)}')@g" /var/www/html/wp-config.php
        sudo chkconfig httpd on
        sudo service httpd start
        sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
        sudo reboot
        

        #sudo vi crontab
        #* * * * * ec2-user /usr/local/bin/aws s3 sync --delete s3://capcode /var/www/html/
        EOF
    tags = {
            Name = "webserver"
    }
}

#cloud front

#creating AMI
resource "aws_ami_from_instance" "cap-ami" {
    name = "cap-ami"
    source_instance_id = ""
    delete_on_termination = true
}

#Create Target group
resource "aws_lb_target_group" "cap-tg" {
    name = "cap-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.capstonevpc.id
    target_type = "instance"
}
#lb target group
resource "aws_lb_target_group_attachment" "cap-tg-attach" {
    target_group_arn = aws_lb_target_group.cap-tg.arn
    target_id = aws_instance.webserver.id
    port = 80
    depends_on = [ aws_lb_target_group.cap-tg ]
}

#Create load balancer
#Create application load balancer
resource "aws_elb" "cap-lb" {
    name = "cap-lb"
    internal = false
    load_balancer_type = "application"
    ip_address_type = "ipv4"
    security_groups = [aws_security_group.capfrontend-SG.id]
    subnets = [aws_subnet.cappub1.id, aws_subnet.cappub2.id] 
    access_logs {
      bucket = aws_s3_bucket.cap-log.id
    }
}
#Lb listner
resource "aws_lb_listener" "cap-lb-listner" {
    load_balancer_arn = aws_lb.cap-lb.arn
    port = "80"
    protocol = "HTTP"
    #ssl_policy = ""  #when using https
    #certificate_arn = ""
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.cap-tg.arn
    }  
}

#Create launch configuration
resource "aws_launch_configuration" "cap-asg-lc" {
    name = "cap-asg-lc"
    image_id = aws_ami_from_instance.cap-ami.id
    instance_type = "t2.micro"
    iam_instance_profile = aws_iam_instance_profile.cap-S3IAM.arn
    associate_public_ip_address = true
    security_groups = [aws_security_group.capfrontend-SG.id]
    key_name = "keypair"

    lifecycle {
      create_before_destroy = true
    }
    depends_on = [ aws_ami_from_instance.cap-ami ]
}

#Create Auto scaling group
resource "aws_autoscaling_group" "cap-asg" {
    name = "cap-asg"
    launch_configuration = aws_launch_configuration.cap-asg-lc.name
    vpc_zone_identifier = [aws_subnet.cappub1.id, aws_subnet.cappub2.id]
    desired_capacity = 2
    min_size = 1
    max_size = 4
    lifecycle {
      create_before_destroy = true
    }  
    force_delete = true
}

#Attaching load balancer to ASG
resource "aws_autoscaling_attachment" "cap-asg-attachment" {
    autoscaling_group_name = aws_autoscaling_group.cap-asg.id
    lb_target_group_arn = aws_lb_target_group.cap-tg.arn
}

#Creating ASG policy
resource "aws_autoscaling_policy" "cap-asg-policy" {
    name = "cap-asg-policy"
    autoscaling_group_name = aws_autoscaling_group.cap-asg.name
    target_tracking_configuration {
      predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilzation"
      }
      target_value = 30.0
    }
    estimated_instance_warmup = 300
  
}

#Hosted Zone
#Create Hosted zone
resource "aws_route53_zone" "cap-HZ" {
    name = "greatminds.sbs"  
}

#Create an record
resource "aws_route53_record" "cap-www" {
    zone_id = aws_route53_zone.cap-HZ.id
    name = "greatminds.sbs"
    type = "A"
    ttl = 300
    alias {
      name = aws_lb.cap-lb.dns_name 
      zone_id = aws_lb_cap-lb.zone_id
      evaluate_target_health = true
    }
}

#Create ACM certificate and validate SSL

#Monitoring
#Create SNS topic and subscription
resource "aws_sns_topic" "cap-update" {
    name = "cap-update"
    delivery_policy = <<EOF
    {
        "http":{
            "defaultHealthRetryPolicy": {
                "minDelayTarget":20,
                "maxDelayTarget":20,
                "numRetries" : 3,
                "numMaxDelayRetries" :0,
                "numNoDelayRetries" :0,
                "numMinDelayRetries" :0,
                backoffFunction": "linear"
            },
            "disableSubscriptionOverrides":false,
            "defaultThrottlePolicy": {
                "maxReceivesPerSecond" :1
            }
        }
    }
    EOF
}
#SNS subcription
resource "aws_sns_topic_subscription" "cap-sns-sub" {
    topic_arn = aws_sns_topic.cap-update.arn
    protocol = "email"
    endpoint = "victor.adepoju@cloudhight.com"
}
#Create cloudwatch dashboard for EC2 instance and auto scaling group
resource "aws_cloudwatch_dashboard" "cap-dashboard" {
    dashboard_name = "cap-dashboard"
    dashboard_body = jsonencode({
        widget = [
            {
                type = "metric"
                x = 0
                y = 0
                width = 12
                height = 6
                properties = {
                    metric = [
                        [
                            "AWS/EC2",
                        "CPUUtilization",
                        "InstanceId",
                        "i-012345"
                        ]
                    ]
                    period = 300
                    stat = "Average"
                    region = "eu-north"
                    title = "EC2 Instance CPU"
                }
            },
            {
               type = "text"
                x = 0
                y = 7
                width = 3
                height = 3
                properties = {
                    markdown = "Hello world"
                }
            }
        ]
    })
  
}
#Create cloud watch metric for EC2 instance and auto scaling group

#Simulate failure and stress