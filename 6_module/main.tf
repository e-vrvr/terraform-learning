provider "aws" {

}

module "apache" {
  source = ".//terraform-aws-apache-s3-example"

  bucket_name    = "apache-example-bucket-001"
  aws_access_key = "AKIAWXFD32DDRAK5ATOM"
  aws_secret_key = "hYP4VCY2WjH+0VRpbHUbQiMn/OXh0TI+gagmJlw8"
  aws_region     = "us-east-1"
  instance_type  = "t2.micro"

}
