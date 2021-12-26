/*
This is a way to separate the variable declaration from actual TF objects declaration.
In the end, Terraform will merge the *.tf files into one during execution.
*/

variable "cidr" {
  default = "0.0.0.0/0"
  type = string
  description = ""
}

#variable "my_array" {
#  type = list(string)
#}


#variable "my_object" {
#  type = object({
#      Name =  "my_first_private_cloud" 
#  })
#}