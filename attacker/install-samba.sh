# installing packages
apt-get update
apt-get install curl make gcc -y --fix-missing

# downloading samba sources
cd /workdir
curl https://download.samba.org/pub/samba/stable/samba-3.4.5.tar.gz -o samba-3.4.5.tar.gz
tar -xvzf samba-3.4.5.tar.gz

# patch for exploit
cp client.c ./samba-3.4.5/source3/client/client.c

# building from sources
cd ./samba-3.4.5/source3/
./configure --prefix=/samba
make
make install
