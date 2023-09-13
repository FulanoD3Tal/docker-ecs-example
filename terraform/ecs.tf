resource "aws_ecs_cluster" "ecs_cluster" {
  name = "vite-docker-cluster"
}

resource "aws_ecs_task_definition" "vite_task" {
  family = "vite-first-app"
  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.ecr_repository.repository_url}"
    essential = true
    portMappings = [
      {
        containerPort : 8080
        hostPort : 8080
      }
    ]
    memory = 512
    cpu    = 256
  }])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  
}
