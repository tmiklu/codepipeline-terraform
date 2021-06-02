resource "aws_iam_role" "vls-orbis-ingester-build-role" {
  name = "vls-orbis-ingester"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vls-orbis-ingester-build-policy" {
  role = aws_iam_role.vls-orbis-ingester-build-role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:GetLifecyclePolicy",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:ListTagsForResource",
                "ecr:DescribeImageScanFindings",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Resource": [
                "*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-east-1-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:codecommit:us-east-1:028960685088:vls-orbis-ingester"
            ],
            "Action": [
                "codecommit:GitPull"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::s3-artifact-repo-test1",
                "arn:aws:s3:::s3-artifact-repo-test1/*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:us-east-1:028960685088:report-group/vls-orbis-ingester-*"
            ]
        }
    ]
}
POLICY
}

/*
output "bucket_name" {
  value = "s3-artifact-repo-test1"
}
*/

resource "aws_codebuild_project" "vls-orbis-ingester" {
  name          = "vls-orbis-ingester"
  description   = "vls-orbis-ingester build"
  build_timeout = "5"
  service_role  = aws_iam_role.vls-orbis-ingester-build-role.arn

  artifacts {
    type      = "S3"
    location  = "s3-artifact-repo-test1"
    packaging = "ZIP"
  }

  cache {
    type     = "S3"
    location = "s3-artifact-repo-test1"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "id"
      value = "null"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "ci"
      value = "null"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "url"
      value = "null"
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/vls-orbis-ingester"
    git_clone_depth = 1


    git_submodules_config {
      fetch_submodules = false
    }
  }

  source_version = "refs/heads/cicd"

  tags = {
    Environment = "random"
  }
}
