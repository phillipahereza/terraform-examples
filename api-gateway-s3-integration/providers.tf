terraform{
  required_providers {
    aws = {
      version = "~> 2.10"
    }
  }
}

provider "aws" {
  region = var.region
}