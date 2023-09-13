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
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


