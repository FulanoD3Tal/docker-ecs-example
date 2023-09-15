# ECS example
#### This example will use a [Vite](https://vitejs.dev/) app to deploy a production ready website using this service and [Docker](https://www.docker.com/)

```
Amazon Elastic Container Service (Amazon ECS) is a fully managed container orchestration service that simplifies your deployment, management, and scaling of containerized applications. Simply describe your application and the resources required, and Amazon ECS will launch, monitor, and scale your application across flexible compute options with automatic integrations to other supporting AWS services that your application needs. Perform system operations such as creating custom scaling and capacity rules, and observe and query data from application logs and telemetry.
```

## Creating the web app

Using vite we will use the command from the documentation for create a new react app

```bash
npm create vite@latest my-vue-app --template react
```

Install the dependencies and run the application in dev mode to verify everything is working

```bash
# move to the dir
cd my-vue-app
# install the dependencies
npm install
# run the dev server
npm run dev
```

You should can open a url to see your web app

```bash
  VITE v4.4.5  ready in 378 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h to show help

```

## Build for production

We need to deploy to production, for that we need to prepare the web app for a real word environment, vite (and many framework) has command for that

```BASH
# compile the web app
npm run build
```

This will create a new directory `/dist` with simple **HTML, CSS, JS**

## Dockerize the application

Those file need to be served, for that we can use some static file server like [nginx](https://www.nginx.com/)

But we are going to use ECS, so for that we will use **Docker** to wrap all

> This tutorial do not include the installation and configuration of Docker

First we will create some files

```markdown
# In the root directory of your project /

# create a Dockerfile

# and a .dockerignore

.
├── Dockerfile (+)
├── .dockerignore (+)
├── index.html
├── package.json
├── package-lock.json
├── public
│ └── vite.svg
├── README.md
├── src
│ ├── App.css
│ ├── App.jsx
│ ├── assets
│ │ └── react.svg
│ ├── index.css
│ └── main.jsx
└── vite.config.js
```

The `.dockerignore` file tell docker wich file/dir avoid when creating the image

```bash
node_modules
.env
```

The important file is the `Dockerfile` where we are going to create a server with the static files from vite build process

```dockerfile
# Dockerfile
#Generate the server

# Create a image from nginx oficial image
FROM nginx

# Using root as working directory
WORKDIR /

# Copy the dist directory content to nginx folder
# to let it server this static file
COPY /dist /usr/share/nginx/html
```

> In this example the process of build the static assets and create the image are separated, i you want use a multi build stage docker, go ahead

### Testing the docker image

Before to continue, let check if the image is really going to work

Let create a container and run it

Create a new image with the `Dockerfile`

```bash
docker build -t vite-app .
```

Let start a new container with the new image

```bash
docker run --name website -d -p 80:80 vite-app
```

if you go to [http://localhost](http://localhost) you should see the vite app we created

## Create the infraestructure

We would use AWS as cloud provider, using the next diagram

![aws_diagram](/images/AWS_diagram.png)

The core of this infrastructure is the `ECS` where aws will managed our docker image in order to deploy an application

> There are more item in the infrastructure, just try to keep as simple as posible

to create the infrastructure i used [Terraform](https://www.terraform.io/)

there is a `terraform` folder with all the files to build the necessary infrastructure to deploy everything

```markdown
.
├── Dockerfile
├── images
│ └── AWS_diagram.png
├── index.html
├── package.json
├── package-lock.json
├── public
│ └── vite.svg
├── README.md
├── src
│ ├── App.css
│ ├── App.jsx
│ ├── assets
│ │ └── react.svg
│ ├── index.css
│ └── main.jsx
├── terraform (+)
│ ├── ecr.tf (+)
│ ├── ecs.tf (+)
│ ├── main.tf (+)
│ ├── variables.tf (+)
│ └── vpc.tf (+)
└── vite.config.js
```

The mains elements in this infrastructure are:

### The docker container registry (ECR)

![ecr](/images/ECR.png)

A place to upload our generated docker image

> This is no necessary, can use other container registry if you want it but since we are using Terraform is easy to keep all in the same cloud provider

This terraform code will create it

```terraform
resource "aws_ecr_repository" "ecr_repository" {
  name                 = "vite-docker-repository"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
```

### The task definition

![Alt text](images/Amazon-Elastic-Container-Service_Task.png)

The task definition is a blueprint of the runner with the docker image we will create

```
resource "aws_ecs_task_definition" "vite_task" {
  family = "vite-first-app"
  container_definitions = jsonencode([{
    name      = "vite-first-app"
    image     = "${aws_ecr_repository.ecr_repository.repository_url}"
    essential = true
    portMappings = [
      {
        containerPort : 80
        hostPort : 80
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
```

### The cluster service

![Alt text](images/Amazon-Elastic-Container-Service_Container.png)

> First: a cluster will be the playground where all our task will run, is defined in the terraform file with this code, so there no much explanation

```hcl
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "vite-docker-cluster"
}
```

We can create a **task** in the **cluster** as a single element, but the benefit of the service is that we define a ideal **state**

- Minimum task running
- Auto scaling
- etc

So we will define a cluster service with 2 tasks always running for redundancy

```hcl
resource "aws_ecs_service" "vite_ecs_service" {
  name = "vite-app-service"

  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.vite_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = aws_ecs_task_definition.vite_task.family
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.service_security_group.id]
  }
}

```

### Load balancer

![Alt text](images/Elastic-Load-Balancing.png)

In order to have redundancy we need a way to manage the inner traffic from the clients to our existing tasks, for that exist the **load balancer** that manage the network traffic and redirect to the available servers or task in our case

```hcl
resource "aws_alb" "vite_load_balancer" {
  name               = "vite-balancer-dev"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.lb_sg.id]
}
```

with the command `plan` and `apply` we should have all deployed in order to start to create or production ready website docker image

```bash
# Move to the terraform directory
cd terraform
# See the change to apply in the aws cloud
terraform plan
#if everything is correct apply the changes
terraform apply --auto-approve
```

The last command you output the url of the application

Right now should show a `503` error page since there is not task running

## Upload to the cloud

The main pipeline is the current

- Upload the docker image
- Create a task definition/revision
- Update the service to start using this new version of the tasks

With this configuration is very easy to update the production application and let AWS to managed everything by it own

### Upload the docker image

Here is the reason to create the repository, we need a source of true of the last version of the web app

```bash
# build the image and tag it with the corresponding repository url/name
docker build -t $REGISTRY/$REPOSITORY:$IMAGE_TAG -t $REGISTRY/$REPOSITORY:latest .
# push to the repository
docker push $REGISTRY/$REPOSITORY:latest
```

#### Create a task definition/revision

The terraform plan create the task definition and linked to the service, so we only have to create revision in order to automate everything

> you can create a all new task and the added to the service if you want a manual setup

To do that, we are going to use the aws cli

First we need the current task-definition and save it into json, getting only the fields that we need to create a new revision

```bash
aws ecs describe-task-definition \
  --task-definition ${{secrets.ECS_TASK_DEFINITION}} \
  --query 'taskDefinition.{
  "containerDefinitions":containerDefinitions,
  "family":family,
  "executionRoleArn":executionRoleArn,
  "networkMode":networkMode,
  "volumes":volumes,
  "placementConstraints":placementConstraints,
  "requiresCompatibilities":requiresCompatibilities,
  "cpu":cpu,
  "memory":memory
  }' > task_definition.json
```

Then we will create a new task revision, this is posible if we have the previous task definition, if not the command will create a new one

```bash
aws ecs register-task-definition \
  --cli-input-json file://./task_definition.json
```

And in the end we only need to update the current service in the cluster

```bash
aws ecs update-service \
            --cluster ${{secrets.CLUSTER_NAME}} \
            --service ${{secrets.CLUSTER_SERVICE}} \
            --task-definition ${{secrets.CONTAINER_NAME}}
```

This command will get the last revision of the task definition and tell the `service` to run the last version of the docker image, under the hood `ECS` will start a new 2 task **with out shutdown the previous one** a then stop the older versions once the new ones are running, giving **zero down time**

## Automate everything

In this repository are two [github actions](https://github.com/features/actions) workflows to automate everything and trigger the update of task from a new commit, splitting the infrastructure deploy from the code deploy

## Authors and acknowledgment


