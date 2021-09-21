provider "aws" {
  region = "us-east-2"
}

/*terraform {
  backend "s3" {
    bucket = "bucket-for-petclinic"
    key    = "terraform/terraform.tfstate"
    region = "us-east-2"
  }
}*/