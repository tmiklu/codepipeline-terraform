resource "aws_codepipeline" "vls-orbis-ingester" {
  name = "vls-orbis-ingester-${local.pipeline_env}"

  role_arn = aws_iam_role.vls-orbis-ingester-role.arn

  artifact_store {
    location = "s3-artifact-repo-test1"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      run_order        = "1"
      output_artifacts = ["source_output"]
      region           = "us-east-1"

      configuration = {
        BranchName           = "cicd"
        RepositoryName       = "vls-orbis-ingester"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      run_order        = "2"
      region           = "us-east-1"

      configuration = {
        ProjectName = "vls-orbis-ingester"
        EnvironmentVariables = jsonencode([
          {
            name  = "ci"
            value = "null"
            type  = "PLAINTEXT"
          },
          {
            name  = "id"
            value = "null"
            type  = "PLAINTEXT"
          },
          {
            name  = "url"
            value = "null"
            type  = "PLAINTEXT"
          },
        ])
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name      = "Deploy"
      category  = "Invoke"
      owner     = "AWS"
      provider  = "Lambda"
      version   = "1"
      run_order = "3"
      region    = "us-east-1"

      configuration = {
        FunctionName = "vls-compute-platform"
      }
    }
  }
}

resource "aws_iam_role" "vls-orbis-ingester-role" {
  name = "vls-orbis-ingester-${local.pipeline_env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "vls-orbis-ingester-policy" {
  name = "vls-orbis-ingester-${local.pipeline_env}"
  role = aws_iam_role.vls-orbis-ingester-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::s3-artifact-repo-test1",
        "arn:aws:s3:::s3-artifact-repo-test1/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:*"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "codepipeline:*",
        "codepipeline:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
     },
     {
      "Action": [
        "lambda:InvokeFunction"
        ],
        "Effect": "Allow",
        "Resource": "*"
     }
  ]
}
EOF
}