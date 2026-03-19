# Lab 01: Build a VPC from Scratch

## Objective
Build a complete VPC without looking at any reference material.

## Requirements
Create a VPC with:
- CIDR: 10.0.0.0/16
- 2 public subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 private subnets (10.0.3.0/24, 10.0.4.0/24)
- Internet Gateway
- Route tables

## Verification
```bash
aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>"
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=<VPC_ID>"
```

## Quiz
1. What's the difference between a public and private subnet?
2. Why do we need an Internet Gateway?
3. What's the maximum number of VPCs per region (default)?
4. Can two subnets in the same VPC have overlapping CIDRs?

## Answers
1. Public subnets have a route to an Internet Gateway; private subnets don't
2. IGW allows resources in public subnets to communicate with the internet
3. 5 (can be increased via support ticket)
4. No - CIDRs must not overlap within a VPC
