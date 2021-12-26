variable "cidr_blocks" {
  type        = list(string)
  description = "List of CIDR Blocks to use in VPC"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}
# variable "availability_zones" {
#   type        = list(string)
#   description = "List of AZs to use"
# }
variable "create_count" {
  type        = number
  description = "How many resources to create"
  default     = 1
}
