#data "archive_file" "report_lambda" {
#  type = "zip"
#
#  source_dir  = "../report"
#  output_path = "report_function.zip"
#}

resource "aws_iam_role" "report_role" {
  name = "aws-ess-report-role"

   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "report_policy" {
  role       = aws_iam_role.report_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "report_dynamoroles" {
  role       = aws_iam_role.report_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "report_snsroles" {
  role       = aws_iam_role.report_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_lambda_function" "report" {
  function_name = "report-insert-file"
  filename         = "report_function.zip"
  source_code_hash = "${filebase64sha256("report_function.zip")}" #data.archive_file.report_lambda.output_base64sha256
  role = "${aws_iam_role.report_role.arn}"
  handler       = "index.handler"
  runtime = "nodejs20.x"
  environment {
    variables = {
      ARN_TOPIC= aws_sns_topic_subscription.email_subscription_ec2.topic_arn
    }
  }
}


## aws lambda invoke --region=eu-central-1 --function-name=process-lambda output.txt
## cat output.txt
#
#
resource "aws_lambda_event_source_mapping" "report_mapping" {
  event_source_arn  = aws_dynamodb_table.upload_table.stream_arn
  function_name     = aws_lambda_function.report.arn
  starting_position = "LATEST"

  tags = {
    Name = "dynamodb"
  }
}
