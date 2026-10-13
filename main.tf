module "network" {
  source = "./modules/network"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

module "web_app" {
  source = "./modules/web_app"

  project_name      = var.project_name
  environment       = var.environment
  instance_type     = var.instance_type
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
}

moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_security_group.load_balancer
  to   = module.web_app.aws_security_group.load_balancer
}

moved {
  from = aws_security_group.application
  to   = module.web_app.aws_security_group.application
}

moved {
  from = aws_instance.application
  to   = module.web_app.aws_instance.application
}

moved {
  from = aws_lb.application
  to   = module.web_app.aws_lb.application
}

moved {
  from = aws_lb_target_group.application
  to   = module.web_app.aws_lb_target_group.application
}

moved {
  from = aws_lb_target_group_attachment.application
  to   = module.web_app.aws_lb_target_group_attachment.application
}

moved {
  from = aws_lb_listener.http
  to   = module.web_app.aws_lb_listener.http
}
