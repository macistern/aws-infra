# Terraform AWS Secure Web Platform

A small, deployable AWS web platform built with Terraform. It demonstrates infrastructure provisioning, network design, least-privilege network access, and infrastructure validation in CI.

## Repository structure

```text
.
├── main.tf                 # Root module: connects reusable child modules
├── providers.tf            # AWS provider configuration and default tags
├── variables.tf            # Deployment-level configuration
├── outputs.tf              # Outputs exposed by the root module
└── modules/
    ├── network/            # VPC, public subnets, internet gateway, and routes
    └── web_app/            # Security groups, EC2, and application load balancer
```

The root module owns deployment configuration and passes explicit inputs between child modules. Child modules do not configure providers or credentials; they inherit the AWS provider configured by the root.

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

Run these commands from the repository root. Configure AWS credentials using an AWS CLI profile, SSO, or environment variables before planning.

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
# Review the plan before approving changes.
terraform apply
```

After the apply completes, open the `application_url` Terraform output. The target-group health check may take a couple of minutes while Nginx installs.

The root configuration includes `moved` blocks for the resources that were moved into child modules. If you have an existing Terraform state from the earlier root-only layout, review `terraform plan` and confirm it shows state moves rather than destroying and recreating those resources. Do not remove the `moved` blocks until all relevant states have been migrated.

## Clean up

This project creates billable AWS resources, including an Application Load Balancer and an EC2 instance. Destroy the environment immediately after testing:

```bash
terraform destroy
```

## Configuration

Defaults target `us-east-2` and use a `t3.micro` instance. Override values without committing credentials or personal settings:

```bash
terraform apply -var='aws_region=us-east-2' -var='environment=dev'
```

Files named `*.tfvars` are ignored by Git. Keep secrets out of this repository and use AWS IAM roles, SSO, or a secrets manager. The Terraform dependency lock file (`.terraform.lock.hcl`) should be committed so local runs and CI use consistent provider versions.

## Next steps

1. Add HTTPS with ACM and a Route 53 domain.
2. Move the application tier to private subnets.
3. Add remote Terraform state in S3 with native S3 lock files.
4. Add CloudWatch alarms, flow logs, and a budget alert.
5. Replace the demo server with a containerized application.
