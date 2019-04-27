# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# iam
data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_iam_role_policy" "frontend_lambda_role_policy" {
  name   = "frontend-lambda-role-policy"
  role   = "${aws_iam_role.iam_for_lambda.id}"
  policy = "${data.aws_iam_policy_document.lambda_log_role_policy.json}"
}

data "aws_iam_policy_document" "lambda_log_role_policy" {

   statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

}



# lambda
provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "s3_trigger_lambda.py"
  output_path = "s3_trigger.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "s3_trigger"

  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

  role    = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "s3_trigger_lambda.lambda_handler"
  runtime = "python3.6"

  environment {
    variables = {
      environment = "dev-setup"
    }
  }
}


resource "aws_s3_bucket" "bucket" {
  bucket = "customer-invoice-ls"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".txt"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.bucket.arn}"
}
