terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "eu-central-1"
}

# create topic for emails
resource "aws_sns_topic" "sns_topic_ec2" {
  name = "aws-ess-ec2-sns-topic"
}
resource "aws_sns_topic_subscription" "email_subscription_ec2" {
  topic_arn = aws_sns_topic.sns_topic_ec2.arn
  protocol  = "email"
  endpoint  = "hristo.zhelev@yahoo.com"
#  endpoint  = "metodil@hotmail.com"
}

# database for storing meta info
resource "aws_dynamodb_table" "upload_table" {
 name = "UploadTable"
 billing_mode     = "PAY_PER_REQUEST"
 hash_key = "id"
 range_key    = "fileExtension"

 attribute {
   name = "id"
   type = "S"
 }

 attribute {
   name = "fileExtension"
   type = "S"
 }

 tags = {
   Name = "UsersTable"
 }
ttl {
  enabled = true
  attribute_name = "ttl"
 }

 stream_enabled = true
 stream_view_type = "NEW_AND_OLD_IMAGES"
 }
