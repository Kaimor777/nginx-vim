FROM nginx

RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "vim"]
COPY index.html /usr/share/nginx/html
