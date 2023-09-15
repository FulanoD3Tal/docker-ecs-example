#Generate the server
# Create a image from nginx oficial image
FROM nginx
# Using root as working directory
WORKDIR /
# Copy the dist directory content to nginx folder
# to let it server this static file
COPY /dist /usr/share/nginx/html
