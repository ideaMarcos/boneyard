terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current-region" {}

locals {
  docker_image = "ideamarcos-boneyard"
  registry_id  = "000000000000"
}

resource "aws_ecr_repository" "ecr_repo" {
  name                 = "localstack-ecr-repo"
  image_tag_mutability = "MUTABLE" # or "IMMUTABLE" based on your requirement
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "builder" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = path.module
    command     = "docker build -t ${local.docker_image} ../"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = path.module
    command     = "docker tag ${local.docker_image} ${local.registry_id}.dkr.ecr.${data.aws_region.current-region.name}.localhost.localstack.cloud:4566/${aws_ecr_repository.ecr_repo.name}"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = path.module
    command     = "docker push ${local.registry_id}.dkr.ecr.${data.aws_region.current-region.name}.localhost.localstack.cloud:4566/${aws_ecr_repository.ecr_repo.name}"
  }
}

output "command_output" {
  value       = null_resource.builder.id
  description = "Output from builder"
}
