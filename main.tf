provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  state_bucket_name = "${var.project_name}-${local.account_id}-${var.region}-remote-state"
  state_table_name  = local.state_bucket_name
}

// Cria a tabela que fará o lock nas alterações quando estas forem aplicadas
resource "aws_dynamodb_table" "locking" {
  name           = local.state_table_name
  read_capacity  = "20"
  write_capacity = "20"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

// Cria o bucket que guardará o estado do terraform da aplicação
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name
  region = data.aws_region.current.name

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    name        = "terraform-remote-state-bucket"
    environment = "global"
    project     = var.project_name
  }
}
