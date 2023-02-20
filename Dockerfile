FROM alpine:latest
COPY ./staging/word-cloud-generator /opt
EXPOSE 8888
CMD /opt/word-cloud-generator
