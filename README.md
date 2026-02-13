AWS Real-Time Data Pipeline (Kinesis → Lambda → DynamoDB)
Project Overview

This project provisions a serverless real-time data pipeline on AWS using Terraform.

The pipeline simulates incoming streaming data and automatically processes and stores it in DynamoDB.

This project demonstrates real-world cloud engineering skills:

Infrastructure as Code (Terraform)

Serverless architecture

Event-driven processing

AWS IAM and security best practices

Architecture

Flow of data:

Data is sent to Amazon Kinesis Data Stream

AWS Lambda automatically processes incoming records

Processed data is stored in DynamoDB

Everything is provisioned using Terraform

Producer → Kinesis Stream → Lambda → DynamoDB

Technologies Used
Service	Purpose
Terraform	Infrastructure as Code
AWS Kinesis	Real-time data streaming
AWS Lambda	Event-driven compute
DynamoDB	NoSQL data storage
IAM	Secure service permissions
Project Structure
telemax-realtime-pipeline/
│
├── main.tf        # Core infrastructure
├── variables.tf   # Input variables
├── outputs.tf     # Terraform outputs
├── lambda/        # Lambda function code
└── .gitignore

What This Infrastructure Creates

Terraform provisions:

Kinesis Data Stream

DynamoDB Table

Lambda Function

IAM Roles and Policies

Event Source Mapping (Kinesis → Lambda)

This mirrors real production architecture used for:

IoT data ingestion

Log processing

Clickstream analytics

Monitoring pipelines

How to Deploy
1. Prerequisites
Install:
AWS CLI
Terraform
Git

Configure AWS credentials: aws configure

2. Initialize Terraform
terraform init

What this does:
Downloads AWS provider
Prepares Terraform working directory

3️. Preview Infrastructure
terraform plan

What this does:
Shows resources that will be created

4. Deploy Infrastructure
terraform apply
Type yes when prompted.
Terraform will create the full pipeline.
5️. Destroy Resources (Cost Safety)
terraform destroy= This removes all AWS resources.

Learning Goals From This Project
This project helped me practice:
Writing production-style Terraform
Designing event-driven AWS architecture
Creating IAM roles securely
Connecting multiple AWS services together
Building a real portfolio cloud project

Future Improvements
Planned upgrades:
-Add CloudWatch logging and alarms
-Add CI/CD pipeline (GitHub Actions)
-Add API Gateway data producer
-Add architecture diagram

Author- Jordan Wray
Aspiring Cloud Engineer ☁️
