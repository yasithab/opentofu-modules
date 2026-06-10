# Must fail: manage_data_lake_settings with empty admin_arns would remove all
# Lake Formation administrators.
enabled                   = true
manage_data_lake_settings = true
admin_arns                = []
