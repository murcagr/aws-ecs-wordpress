### ECS Configuration###
resource "aws_ecs_cluster" "wordpress" {
  name = "${var.app_name}-ecs-cluster"
}
resource "aws_ecs_service" "wordpress" {
  name            = "${var.app_name}-ecs-service"
  cluster         = aws_ecs_cluster.wordpress.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_service.id]
  }


  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress_http.arn
    container_name   = "wordpress"
    container_port   = local.container_port
  }
}

resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.app_name}-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = data.template_file.wp_task_definition.rendered

  depends_on = [aws_iam_role.ecs_task_execution_role]
}

data "template_file" "wp_task_definition" {
  template = file("${path.module}/ecs-task-definitions/wordpress.json")
  vars = {
    ecs_task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    db_host                     = "${module.rds.db_instance_address}"
    db_port                     = "3306"
    # db_host = "${module.rds.db_instance_address}"
    db_user     = var.db_user
    db_password = var.db_password
    db_name     = var.db_name
    db_port = var.db_port
    wp_title    = "wordpress"
    wp_user     = var.wordpress_user
    wp_password = var.wordpress_password
    wp_mail     = var.wordpress_email
  }
}


### ECS security group config ###
resource "aws_security_group" "ecs_service" {
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port        = local.container_port
    to_port          = local.container_port
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
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

### ECS IAM SETUP ###

data "aws_iam_policy_document" "service_assume" {
  statement {
    sid     = "ECSServiceAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service" {
  name                  = "test"
  assume_role_policy    = data.aws_iam_policy_document.service_assume.json
  force_detach_policies = true

}

data "aws_iam_policy_document" "elb_access" {
  statement {
    sid       = "ECSService"
    resources = ["*"]

    actions = [
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets"
    ]
  }
}
#
resource "aws_iam_policy" "elb_access" {
  name   = "allow-elb-interactions"
  policy = data.aws_iam_policy_document.elb_access.json
}


resource "aws_iam_role_policy_attachment" "elb_access" {
  role       = aws_iam_role.service.name
  policy_arn = aws_iam_policy.elb_access.arn
}



# ECS task execution policy
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid       = "S3Service"
    resources = ["*"]

    actions = [
      "s3:*",
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "allow-s3-interactions"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.service.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}