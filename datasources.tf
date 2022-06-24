data "aws_ami" "mtc_ami" {
  owners      = [var.mtc_ami_owner]
  most_recent = true
  filter {
    name   = "name"
    values = [var.mtc_ami_name]
  }
}