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

The importart file is the `Dockerfile` where we are going to create a server with the static files from vite build process

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

