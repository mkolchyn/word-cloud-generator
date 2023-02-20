FROM alpine:latest
COPY ./staging/word-cloud-generator /opt
EXPOSE 8888
