name                   = "terratest-plan"
result_output_location = "s3://terratest-plan-athena-results/output/"

prepared_statements = {
  events_by_day = {
    query_statement = "SELECT * FROM analytics.events WHERE event_date = ?"
    description     = "Fetch events for a given day"
  }
}

capacity_reservation = {
  target_dpus = 24
}
