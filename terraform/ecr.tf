resource "aws_ecr_repository" "ecr_repository" {
  name                 = "vite-docker-repository"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
