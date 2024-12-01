#data "archive_file" "image_analysis" {
#  type = "zip"
#
#  source_dir  = "../image_analysis"
#  output_path = "image_analysis_function.zip"
#}

resource "aws_iam_role" "image_analysis_function_role" {
  name = "image_analysis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "image_analysis_policy" {
  role       = aws_iam_role.image_analysis_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "image_analysis_dynamoroles" {
  role       = aws_iam_role.image_analysis_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "image_analysis_snsroles" {
  role       = aws_iam_role.image_analysis_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_lambda_function" "image_analysis_lambda" {
  filename         = "image_analysis_function.zip"
  function_name    = "image_analysis_lambda"
  handler       = "index.handler"
  runtime = "nodejs20.x"
  role             = aws_iam_role.image_analysis_function_role.arn
  memory_size      = "128"
  timeout          = "3"
  source_code_hash =  "${filebase64sha256("image_analysis_function.zip")}" #data.archive_file.image_analysis.output_base64sha256
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.upload_table.name,
      ARN_TOPIC= aws_sns_topic_subscription.email_subscription_ec2.topic_arn
    }
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_analysis_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.aws-ess-exam.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.aws-ess-exam.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_analysis_lambda.arn
    events              = ["s3:ObjectCreated:*"]
#    filter_prefix       = "images/"
#    filter_suffix       = ".png"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

#
## aws lambda invoke --region=eu-central-1 --function-name=process-lambda output.txt
## cat output.txt
