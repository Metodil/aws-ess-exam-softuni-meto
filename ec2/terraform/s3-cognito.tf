# new bucket
resource "aws_s3_bucket" "aws-ess-exam" {
  bucket = "aws-ess-exam-meto"
}

resource "aws_s3_bucket_lifecycle_configuration" "aws-ess-exam-lifecycle" {
  bucket = aws_s3_bucket.aws-ess-exam.id
  rule {
    id     = "ManageLifecycleAndDelete"
    status = "Enabled"
    expiration {
      days = 2
    }
  }
}


resource "aws_s3_bucket_public_access_block" "aws-ess-exam" {
  bucket = aws_s3_bucket.aws-ess-exam.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.aws-ess-exam.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST","GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}


resource "aws_cognito_identity_pool" "upload-s3" {
      identity_pool_name               = "ip-upload-s3"
      allow_unauthenticated_identities = true

 }


resource "aws_cognito_identity_pool_roles_attachment" "upload-s3-attach" {
      identity_pool_id = aws_cognito_identity_pool.upload-s3.id

      roles = {
           unauthenticated = aws_iam_role.unauth_iam_role.arn
      }
}

resource "aws_iam_role" "unauth_iam_role" {
      name = "unauth_iam_role"
      assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
           {
                "Action": "sts:AssumeRole",
                "Principal": {
                     "Federated": "cognito-identity.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
           }
      ]
 }

EOF
}

resource "aws_iam_role_policy" "unauth_credentials_allow_role_policy" {
      name = "unauth_credentials_allow__unauth_role_policy"
      role = aws_iam_role.unauth_iam_role.id
      policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "cognito-identity:GetCredentialsForIdentity"
                ],
                "Resource": [
                    "*"
                ]
            }
        ]
     })
}

resource "aws_iam_role_policy" "web_iam_unauth_role_policy" {
      name = "web_iam_unauth_role_policy"
      role = aws_iam_role.unauth_iam_role.id
      policy = jsonencode({
       	"Version": "2012-10-17",
       	"Statement": [
       		{
       			"Effect": "Allow",
       			"Action": [
       				"s3:PutObject"
       			],
       			"Resource": "${aws_s3_bucket.aws-ess-exam.arn}/*"
       		}
       	]
      })
}

resource "terraform_data" "set-cognito-id-web" {
  provisioner "local-exec" {
    command = "CONGNITO_IP_ID=${aws_cognito_identity_pool.upload-s3.id}"
  }
}
