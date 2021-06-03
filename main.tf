provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_s3_bucket" "s3" {
  bucket = "s3-artifact-repo-test1"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }
}

module "vls-vpc" {
  source = "./vpc"
}

module "build" {
  //s3_bucket = aws_s3_bucket.s3.name
  source = "./build"
}

module "deploy" {
  //s3_bucket = aws_s3_bucket.s3.name
  source = "./deploy"
}

module "pipelines" {
  #pipeline_env = local.env
  source = "./pipelines"
}

/* locals {
  env = terraform.workspace
}
*/