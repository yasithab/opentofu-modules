name = "terratest-plan"

create_cloudwatch_log_group = true

create_alert_manager_definition = true

alert_manager_definition = <<-EOT
  alertmanager_config: |
    route:
      receiver: 'default'
    receivers:
      - name: 'default'
EOT

rule_group_namespaces = {
  default = {
    name = "terratest-rules"
    data = <<-EOT
      groups:
        - name: test
          rules:
            - record: metric:recording_rule
              expr: avg(rate(container_cpu_usage_seconds_total[5m]))
    EOT
  }
}
