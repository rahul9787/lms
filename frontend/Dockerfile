# Stage 1: Prepare frontend assets
FROM alpine:3.20 AS builder

WORKDIR /build

COPY index.html .

RUN mkdir -p /output && cp index.html /output/index.html


# Stage 2: Nginx production server
FROM nginx:alpine AS runtime

COPY --from=builder /output/ /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
