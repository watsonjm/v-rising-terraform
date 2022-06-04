locals {
  common_tags = merge({
    environment = var.environment
    },
  var.common_tags)
  name_tag = var.environment
  route_table = {
    public = try(aws_route_table.public_default.id, "This route table does not exist.")
  }
}
