Description
-----------

This repository contains Terraform code to deploy Wordpress on ECS.

Infrastructure setup
--------------------

**VPC and Subnets:**

The code utilizes the `terraform-aws-modules/vpc` module to create a VPC (Virtual Private Cloud) defining the overall network for your application. Local variables subdivide the VPC into public, database, and private subnets. Public subnets allow inbound internet traffic, while private and database subnets are for internal resources without direct internet access.

**Security Groups:**

Several security groups are defined for access control:

-   `lb`: Allows inbound traffic on HTTP(80) and HTTPS(443) ports from anywhere (0.0.0.0/0) for the Application Load Balancer.
-   `ecs_service`: Allows inbound traffic on the container port (`local.container_port`) from within the VPC for communication between ECS tasks and the database.
-   `db_local`: Allows inbound traffic on the DB port (`var.db_port`) from within the VPC for communication between the WordPress container and the database.

**Application Load Balancer (ALB):**

An Application Load Balancer (ALB) is created using the `aws_lb` resource. It distributes incoming traffic across multiple ECS tasks running your WordPress application.

**ECS Cluster and Service:**

-   An ECS cluster (`aws_ecs_cluster`) manages containerized application.
-   An ECS service (`aws_ecs_service`), deployed using the Fargate launch type, runs the WordPress application as a containerized task on the ECS cluster.
-   The service references the task definition (`aws_ecs_task_definition`) that specifies the container image and configurations.
-   The service also links the load balancer target group (`aws_lb_target_group`) to route traffic to the ECS tasks.

**ECS Task Definition:**

The `aws_ecs_task_definition` defines the containerized application.

-   It uses a template file (`data.template_file`) to dynamically inject environment variables like database connection details.
-   The task definition specifies the IAM role (`aws_iam_role`) that grants the ECS tasks necessary permissions to run and access resources.

**Database (RDS):**

A separate Terraform module (`terraform-aws-modules/rds`) deploys a MySQL database instance on AWS RDS (Relational Database Service). The database instance resides in a private subnet within the VPC.

**IAM Roles and Policies:**

-   An IAM role named `ecs_task_execution_role` allows ECS tasks to assume the role and access resources they need.
-   Several IAM policies are defined and attached to roles:
    -   `service-assume`: Allows the ECS service to assume the `ecs_task_execution_role`.
    -   `allow-elb-interactions`: Grants the ECS service role permissions to interact with the Application Load Balancer.
    -   `allow-s3-interactions` (commented out): Grants the ECS service role permissions to interact with S3 buckets.
    -   `service-role/AmazonECSTaskExecutionRolePolicy` (pre-defined): Allows ECS tasks to access resources needed for execution.

**Additional Resources:**

-   `aws_availability_zones`: Retrieves available zones in the deployment region.
-   `s3_bucket`: Defines a private S3 bucket for storing WordPress media files (commented out).

Deployment Steps
----------------
### Prerequisites

-   Preinstalled Terraform ~>v1.8.5
-   AWS credentials

### Deployment steps
1. Export AWS credentials or login using sso
2. Configure the Terraform configuration with your desired variables (e.g., `db_user`, `db_password`, `db_name`)
3.  Initialize Terraform: `terraform init`
4.  Apply the configuration: `terraform apply`

This code provisions all the resources and deploys your WordPress application on ECS with Fargate, offering a scalable and secure deployment on AWS.

WP Offload Plugin
-----------------

The task required installing the WP Offload Media Plugin. However, there are challenges:

-   The plugin is paid and requires credentials to the plugin composer repository.
-   The free WP Offload Media Lite version is not listed in the default repository or on https://composer.deliciousbrains.com/packages.json, making composer installation impossible.

Therefore, the WP Offload plugin is not installed, but three solutions are provided if the plugin becomes accessible:
- Fast: edit ECS entrypoint to add composer repository, edit wp-config.php to work with IAM ecs-task-execution role. 
- Prebuild: prebuild wordpress image with added composer repository and edited wp-config.php 
- Volume-based: Use persistent volume.

Infrastructure Improvements
-----------------

The document also highlights areas for infrastructure improvement:

-   **Reduced IAM Role Scope:**
    -   Implement the principle of least privilege. Grant IAM roles only the permissions necessary for their specific tasks within the application.
-   **HTTPS and R53 Record:**
    -   Configure HTTPS for secure communication between clients and the application.
    -   Set up a Route 53 record for application's domain name.
-   **Scaling:**
    -   Implement autoscaling mechanisms to automatically adjust resources based on traffic demands.
-   **Automated RDS Backups:**
    -   Configure automated backups for your RDS database instance to ensure data protection.
-   **Remote State:**
    -   Utilize a remote state management solution like Terraform Cloud or backendless options for managing infrastructure state.
-   **Enhanced Outputs:**
    -   Provide more informative outputs from Terraform commands to improve post-deployment monitoring and troubleshooting.
-   **Secret Manager for Passwords:**
    -   Leverage AWS Secrets Manager to securely store sensitive information like database credentials. This eliminates the need to store passwords directly in Terraform configuration files.