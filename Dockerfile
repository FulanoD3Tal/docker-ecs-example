#Generate the server
FROM nginx
WORKDIR /
COPY /dist /usr/share/nginx/html
