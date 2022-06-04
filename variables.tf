variable "region" {
  type    = string
  default = "us-east-2"
}
variable "environment" {
  type    = string
  default = "vrising"
}
variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Map of generic tags to assign to all possible resources."
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "private_subnets" {
  type        = list(string)
  default     = null
  description = "List of private subnet IDs."
}
variable "public_subnets" {
  type        = list(string)
  default     = null
  description = "List of public subnet IDs."
}
variable "public_key_path" {
  type        = string
  default     = null
  description = "Path to your generated RSA .pub key file."
}
variable "subnets" {
  type = map(
    object({
      cidr    = list(string)
      rt      = string
      name    = string
      auto_ip = bool #this can be optional possibly in the future.
    })
  )
  default = {
    public = {
      cidr    = ["10.10.10.0/24"]
      rt      = "public"
      name    = "public-subnet"
      auto_ip = true
    }
  }
}