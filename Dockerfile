FROM alpine:latest
RUN ls -la /
RUN pwd
RUN ls -la
COPY ./staging/word-cloud-generator .
EXPOSE 8888
