resource "aws_lb" "wordpress" {
  name               = "${var.app_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = module.vpc.public_subnets
  tags               = local.tags
}

resource "aws_security_group" "lb" {
  vpc_id = module.vpc.vpc_id
  name   = "${var.app_name}-lb-sg"

  ingress {
    from_port        = local.https_port
    to_port          = local.https_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = local.http_port
    to_port          = local.http_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb_listener" "wordpress_http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_http.arn
  }
}

resource "aws_lb_target_group" "wordpress_http" {
  name        = "${var.app_name}-lb-tg"
  port        = local.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  #   lifecycle {
  #     create_before_destroy = true
  #   }
  health_check {
    matcher = "200-499"
    port    = local.container_port
  }
  
  tags = local.tags
}
