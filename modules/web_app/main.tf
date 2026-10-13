data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "load_balancer" {
  name        = "${var.project_name}-${var.environment}-alb"
  description = "Allows public HTTP traffic to the application load balancer."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "application" {
  name        = "${var.project_name}-${var.environment}-app"
  description = "Only accepts HTTP traffic from the load balancer."
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  egress {
    description = "Outbound traffic for package updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "application" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.application.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="description" content="Matías Cisterna — DevOps Engineer">
        <title>Matías Cisterna | DevOps Engineer</title>
        <style>
          :root { color-scheme: dark; font-family: Inter, ui-sans-serif, system-ui, sans-serif; }
          body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #0b1020; color: #e7edf8; }
          main { width: min(680px, calc(100% - 3rem)); padding: 3rem; border: 1px solid #263453; border-radius: 20px; background: #121a2f; box-shadow: 0 24px 70px rgba(0, 0, 0, .35); }
          .eyebrow { margin: 0 0 .75rem; color: #6ee7b7; font-size: .8rem; font-weight: 700; letter-spacing: .14em; text-transform: uppercase; }
          h1 { margin: 0; font-size: clamp(2.2rem, 7vw, 4rem); line-height: 1; }
          .role { margin: 1rem 0; color: #b8c5df; font-size: 1.25rem; }
          .bio { max-width: 58ch; color: #d2daea; line-height: 1.65; }
          nav { display: flex; flex-wrap: wrap; gap: .75rem; margin-top: 2rem; }
          a { padding: .8rem 1.05rem; border-radius: 9px; color: #07131e; background: #6ee7b7; font-weight: 750; text-decoration: none; }
          a:hover, a:focus-visible { background: #a7f3d0; outline: 3px solid #fff; outline-offset: 3px; }
          footer { margin-top: 2.5rem; color: #8290ae; font-size: .9rem; }
        </style>
      </head>
      <body>
        <main>
          <h1>Matías Cisterna</h1>
          <p class="role">DevOps Engineer · Cloud Infrastructure &amp; Automation</p>
          <p class="bio">I build reliable infrastructure, automate operations, and bring a database-administration mindset to cloud platforms and observability.</p>
          <nav aria-label="Contact links">
            <a href="https://github.com/macistern">GitHub</a>
            <a href="https://www.linkedin.com/in/esteban-matias-cisterna/">LinkedIn</a>
          </nav>
          <footer>Built on AWS with Terraform, an Application Load Balancer, and Nginx.</footer>
        </main>
      </body>
    </html>
    HTML
    systemctl enable --now nginx
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app"
    Role = "application"
  }
}

resource "aws_lb" "application" {
  name                       = "${var.project_name}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.load_balancer.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "application" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "application" {
  target_group_arn = aws_lb_target_group.application.arn
  target_id        = aws_instance.application.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}
