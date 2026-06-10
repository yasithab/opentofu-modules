name                  = "terratest-plan"
file_system_type      = "ONTAP"
subnet_ids            = ["subnet-12345678"]
storage_capacity      = 1024
throughput_capacity   = 128
ontap_deployment_type = "SINGLE_AZ_1"

ontap_svms = {
  apps = {
    name = "svm01"
  }
  analytics = {}
}

ontap_volumes = {
  data = {
    name              = "data_vol"
    svm_key           = "apps"
    size_in_megabytes = 102400
  }
  logs = {
    name              = "logs_vol"
    svm_key           = "analytics"
    size_in_megabytes = 51200
  }
}
