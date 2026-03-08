locals {
  create_role           = var.enabled && var.create_role
  create_pipes          = var.enabled && var.create_pipes
  create_role_for_pipes = local.create_pipes && (var.create_role || var.create_pipe_role_only)

  # Defaulting to "*" (an invalid character for an IAM Role name) will cause an error when
  # attempting to plan if the role_name and bus_name are not set. This is a workaround
  # that will allow one to import resources without receiving an error from coalesce.
  # @see https://github.com/terraform-aws-modules/terraform-aws-lambda/issues/83
  role_name = local.create_role ? coalesce(var.role_name, var.bus_name, "*") : null
}

###########################
# IAM role for EventBridge
###########################

data "aws_iam_policy_document" "assume_role" {
  count = local.create_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = distinct(concat(["events.amazonaws.com"], var.trusted_entities, length(keys(var.schedules)) > 0 && var.create_schedules ? ["scheduler.amazonaws.com"] : []))
    }
  }
}

resource "aws_iam_role" "eventbridge" {
  name                  = local.role_name
  description           = var.role_description
  path                  = var.role_path
  force_detach_policies = var.role_force_detach_policies
  permissions_boundary  = var.role_permissions_boundary
  assume_role_policy    = data.aws_iam_policy_document.assume_role[0].json

  tags = merge({ Name = local.role_name }, local.tags, var.role_tags)

  lifecycle {
    enabled = local.create_role
  }
}

#####################
# Tracing with X-Ray
#####################

# Copying AWS managed policy to be able to attach the same policy with
# multiple roles without overwrites by another resources
data "aws_iam_policy" "tracing" {
  count = local.create_role && var.attach_tracing_policy ? 1 : 0

  arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_policy" "tracing" {
  name   = "${local.role_name}-tracing"
  policy = data.aws_iam_policy.tracing[0].policy
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-tracing" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_tracing_policy
  }
}

resource "aws_iam_role_policy_attachment" "tracing" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.tracing.arn

  lifecycle {
    enabled = local.create_role && var.attach_tracing_policy
  }
}

##################
# Kinesis Config
##################

data "aws_iam_policy_document" "kinesis" {
  count = local.create_role && var.attach_kinesis_policy ? 1 : 0

  statement {
    sid       = "KinesisAccess"
    effect    = "Allow"
    actions   = ["kinesis:PutRecord", "kinesis:PutRecords"]
    resources = var.kinesis_target_arns
  }
}

resource "aws_iam_policy" "kinesis" {
  name   = "${local.role_name}-kinesis"
  policy = data.aws_iam_policy_document.kinesis[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-kinesis" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_kinesis_policy
  }
}

resource "aws_iam_role_policy_attachment" "kinesis" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.kinesis.arn

  lifecycle {
    enabled = local.create_role && var.attach_kinesis_policy
  }
}

##########################
# Kinesis Firehose Config
##########################

data "aws_iam_policy_document" "kinesis_firehose" {
  count = local.create_role && var.attach_kinesis_firehose_policy ? 1 : 0

  statement {
    sid       = "KinesisFirehoseAccess"
    effect    = "Allow"
    actions   = ["firehose:PutRecord"]
    resources = var.kinesis_firehose_target_arns
  }
}

resource "aws_iam_policy" "kinesis_firehose" {
  name   = "${local.role_name}-kinesis-firehose"
  policy = data.aws_iam_policy_document.kinesis_firehose[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-kinesis-firehose" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_kinesis_firehose_policy
  }
}

resource "aws_iam_role_policy_attachment" "kinesis_firehose" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.kinesis_firehose.arn

  lifecycle {
    enabled = local.create_role && var.attach_kinesis_firehose_policy
  }
}

#############
# SQS Config
#############

data "aws_iam_policy_document" "sqs" {
  count = local.create_role && var.attach_sqs_policy ? 1 : 0

  statement {
    sid    = "SQSAccess"
    effect = "Allow"
    actions = [
      "sqs:SendMessage*",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = var.sqs_target_arns
  }
}

resource "aws_iam_policy" "sqs" {
  name   = "${local.role_name}-sqs"
  policy = data.aws_iam_policy_document.sqs[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-sqs" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_sqs_policy
  }
}

resource "aws_iam_role_policy_attachment" "sqs" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.sqs.arn

  lifecycle {
    enabled = local.create_role && var.attach_sqs_policy
  }
}

#############
# SNS Config
#############

data "aws_iam_policy_document" "sns" {
  count = local.create_role && var.attach_sns_policy ? 1 : 0

  statement {
    sid    = "SNSAccess"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = var.sns_target_arns
  }

  dynamic "statement" {
    for_each = length(var.sns_kms_arns) > 0 ? [1] : []

    content {
      sid    = "SNSKMSAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = var.sns_kms_arns
    }
  }

}

resource "aws_iam_policy" "sns" {
  name   = "${local.role_name}-sns"
  policy = data.aws_iam_policy_document.sns[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-sns" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_sns_policy
  }
}

resource "aws_iam_role_policy_attachment" "sns" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.sns.arn

  lifecycle {
    enabled = local.create_role && var.attach_sns_policy
  }
}

#############
# ECS Config
#############

data "aws_iam_policy_document" "ecs" {
  count = local.create_role && var.attach_ecs_policy ? 1 : 0

  statement {
    sid    = "ECSAccess"
    effect = "Allow"
    actions = [
      "ecs:RunTask",
      "ecs:TagResource"
    ]
    resources = [for arn in var.ecs_target_arns : replace(arn, "/:\\d+$/", ":*")]
  }

  statement {
    sid       = "PassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = coalescelist(var.ecs_pass_role_resources, ["*"])
  }
}

resource "aws_iam_policy" "ecs" {
  name   = "${local.role_name}-ecs"
  policy = data.aws_iam_policy_document.ecs[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-ecs" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_ecs_policy
  }
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.ecs.arn

  lifecycle {
    enabled = local.create_role && var.attach_ecs_policy
  }
}

#########################
# Lambda Function Config
#########################

data "aws_iam_policy_document" "lambda" {
  count = local.create_role && var.attach_lambda_policy ? 1 : 0

  statement {
    sid       = "LambdaAccess"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = var.lambda_target_arns
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${local.role_name}-lambda"
  policy = data.aws_iam_policy_document.lambda[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-lambda" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_lambda_policy
  }
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.lambda.arn

  lifecycle {
    enabled = local.create_role && var.attach_lambda_policy
  }
}

######################
# StepFunction Config
######################

data "aws_iam_policy_document" "sfn" {
  count = local.create_role && var.attach_sfn_policy ? 1 : 0

  statement {
    sid       = "StepFunctionAccess"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = var.sfn_target_arns
  }
}

resource "aws_iam_policy" "sfn" {
  name   = "${local.role_name}-sfn"
  policy = data.aws_iam_policy_document.sfn[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-sfn" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_sfn_policy
  }
}

resource "aws_iam_role_policy_attachment" "sfn" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.sfn.arn

  lifecycle {
    enabled = local.create_role && var.attach_sfn_policy
  }
}

#########################
# API Destination Config
#########################

data "aws_iam_policy_document" "api_destination" {
  count = local.create_role && var.attach_api_destination_policy ? 1 : 0

  statement {
    sid       = "APIDestinationAccess"
    effect    = "Allow"
    actions   = ["events:InvokeApiDestination"]
    resources = [for k, v in aws_cloudwatch_event_api_destination.this : v.arn]
  }
}

resource "aws_iam_policy" "api_destination" {
  name   = "${local.role_name}-api-destination"
  policy = data.aws_iam_policy_document.api_destination[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-api-destination" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_api_destination_policy
  }
}

resource "aws_iam_role_policy_attachment" "api_destination" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.api_destination.arn

  lifecycle {
    enabled = local.create_role && var.attach_api_destination_policy
  }
}

####################
# Cloudwatch Config
####################

data "aws_iam_policy_document" "cloudwatch" {
  count = local.create_role && var.attach_cloudwatch_policy ? 1 : 0

  statement {
    sid    = "CloudwatchAccess"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = var.cloudwatch_target_arns
  }
}

resource "aws_iam_policy" "cloudwatch" {
  name   = "${local.role_name}-cloudwatch"
  policy = data.aws_iam_policy_document.cloudwatch[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-cloudwatch" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_cloudwatch_policy
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.cloudwatch.arn

  lifecycle {
    enabled = local.create_role && var.attach_cloudwatch_policy
  }
}

###########################
# Additional policy (JSON)
###########################

resource "aws_iam_policy" "additional_json" {
  name   = local.role_name
  path   = var.role_path
  policy = var.policy_json

  tags = merge({ Name = local.role_name }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_policy_json
  }
}

resource "aws_iam_role_policy_attachment" "additional_json" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.additional_json.arn

  lifecycle {
    enabled = local.create_role && var.attach_policy_json
  }
}

#####################################
# Additional policies (list of JSON)
#####################################

resource "aws_iam_policy" "additional_jsons" {
  count = local.create_role && var.attach_policy_jsons ? var.number_of_policy_jsons : 0

  name   = "${local.role_name}-${count.index}"
  policy = var.policy_jsons[count.index]
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-${count.index}" }, local.tags)
}

resource "aws_iam_role_policy_attachment" "additional_jsons" {
  count = local.create_role && var.attach_policy_jsons ? var.number_of_policy_jsons : 0

  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.additional_jsons[count.index].arn
}

###########################
# ARN of additional policy
###########################

resource "aws_iam_role_policy_attachment" "additional_one" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = var.policy

  lifecycle {
    enabled = local.create_role && var.attach_policy
  }
}

######################################
# List of ARNs of additional policies
######################################

resource "aws_iam_role_policy_attachment" "additional_many" {
  count = local.create_role && var.attach_policies ? var.number_of_policies : 0

  role       = aws_iam_role.eventbridge.name
  policy_arn = var.policies[count.index]
}

###############################
# Additional policy statements
###############################

data "aws_iam_policy_document" "additional_inline" {
  count = local.create_role && var.attach_policy_statements ? 1 : 0

  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid           = lookup(statement.value, "sid", replace(statement.key, "/[^0-9A-Za-z]*/", ""))
      effect        = lookup(statement.value, "effect", null)
      actions       = lookup(statement.value, "actions", null)
      not_actions   = lookup(statement.value, "not_actions", null)
      resources     = lookup(statement.value, "resources", null)
      not_resources = lookup(statement.value, "not_resources", null)

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", [])
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = lookup(statement.value, "not_principals", [])
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = lookup(statement.value, "condition", [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "additional_inline" {
  name   = "${local.role_name}-inline"
  policy = data.aws_iam_policy_document.additional_inline[0].json
  path   = var.policy_path

  tags = merge({ Name = "${local.role_name}-inline" }, local.tags)

  lifecycle {
    enabled = local.create_role && var.attach_policy_statements
  }
}

resource "aws_iam_role_policy_attachment" "additional_inline" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.additional_inline.arn

  lifecycle {
    enabled = local.create_role && var.attach_policy_statements
  }
}
