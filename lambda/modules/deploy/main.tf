locals {
  # AWS CodeDeploy can't deploy when CurrentVersion is "$LATEST"
  qualifier       = try(data.aws_lambda_function.this[0].qualifier, "")
  current_version = local.qualifier == "$LATEST" ? 1 : local.qualifier

  app_name              = try(aws_codedeploy_app.this.name, var.app_name)
  deployment_group_name = try(aws_codedeploy_deployment_group.this.deployment_group_name, var.deployment_group_name)

  appspec = merge({
    version = "0.0"
    Resources = [
      {
        MyFunction = {
          Type = "AWS::Lambda::Function"
          Properties = {
            Name           = var.function_name
            Alias          = var.alias_name
            CurrentVersion = var.current_version != null ? var.current_version : local.current_version
            TargetVersion  = var.target_version
          }
        }
      }
    ]
    }, var.before_allow_traffic_hook_arn != null || var.after_allow_traffic_hook_arn != null ? {
    Hooks = [for k, v in zipmap(["BeforeAllowTraffic", "AfterAllowTraffic"], [
      var.before_allow_traffic_hook_arn != null ? var.before_allow_traffic_hook_arn : null,
      var.after_allow_traffic_hook_arn != null ? var.after_allow_traffic_hook_arn : null
    ]) : tomap({ (k) = v }) if v != null]
  } : {})

  appspec_content = replace(jsonencode(local.appspec), "\"", "\\\"")
  appspec_sha256  = sha256(jsonencode(local.appspec))

  script = <<EOF
#!/bin/bash

if [[ '${var.target_version}' == '${var.current_version != null ? var.current_version : local.current_version}' ]]; then
  echo "Skipping deployment because target version (${var.target_version}) is already the current version"
  exit 0
fi

ID=$(${var.aws_cli_command} deploy create-deployment \
    --application-name ${local.app_name} \
    --deployment-group-name ${local.deployment_group_name} \
    --deployment-config-name ${var.deployment_config_name} \
    --description "${var.description}" \
    --revision '{"revisionType": "AppSpecContent", "appSpecContent": {"content": "${local.appspec_content}", "sha256": "${local.appspec_sha256}"}}' \
    --output text \
    --query '[deploymentId]')

%{if var.wait_deployment_completion}
STATUS=$(${var.aws_cli_command} deploy get-deployment \
    --deployment-id $ID \
    --output text \
    --query '[deploymentInfo.status]')

while [[ $STATUS == "Created" || $STATUS == "InProgress" || $STATUS == "Pending" || $STATUS == "Queued" || $STATUS == "Ready" ]]; do
    echo "Status: $STATUS..."
    STATUS=$(${var.aws_cli_command} deploy get-deployment \
        --deployment-id $ID \
        --output text \
        --query '[deploymentInfo.status]')

    SLEEP_TIME=$((( $RANDOM % 5 ) + ${var.get_deployment_sleep_timer}))

    echo "Sleeping for: $SLEEP_TIME Seconds"
    sleep $SLEEP_TIME
done

${var.aws_cli_command} deploy get-deployment --deployment-id $ID

if [[ $STATUS == "Succeeded" ]]; then
    echo "Deployment succeeded."
else
    echo "Deployment failed!"
    exit 1
fi

%{else}

${var.aws_cli_command} deploy get-deployment --deployment-id $ID
echo "Deployment started, but wait deployment completion is disabled!"

%{endif}
EOF


  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

data "aws_lambda_alias" "this" {
  count = var.enabled && var.create_deployment ? 1 : 0

  function_name = var.function_name
  name          = var.alias_name
}

data "aws_lambda_function" "this" {
  count = var.enabled && var.create_deployment ? 1 : 0

  function_name = var.function_name
  qualifier     = data.aws_lambda_alias.this[0].function_version
}

resource "local_file" "deploy_script" {
  filename             = "deploy_script_${local.appspec_sha256}.txt"
  directory_permission = "0755"
  file_permission      = "0644"
  content              = local.script

  lifecycle {
    enabled = var.enabled && var.create_deployment && var.save_deploy_script
  }
}

resource "null_resource" "deploy" {
  triggers = {
    appspec_sha256 = local.appspec_sha256
    force_deploy   = var.force_deploy ? uuid() : false
  }

  provisioner "local-exec" {
    command     = local.script
    interpreter = var.interpreter
  }

  depends_on = [
    aws_iam_role_policy_attachment.hooks
  ]

  lifecycle {
    enabled = var.enabled && var.create_deployment && var.run_deployment
  }
}

resource "aws_codedeploy_app" "this" {
  name             = var.app_name
  compute_platform = "Lambda"
  tags             = local.tags

  lifecycle {
    enabled = var.enabled && var.create_app && !var.use_existing_app
  }
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = local.app_name
  deployment_group_name  = var.deployment_group_name
  service_role_arn       = try(aws_iam_role.codedeploy.arn, data.aws_iam_role.codedeploy[0].arn, "")
  deployment_config_name = var.deployment_config_name

  outdated_instances_strategy = var.outdated_instances_strategy
  termination_hook_enabled    = var.termination_hook_enabled

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = var.auto_rollback_enabled
    events  = var.auto_rollback_events
  }

  dynamic "alarm_configuration" {
    for_each = var.alarm_enabled ? [true] : []

    content {
      enabled                   = var.alarm_enabled
      alarms                    = var.alarms
      ignore_poll_alarm_failure = var.alarm_ignore_poll_alarm_failure
    }
  }

  dynamic "ec2_tag_filter" {
    for_each = var.ec2_tag_filter

    content {
      key   = try(ec2_tag_filter.value.key, null)
      type  = try(ec2_tag_filter.value.type, null)
      value = try(ec2_tag_filter.value.value, null)
    }
  }

  dynamic "ec2_tag_set" {
    for_each = var.ec2_tag_set

    content {
      dynamic "ec2_tag_filter" {
        for_each = try(ec2_tag_set.value.ec2_tag_filter, [])

        content {
          key   = try(ec2_tag_filter.value.key, null)
          type  = try(ec2_tag_filter.value.type, null)
          value = try(ec2_tag_filter.value.value, null)
        }
      }
    }
  }

  dynamic "trigger_configuration" {
    for_each = var.triggers

    content {
      trigger_events     = trigger_configuration.value.events
      trigger_name       = trigger_configuration.value.name
      trigger_target_arn = trigger_configuration.value.target_arn
    }
  }

  tags = local.tags

  lifecycle {
    enabled = var.enabled && var.create_deployment_group && !var.use_existing_deployment_group
  }
}

data "aws_iam_role" "codedeploy" {
  count = var.enabled && !var.create_codedeploy_role ? 1 : 0

  name = var.codedeploy_role_name
}

resource "aws_iam_role" "codedeploy" {
  name               = try(coalesce(var.codedeploy_role_name, "${local.app_name}-codedeploy"), "codedeploy")
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  tags               = local.tags

  lifecycle {
    enabled = var.enabled && var.create_codedeploy_role
  }
}


data "aws_iam_policy_document" "assume_role" {
  count = var.enabled && var.create_codedeploy_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.codedeploy_principals
    }
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = try(aws_iam_role.codedeploy.id, "")
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"

  lifecycle {
    enabled = var.enabled && var.create_codedeploy_role
  }
}

data "aws_iam_policy_document" "hooks" {
  count = var.enabled && var.create_codedeploy_role && var.attach_hooks_policy && (var.before_allow_traffic_hook_arn != null || var.after_allow_traffic_hook_arn != null) ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = compact([var.before_allow_traffic_hook_arn, var.after_allow_traffic_hook_arn])
  }

}

resource "aws_iam_policy" "hooks" {
  policy = data.aws_iam_policy_document.hooks[0].json
  tags   = local.tags

  lifecycle {
    enabled = var.enabled && var.create_codedeploy_role && var.attach_hooks_policy && (var.before_allow_traffic_hook_arn != null || var.after_allow_traffic_hook_arn != null)
  }
}

resource "aws_iam_role_policy_attachment" "hooks" {
  role       = try(aws_iam_role.codedeploy.id, "")
  policy_arn = aws_iam_policy.hooks.arn

  lifecycle {
    enabled = var.enabled && var.create_codedeploy_role && var.attach_hooks_policy && (var.before_allow_traffic_hook_arn != null || var.after_allow_traffic_hook_arn != null)
  }
}

data "aws_iam_policy_document" "triggers" {
  count = var.enabled && var.create_codedeploy_role && var.attach_triggers_policy ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "triggers" {
  policy = data.aws_iam_policy_document.triggers[0].json
  tags   = local.tags

  lifecycle {
    enabled = var.enabled && var.create_codedeploy_role && var.attach_triggers_policy
  }
}

resource "aws_iam_role_policy_attachment" "triggers" {
  role       = try(aws_iam_role.codedeploy.id, "")
  policy_arn = aws_iam_policy.triggers.arn

  lifecycle {
    enabled = var.enabled && var.create_codedeploy_role && var.attach_triggers_policy
  }
}

# https://docs.aws.amazon.com/codedeploy/latest/userguide/deployment-configurations.html
# https://www.terraform.io/docs/providers/aws/r/codedeploy_deployment_config.html
#resource "aws_codedeploy_deployment_config" "this" {
#  deployment_config_name = "test-deployment-config"
#  compute_platform       = "Lambda"
#
#  traffic_routing_config {
#    type = "TimeBasedLinear"
#
#    time_based_linear {
#      interval   = 10
#      percentage = 10
#    }
#  }
#}
