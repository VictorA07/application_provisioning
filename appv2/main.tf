#Creating VPC
resource "aws_vpc" "capstonevpc" {
  cidr_block = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name: "capstonevpc"
  }
}

#Creating public subnet1
resource "aws_subnet" "cappub1" {
  vpc_id = aws_vpc.capstonevpc.id
  cidr_block = var.Psbn1
  availability_zone = var.AZ1
  map_public_ip_on_launch = true
  tags = {
    Name: "cappub1"
  }
}

#Creating public subnet2
resource "aws_subnet" "cappub2" {
  vpc_id = aws_vpc.capstonevpc.id
  cidr_block = var.Psbn2
  availability_zone = var.AZ2
  tags = {
    Name: "cappub2"
  }
}

#Creating private subnet1
resource "aws_subnet" "capprv1" {
  vpc_id = aws_vpc.capstonevpc.id
  cidr_block = var.Prsbn1
  availability_zone = var.AZ1
  tags = {
    Name: "capprv1"
  }
}

#Creating private subnet2
resource "aws_subnet" "capprv2" {
  vpc_id = aws_vpc.capstonevpc.id
  cidr_block = var.Prsbn2
  availability_zone = var.AZ2
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
resource "aws_nat_gateway" "cap-NGW" {
  allocation_id = aws_eip.cap-EIP.id
  subnet_id = aws_subnet.cappub1.id
  connectivity_type = "public"
  tags = {
    Name: "cap-NGW"
  }
  depends_on = [ aws_internet_gateway.cap-IGW ]
}

#Creating Public Route table and route table association
resource "aws_route_table" "cappub-rt" {
  vpc_id = aws_vpc.capstonevpc.id
  route {
    cidr_block = var.all_access_cidr
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
resource "aws_route_table" "capprv-rt" {
  vpc_id = aws_vpc.capstonevpc.id
  route {
    cidr_block = var.all_access_cidr
    nat_gateway_id = aws_nat_gateway.cap-NGW.id
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
# ssh inbound rule
  ingress {
    description = "SSH"
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = [var.all_access_cidr]
  }
# http inbound rule
  ingress {
    description = "HTTP"
    from_port = var.http_port
    to_port = var.http_port
    protocol = "tcp"
    cidr_blocks = [var.all_access_cidr]
  }
# https inbound rule
  ingress {
    description = "HTTP"
    from_port = var.http_port
    to_port = var.http_port
    protocol = "tcp"
    cidr_blocks = [var.all_access_cidr]
  }
# outbound rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.all_access_cidr]
  }
}

#Creating Private Security group
resource "aws_security_group" "capbackend-SG" {
  name = "backend-SG"
  description = "backend SG"
  vpc_id = aws_vpc.capstonevpc.id

  ingress {
    description = "SSH"
    from_port = var.ssh_port
    to_port = var.ssh_port
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
    #cidr_blocks = [aws_security_group.capfrontend-SG.id]
  }

  ingress {
    description = "MYSQL/Aurora"
    from_port = var.mysql_port
    to_port = var.mysql_port
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
    #cidr_blocks = [aws_security_group.capfrontend-SG.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.all_access_cidr]
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
  identifier = var.database_identifier
  allocated_storage = 10
  db_name = var.database_name
  engine = "mysql"
  engine_version = var.Dbase_version
  instance_class = "db.t3.micro"
  publicly_accessible = false
  username = var.database_username
  password = var.database_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.cap-db-sn.id
  vpc_security_group_ids = [aws_security_group.capbackend-SG.id]
  skip_final_snapshot = true
  port = var.mysql_port
  max_allocated_storage = 1000
  apply_immediately = true
  #multi_az = true
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

#aws_s3_bucket_ownership_controls
resource "aws_s3_bucket_ownership_controls" "capmedia-ct" {
    bucket = aws_s3_bucket.capmedia.id
    rule {
      object_ownership = "BucketOwnerEnforced"
    }
    depends_on = [ aws_s3_bucket_public_access_block.capmedia-pab ]
}

#aws_s3_bucket_public_access_block"
resource "aws_s3_bucket_public_access_block" "capmedia-pab" {
    bucket = aws_s3_bucket.capmedia.id
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false   
}

#aws_s3_bucket_acl
resource "aws_s3_bucket_acl" "cap-media-acl" {
    bucket = aws_s3_bucket.capmedia.id
    depends_on = [ aws_s3_bucket_ownership_controls.capmedia-ct]
    acl = "public-read"
}

#Creating Bucket policy
resource "aws_s3_bucket_policy" "cap-media-policy" {
    bucket = aws_s3_bucket.capmedia.id
    policy = jsonencode({
        id = "cap-media-policy"
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
    id = "cap-log-policy"
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

#aws_iam_policy
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
    key_name = var.keyname
    public_key = file(var.cap-keypair-path)
}

#Creating webserver
resource "aws_instance" "webserver" {
    ami = var.ami
    instance_type = var.instance-type
    key_name = var.keyname
    subnet_id = aws_subnet.cappub1.id
    vpc_security_group_ids = [aws_security_group.capfrontend-SG.id]
    iam_instance_profile = "aws_iam_instance_profile.cap-S3IAM.id"
    associate_public_ip_address = true
    user_data = templatefile(var.wordpress, {
    database_name = var.database_name,
    database_username = var.database_username,
    database_password = var.database_password,
    db_endpoint= aws_db_instance.capdb.endpoint,
    cloud_front_name = data.aws_cloudfront_distribution.cap-cloudfront.domain_name,
    REQUEST_FILENAME = "{REQUEST_FILENAME}"
    })
    tags = {
            Name = "webserver"
    }
}

#cloud front distribution
locals {
  s3_origin_id = "aws_s3_bucket.capmedia.bucket"
}
resource "aws_cloudfront_distribution" "cap-cldfront" {
    origin {
      domain_name = aws_s3_bucket.capmedia.bucket_domain_name
      origin_id = local.s3_origin_id
    }
    enabled = true
    # is_ipv6_enabled = true
    # default_root_object = "index.html"

    # logging_config {
    #     include_cookies = false
    #     bucket = "cap-log.s3.amazonaws.com"
    #     prefix = "mylog"
    #   }
    #   aliases = [var.domain_name]

    default_cache_behavior {
      allowed_methods = ["GET", "POST", "PUT", "DELETE", "PATCH","HEAD", "OPTIONS"]
      cached_methods = ["GET", "HEAD"]
      target_origin_id = local.s3_origin_id

      forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
      }
      viewer_protocol_policy = "allow-all"
      min_ttl = 0
      default_ttl = 0
      max_ttl = 600
    }
    price_class = "PriceClass_All"
    restrictions {
      geo_restriction {
        restriction_type = "none"
      }
    }
    
    viewer_certificate{
      cloudfront_default_certificate = true
    }
    
}

#Exporting from CloudFront
data "aws_cloudfront_distribution" "cap-cloudfront" {
  id = aws_cloudfront_distribution.cap-cldfront.id
  
}

#creating AMI
resource "aws_ami_from_instance" "cap-ami" {
    name = "cap-ami"
    source_instance_id = aws_instance.webserver.id
    snapshot_without_reboot = true
    depends_on = [ aws_instance.webserver, time_sleep.EC2-wait-time ]
}

#Sleep time to delay AMI resoures creation
resource "time_sleep" "EC2-wait-time" {
    depends_on = [ aws_instance.webserver ]
    create_duration = "300s"  
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
resource "aws_lb" "cap-lb" {
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
    instance_type = var.instance-type
    iam_instance_profile = aws_iam_instance_profile.cap-S3IAM.arn
    associate_public_ip_address = true
    security_groups = [aws_security_group.capfrontend-SG.id]
    key_name = var.keyname

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
    health_check_type = "EC2"
    health_check_grace_period = 300
    lifecycle {
      create_before_destroy = true
    }  
    force_delete = true
    tag {
      key = "cap-asg"
      value = "asg"
      propagate_at_launch = true
    }
}

#Attaching load balancer to ASG
resource "aws_autoscaling_attachment" "cap-asg-attachment" {
    autoscaling_group_name = aws_autoscaling_group.cap-asg.id
    lb_target_group_arn = aws_lb_target_group.cap-tg.arn
}

#Creating ASG policy
resource "aws_autoscaling_policy" "cap-asg-policy" {
    name = "cap-asg-policy"
    scaling_adjustment = 4
    adjustment_type = "ChangeInCapcity"
    autoscaling_group_name = aws_autoscaling_group.cap-asg.name
    policy_type = "TargetTrackingScaling"
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
data "aws_route53_zone" "cap-HZ" {
    name = "greatminds.sbs"  
}

#Create an record
resource "aws_route53_record" "cap-www" {
    zone_id = data.aws_route53_zone.cap-HZ.id
    name = "www.${data.aws_route53_zone.cap-HZ.name}"
    type = "A"
    #ttl = 300
    alias {
      name = aws_lb.cap-lb.dns_name 
      zone_id = aws_lb.cap-lb.zone_id
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
      "backoffFunction": "linear"
  },
    "disableSubscriptionOverrides":false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond" :1
    }
  }
}
EOF
}

locals {
  emails = var.email
}
#SNS subcription
resource "aws_sns_topic_subscription" "cap-sns-sub" {
  count = length(local.emails)
    topic_arn = aws_sns_topic.cap-update.arn
    protocol = "email"
    endpoint = local.emails[count.index]
}
#Create cloudwatch dashboard for EC2 instance
resource "aws_cloudwatch_dashboard" "cap-ec2-dashboard" {
  dashboard_name = "cap-ec2-dashboard"
  dashboard_body = jsonencode({
    widget = [
      {
        type = "metric"
        properties = {
          metric = [
              [ "AWS/EC2", "CPUUtilization", "InstanceId", "${aws_instance.webserver.id}", {"label": "Average CPU utilization"}]
          ]
          period = 300
          stat = "Average"
          view = "timeSeries"
          region = "eu-north-1"
          title = "Average CPU Ultilization"
          stacked = false
          yAxis = {
            left = {
              label = "Percentage"
              showUnit = true
            }
          }
        }
      },
    ]
  }) 
}
#Create cloudwatch dashboard for auto scaling group
resource "aws_cloudwatch_dashboard" "cap-asg-dashboard" {
  dashboard_name = "cap-asg-dashboard"
  dashboard_body = jsonencode({
    widget = [
      {
        type = "metric"
        properties = {
          metric = [
              [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${aws_autoscaling_group.cap-asg.id}", {"label": "Average CPU utilization"}]
          ]
          period = 300
          stat = "Average"
          view = "timeSeries"
          region = "eu-north-1"
          title = "Average CPU Ultilization"
          stacked = false
          yAxis = {
            left = {
              label = "Percentage"
              showUnit = true
            }
          }
        }
      },
    ]
  }) 
}
#Create cloud watch metric for EC2 instance
resource "aws_cloudwatch_metric_alarm" "cap-ec2-cloudwatch-alarm" {
  alarm_name = "cap-ec2-cloudwatch-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 80
  alarm_description = "This metric monitors EC2 CPU utilization"
  insufficient_data_actions = []  
}
#Create cloud watch metric for autoscaling group

resource "aws_cloudwatch_metric_alarm" "cap-asg-cloudwatch-alarm" {
  alarm_name = "cap-asg-cloudwatch-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  threshold = 80
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cap-asg.name
  }
  alarm_description = "This metric monitors EC2 CPU utilization"
  alarm_actions = [aws_autoscaling_policy.cap-asg-policy.arn]  
}


#Simulate failure and stress