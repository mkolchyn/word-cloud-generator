FROM alpine:latest
RUN ls -la
COPY ./staging/word-cloud-generator .
RUN ls -la
EXPOSE 8888
