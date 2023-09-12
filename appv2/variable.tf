variable "ami" {
  default = "ami-0baa9e2e64f3c00db"
}

variable "instance-type" {
    default = "t3.micro"
}

variable "cap-keypair-path" {
  default = "~/keypair/Keypair2.pub"
  description = "path to my keypair"
}

variable "keyname" {
    default = "cap-keypair"  
}

variable "database_name" {
    default = "capdb"
    description = "database name"  
}

variable "database_identifier" {
    default = "capdb-id"
}

variable "Dbase_version" {
  default = "8.0.28"
  description = "database version"
}

variable "database_username" {
    default = "Admin"
    description = "dtabase username"  
}

variable "database_password" {
    default = "Admin123"
    description = "database password"   
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
    description = "VPC cidr block ip address"
}

variable "AZ1" {
    default = "eu-north-1a"
    description = "availability zone 1"
}

variable "AZ2" {
    default = "eu-north-1b"
    description = "availability zone 2"
}

variable "Psbn1" {
  default = "10.0.1.0/24"
  description = "cidr block for public subnet1"
}

variable "Psbn2" {
    default = "10.0.2.0/24"
  description = "cidr block for public subnet2"
}

variable "Prsbn1" {
    default = "10.0.3.0/24"
  description = "cidr block for private subnet1"
}

variable "Prsbn2" {
    default = "10.0.4.0/24"
  description = "cidr block for private subnet2"
}

variable "all_access_cidr" {
    default = "0.0.0.0/0"
  description = "cidr block for all access"
}

variable "http_port" {
    default = "80"
    description = "http port"
}

variable "ssh_port" {
    default = "22"
    description = "ssh port"
}
variable "https_port" {
    default = "443"
    description = "https port"
  
}
variable "mysql_port" {
    default = "3306"
    description = "Sql port"
}

variable "email" {
    default = ["victor.adepoju@cloudhight.com", "victech92@gmail.com"]
    description = "email address"
}

variable "wordpress" {
    default = "../user-data/wordpress.sh"
    description = "Instance userdata including wordpress configuration settings"
}

variable "domain_name" {
    default = "greatminds.sbs"
    description = "my domain name"
}