# Terraform AWS Secure Web Platform

A small, deployable AWS web platform built with Terraform. It demonstrates infrastructure provisioning, network design, least-privilege network access, and infrastructure validation in CI.

## Architecture

```text
Internet
   |
Application Load Balancer (HTTP :80)
   |
EC2 / Nginx (HTTP :80; accepts traffic only from the ALB)
   |
VPC across two Availability Zones
```

The Application Load Balancer spans two public subnets. The demo instance is in a public subnet only to keep the first version inexpensive and self-contained: it has no direct inbound access, no SSH rule, and its security group only permits port 80 from the ALB. A production-oriented next iteration would move the workload to private subnets and use a NAT Gateway or VPC endpoints for controlled outbound access.

## What this demonstrates

- VPC, Internet Gateway, subnets, route tables, and multi-AZ load balancing
- Separate security groups for the load balancer and the application
- No SSH ingress and IMDSv2 enforced on EC2
- AWS-managed Amazon Linux 2023 image lookup
- Reusable variables, resource tags, outputs, and Terraform version pinning
- GitHub Actions checks for `fmt` and `validate`

## Prerequisites

- Terraform 1.6+
- An AWS account and credentials configured locally (AWS CLI profile, SSO, or environment variables)
- Permission to create VPC, EC2, ELBv2, and security-group resources

## Deploy

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

After the apply completes, open the `application_url` Terraform output. The target-group health check may take a couple of minutes while Nginx installs.

## Clean up

This project creates billable AWS resources, including an Application Load Balancer and an EC2 instance. Destroy the environment immediately after testing:

```bash
terraform destroy
```

## Configuration

Defaults target `us-east-1` and use a `t3.micro` instance. Override values without committing credentials or personal settings:

```bash
terraform apply -var='aws_region=us-east-1' -var='environment=dev'
```

Files named `*.tfvars` are ignored by Git. Keep secrets out of this repository and use AWS IAM roles, SSO, or a secrets manager.

## Next steps

1. Add HTTPS with ACM and a Route 53 domain.
2. Move the application tier to private subnets.
3. Add remote Terraform state in S3 with DynamoDB locking.
4. Add CloudWatch alarms, flow logs, and a budget alert.
5. Replace the demo server with a containerized application.
