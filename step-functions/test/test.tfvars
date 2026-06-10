name       = "terratest-plan"
definition = "{\"StartAt\":\"Pass\",\"States\":{\"Pass\":{\"Type\":\"Pass\",\"End\":true}}}"

publish = true

aliases = {
  live = {
    description = "Production traffic alias"
    routing_configuration = [
      {
        weight = 100
      },
    ]
  }
}
