variable "bucket_name" {
  type = string
  description = "Name of S3 bucket where the THML file will reside."
}

variable "aws_access_key" {
  type = string
  description = "AWS Access Key"
  sensitive = true
}


variable "aws_secret_key" {
  type = string
  description = "AWS Secret Key"
  sensitive = true
}

variable "aws_region" {
  type = string
  description = "AWS region"
  default = "us-east-1"
}

variable "instance_type" {
   type = string
   description = "EC2 instance type"
   default = "t2.micro"
}