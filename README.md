# EC2 Web Application with Terraform

A complete infrastructure-as-code project to deploy a **Python Flask web application** on **AWS EC2** with **PostgreSQL RDS**, **Application Load Balancer**, and **VPC networking**.

## 📋 Architecture

```
╔─────────────────────────────────────╗
│         Internet (0.0.0.0/0)        │
╚────────────────┬────────────────────╝
                 │
         ┌───────▼────────┐
         │  ALB (Port 80) │
         └───────┬────────┘
                 │
         ┌───────▼──────────────────┐
         │   Public Subnets (2x)    │
         │   NAT Gateway Setup      │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │   Private Subnets (2x)   │
         │  EC2 Instances (2x)      │
         │  Python Flask Apps       │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │  RDS PostgreSQL DB       │
         │  Private Subnet          │
         └──────────────────────────┘
```

## 🛠️ Components

### Infrastructure
- **VPC** with 2 public and 2 private subnets across 2 AZs
- **Internet Gateway** for public internet access
- **NAT Gateways** for private subnet egress
- **Application Load Balancer** for traffic distribution
- **Security Groups** for access controls
- **IAM Roles** for secure EC2 permissions

### Compute
- **2x EC2 t2.micro instances** (customizable)
- **Ubuntu 22.04 LTS** AMI
- **Python 3 environment** with Flask
- **Systemd service** for application management
- **Health checks** via ALB

### Database
- **PostgreSQL 15.3** on RDS
- **db.t3.micro** instance (customizable)
- **20GB** auto-provisioned storage
- **Private subnet deployment** (no public access)
- **Automated backups** (7-day retention)

## 📦 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 ([Install](https://www.terraform.io/downloads))
3. **AWS CLI** ([Install](https://aws.amazon.com/cli/))
4. **Git** (optional, for version control)

## 🚀 Quick Start

### Step 1: Configure AWS Credentials

```bash
aws configure
# or use environment variables:
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2: Customize Configuration

Edit `terraform/terraform.tfvars`:

```hcl
aws_region     = "us-east-1"      # Change region if needed
instance_count = 2                  # Number of EC2 instances
instance_type  = "t2.micro"         # Instance type
db_name        = "myappdb"          # Database name
db_username    = "admin"            # DB admin user
```

### Step 3: Initialize Terraform

```bash
cd ec2-webapp/terraform
terraform init
```

### Step 4: Plan the Deployment

```bash
terraform plan \
  -var="db_password=YourSecurePassword123!" \
  -out=tfplan
```

**Review the plan carefully** — it will show all resources being created.

### Step 5: Apply the Configuration

```bash
terraform apply tfplan
```

This will:
- Create VPC and networking
- Set up security groups
- Provision RDS database
- Launch EC2 instances
- Configure ALB
- Deploy Python Flask application
- Start the web application

⏱️ **Deployment time**: 10-15 minutes (RDS takes the longest)

### Step 6: Verify Deployment

Once Terraform completes, get the ALB DNS name:

```bash
terraform output alb_dns_name
```

Access your application:

```bash
curl http://<alb_dns_name>
```

You should see the **EC2 Web Application** page with instance info and database status.

## 📊 Monitoring Outputs

View all deployment outputs:

```bash
terraform output
```

Key outputs:
- **alb_dns_name**: URL to access your application
- **rds_endpoint**: Database connection string
- **ec2_instance_ids**: ID of deployed instances
- **vpc_id**: VPC identifier

## 🧹 Cleanup

To destroy all resources and avoid AWS charges:

```bash
terraform destroy
```

Type `yes` when prompted. This will delete:
- All EC2 instances
- RDS database (snapshot will be skipped)
- VPC, subnets, NAT gateways
- ALB and target groups
- Security groups

## 📝 Project Structure

```
ec2-webapp/
├── terraform/
│   ├── provider.tf          # AWS provider configuration
│   ├── variables.tf         # Variable definitions
│   ├── terraform.tfvars     # Value assignments
│   ├── vpc.tf              # VPC, subnets, routing
│   ├── security_groups.tf  # Security group rules
│   ├── alb.tf              # Load balancer config
│   ├── rds.tf              # Database configuration
│   ├── ec2.tf              # EC2 instance config
│   ├── outputs.tf          # Output values
│   └── .terraform/         # Terraform state (auto-generated)
├── scripts/
│   └── user_data.sh        # EC2 bootstrap script
├── app/
│   └── (optional app code)
└── README.md               # This file
```

## 🔍 Understanding the Code

### Key Terraform Concepts Used

1. **Data Sources** (`data "aws_ami"`) - Fetch latest Ubuntu AMI
2. **Variables** - Parameterize configuration
3. **Outputs** - Export important values
4. **Depends_on** - Control resource creation order
5. **Count** - Create multiple instances from one resource
6. **Templates** - Inject variables into user-data script
7. **IAM Roles** - Grant EC2 permissions

### Application Flow

1. **User** → requests ALB DNS
2. **ALB** → routes to healthy EC2 instance
3. **EC2** → runs Flask app on port 5000
4. **Flask** → connects to RDS PostgreSQL
5. **App** → returns HTML response with status

## 🐛 Troubleshooting

### Application not responding?

Check EC2 instance logs:

```bash
aws ec2 get-console-output --instance-ids <instance-id>
```

### RDS connection fails?

Verify security group allows EC2→RDS on port 5432:

```bash
aws ec2 describe-security-groups --group-ids <rds-sg-id>
```

### Terraform state issues?

Use refresh to sync state with AWS:

```bash
terraform refresh
```

## 💡 Learning Points

This project teaches:
- ✅ VPC setup with multiple subnets and AZs
- ✅ Security group design and principles
- ✅ RDS provisioning and configuration
- ✅ EC2 user-data for application bootstrapping
- ✅ ALB setup and target groups
- ✅ Terraform state management
- ✅ IAM roles and instance profiles
- ✅ Python Flask application deployment

## 📚 Further Enhancements

Consider adding:
- [ ] HTTPS/SSL certificates (ACM + ALB listener)
- [ ] Auto-scaling groups (ASG instead of fixed count)
- [ ] CloudWatch monitoring and alarms
- [ ] SNS notifications for alerts
- [ ] RDS read replicas for HA
- [ ] Secrets Manager for credential rotation
- [ ] Terraform remote state (S3 + DynamoDB)
- [ ] VPN for private RDS access

## 🤝 Tips for Learning Terraform

1. **Always run `terraform plan`** before apply
2. **Use `terraform output`** to understand what was created
3. **Read AWS documentation** for each resource
4. **Version control** your terraform files
5. **Use workspaces** for multiple environments
6. **Document** your infrastructure with comments
7. **Test locally** with smaller instances before scaling

## 📖 Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/best-practices/index.html)

---

**Happy Learning! 🎉**
