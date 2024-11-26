FROM nginx:1.25.3-alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy static files
COPY . /usr/share/nginx/html/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy SSL certificates
COPY certs/nginx.crt /etc/nginx/certs/nginx.crt
COPY certs/nginx.key /etc/nginx/certs/nginx.key

# Ensure certs directory exists
RUN mkdir -p /etc/nginx/certs

# Set permissions for SSL certificates
RUN chmod 600 /etc/nginx/certs/nginx.key /etc/nginx/certs/nginx.crt

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]