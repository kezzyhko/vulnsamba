FROM ubuntu:20.04
COPY . /workdir
WORKDIR /workdir
RUN ./install-samba.sh
# CMD smbd
