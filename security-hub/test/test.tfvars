name = "terratest-plan"

automation_rules = {
  suppress-sandbox-informational = {
    rule_order  = 1
    description = "Suppress informational findings from the sandbox account"
    criteria = {
      aws_account_id = [{ comparison = "EQUALS", value = "111111111111" }]
      severity_label = [{ comparison = "EQUALS", value = "INFORMATIONAL" }]
    }
    actions = {
      workflow_status = "SUPPRESSED"
      note_text       = "Auto-suppressed by automation rule"
    }
  }
}

insights = {
  critical-findings-by-resource = {
    group_by_attribute = "ResourceId"
    filters = {
      severity_label  = [{ comparison = "EQUALS", value = "CRITICAL" }]
      workflow_status = [{ comparison = "EQUALS", value = "NEW" }]
      record_state    = [{ comparison = "EQUALS", value = "ACTIVE" }]
    }
  }
}
