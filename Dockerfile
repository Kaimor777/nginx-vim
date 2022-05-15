#Let's get basic image of nginx
FROM nginx

#Update the image
RUN ["apt-get", "update"]

#Install vim. Casuse there's no like vim
RUN ["apt-get", "install", "-y", "vim"]

#And upload our HTML page to it as default
COPY index.html /usr/share/nginx/html
