variable "ecs_cluster_name" {
  default = "value"
  type    = string
}

variable "app_name" {
  default = "somewordpress"
  type    = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_port" {
  type = string
}

variable "db_name" {
  type = string
}

variable "wordpress_user" {
  type = string
}

variable "wordpress_email" {
  type = string
}

variable "wordpress_password" {
  type = string
}

variable "db_instance_type" {
  type    = string
  default = "db.t4g.small"
}

variable "ecs_cpu" {
  type    = string
  default = "1024"
}

variable "ecs_memory" {
  type    = string
  default = "2048"
}
