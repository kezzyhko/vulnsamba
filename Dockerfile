FROM ubuntu:20.04

ENV PATH=/samba/bin/:/samba/sbin/:$PATH
ENV LD_LIBRARY_PATH="/samba/lib:$LD_LIBRARY_PATH"

COPY . /workdir
WORKDIR /workdir
RUN ./install-samba.sh
CMD smbd -iF
