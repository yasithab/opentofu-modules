mock_resource "aws_fsx_ontap_file_system" {
  defaults = {
    id = "fs-0123456789abcdef0"
  }
}

mock_resource "aws_fsx_ontap_storage_virtual_machine" {
  defaults = {
    id = "svm-0123456789abcdef0"
  }
}
