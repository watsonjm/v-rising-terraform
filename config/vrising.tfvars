common_tags = { #environment tag automatically added, add programmatic tags in local.common_tags.
  repo    = "github/v-rising-terraform"
  managed = "terraform"
}

vpc_cidr = "10.0.80.0/22"
subnets = {
  public = {
    cidr    = ["10.0.80.0/24"]
    rt      = "public"
    name    = "public-subnet"
    auto_ip = false
  }
}