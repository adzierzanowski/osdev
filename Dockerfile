FROM ubuntu:latest

RUN apt-get update
RUN apt-get install -y gcc xxd

COPY ./entrypoint.sh ./entrypoint.sh
COPY ./kernel.c ./kernel.c
ENTRYPOINT ./entrypoint.sh
