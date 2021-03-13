# installing packages
apt-get update
apt-get install curl make gcc -y

# downloading samba sources
curl https://download.samba.org/pub/samba/stable/samba-3.4.5.tar.gz -o samba-3.4.5.tar.gz
tar -xvzf samba-3.4.5.tar.gz

# building from sources
cd ./samba-3.4.5/source3/
./configure --prefix=/samba
make
make install

# setting necessary variables
export PATH=/samba/bin/:/samba/sbin/:$PATH
export LD_LIBRARY_PATH="/samba/lib:$LD_LIBRARY_PATH"
