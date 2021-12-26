# Datasource is the way to grab some information from the Cloud provider
/*
data "aws_vpc" "test-vpc" {
  filter {
    name = "tag:Name"
    values = [ "test-name" ]
  }
}


output "test_vpc_id" {
  value = data.aws_vpc.test-vpc.id
}
*/